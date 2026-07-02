import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/inbound_record.dart';
import '../models/outbound_record.dart';
import '../services/database_service.dart';

class InventoryState {
  final List<Product> products;
  final List<String> categories;
  final String searchKeyword;
  final String selectedCategory;
  final String? errorMessage;
  final bool isLoading;

  InventoryState({
    required this.products,
    required this.categories,
    this.searchKeyword = '',
    this.selectedCategory = 'Semua',
    this.errorMessage,
    this.isLoading = false,
  });

  InventoryState copyWith({
    List<Product>? products,
    List<String>? categories,
    String? searchKeyword,
    String? selectedCategory,
    String? errorMessage,
    bool? isLoading,
  }) {
    return InventoryState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier()
      : super(InventoryState(products: [], categories: ['Semua'])) {
    loadProducts();
  }

  void loadProducts() {
    state = state.copyWith(isLoading: true);
    final allProducts = DatabaseService.productsBox.values
        .where((p) => !p.isDeleted)
        .toList();

    // Extract unique categories
    final categories = {'Semua'};
    for (final p in allProducts) {
      if (p.category != null && p.category!.trim().isNotEmpty) {
        categories.add(p.category!.trim());
      }
    }

    // Apply Filter & Search
    List<Product> filteredProducts = allProducts;
    if (state.selectedCategory != 'Semua') {
      filteredProducts = filteredProducts
          .where((p) => p.category == state.selectedCategory)
          .toList();
    }

    if (state.searchKeyword.isNotEmpty) {
      final query = state.searchKeyword.toLowerCase();
      filteredProducts = filteredProducts
          .where((p) =>
              p.name.toLowerCase().contains(query) ||
              p.sku.toLowerCase().contains(query))
          .toList();
    }

    // Sort alphabetically
    filteredProducts.sort((a, b) => a.name.compareTo(b.name));

    state = state.copyWith(
      products: filteredProducts,
      categories: categories.toList(),
      isLoading: false,
    );
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadProducts();
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(selectedCategory: category);
    loadProducts();
  }

  // Add Product
  Future<bool> addProduct({
    required String name,
    required String sku,
    String? category,
    required double initialStock,
    required String unit,
  }) async {
    if (name.trim().isEmpty || sku.trim().isEmpty || unit.trim().isEmpty || initialStock < 0) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi dengan benar');
      return false;
    }

    // Validate SKU uniqueness
    final skuExists = DatabaseService.productsBox.values
        .any((p) => p.sku.toLowerCase() == sku.trim().toLowerCase() && !p.isDeleted);
    
    if (skuExists) {
      state = state.copyWith(errorMessage: 'Kode SKU sudah digunakan produk lain');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final product = Product(
      id: id,
      name: name.trim(),
      sku: sku.trim(),
      category: category?.trim(),
      currentStock: initialStock,
      unit: unit.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.productsBox.put(id, product);
    
    // Also create an initial inbound record if initial stock is > 0
    if (initialStock > 0) {
      final inboundId = const Uuid().v4();
      final inbound = InboundRecord(
        id: inboundId,
        productId: id,
        productName: name.trim(),
        productSku: sku.trim(),
        quantity: initialStock,
        pricePerUnit: 0, // Initial stock is free/unscheduled cost
        totalCost: 0,
        date: now,
        notes: 'Stok awal produk',
        createdAt: now,
      );
      await DatabaseService.inboundBox.put(inboundId, inbound);
    }

    loadProducts();
    return true;
  }

  // Update Product
  Future<bool> updateProduct({
    required String id,
    required String name,
    String? category,
    required String unit,
  }) async {
    final product = DatabaseService.productsBox.get(id);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Produk tidak ditemukan');
      return false;
    }

    if (name.trim().isEmpty || unit.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Nama dan satuan wajib diisi');
      return false;
    }

    product.name = name.trim();
    product.category = category?.trim();
    product.unit = unit.trim();
    product.updatedAt = DateTime.now();

    await product.save();
    loadProducts();
    return true;
  }

  // Soft Delete Product
  Future<void> deleteProduct(String id) async {
    final product = DatabaseService.productsBox.get(id);
    if (product != null) {
      product.isDeleted = true;
      product.updatedAt = DateTime.now();
      await product.save();
      loadProducts();
    }
  }

  // Get Stock History for a Product
  List<Map<String, dynamic>> getStockHistory(String productId) {
    final List<Map<String, dynamic>> history = [];

    // Fetch Inbound Records
    final inbounds = DatabaseService.inboundBox.values
        .where((rec) => rec.productId == productId)
        .toList();
    for (final rec in inbounds) {
      history.add({
        'type': 'inbound',
        'quantity': rec.quantity,
        'date': rec.date,
        'title': 'Barang Masuk',
        'subtitle': rec.notes ?? 'Penerimaan barang',
      });
    }

    // Fetch Outbound Records
    final outbounds = DatabaseService.outboundBox.values
        .where((rec) => rec.productId == productId && rec.status != OutboundStatus.dibatalkan)
        .toList();
    for (final rec in outbounds) {
      history.add({
        'type': 'outbound',
        'quantity': rec.quantity,
        'date': rec.date,
        'title': 'Barang Keluar',
        'subtitle': 'Tujuan: ${rec.destination}',
      });
    }

    // Sort by date descending
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return history;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final inventoryProvider = StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});
