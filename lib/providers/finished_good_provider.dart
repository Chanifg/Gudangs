import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/finished_good.dart';
import '../services/database_service.dart';

class FinishedGoodState {
  final List<FinishedGood> finishedGoods;
  final String searchKeyword;
  final String? errorMessage;
  final bool isLoading;

  FinishedGoodState({
    required this.finishedGoods,
    this.searchKeyword = '',
    this.errorMessage,
    this.isLoading = false,
  });

  FinishedGoodState copyWith({
    List<FinishedGood>? finishedGoods,
    String? searchKeyword,
    String? errorMessage,
    bool? isLoading,
  }) {
    return FinishedGoodState(
      finishedGoods: finishedGoods ?? this.finishedGoods,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FinishedGoodNotifier extends StateNotifier<FinishedGoodState> {
  FinishedGoodNotifier() : super(FinishedGoodState(finishedGoods: [])) {
    loadFinishedGoods();
  }

  void loadFinishedGoods() {
    state = state.copyWith(isLoading: true);
    final allGoods = DatabaseService.finishedGoodsBox.values
        .where((g) => !g.isDeleted)
        .toList();

    List<FinishedGood> filtered = allGoods;
    if (state.searchKeyword.isNotEmpty) {
      final query = state.searchKeyword.toLowerCase();
      filtered = filtered
          .where((g) =>
              g.name.toLowerCase().contains(query) ||
              g.sku.toLowerCase().contains(query))
          .toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    state = state.copyWith(
      finishedGoods: filtered,
      isLoading: false,
    );
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadFinishedGoods();
  }

  Future<bool> addFinishedGood({
    required String name,
    required String sku,
    required String unit,
    required double initialStock,
    required double defaultUnitPrice,
  }) async {
    if (name.trim().isEmpty || sku.trim().isEmpty || unit.trim().isEmpty || initialStock < 0 || defaultUnitPrice < 0) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi dengan benar');
      return false;
    }

    final skuExists = DatabaseService.finishedGoodsBox.values
        .any((g) => g.sku.toLowerCase() == sku.trim().toLowerCase() && !g.isDeleted);
    
    if (skuExists) {
      state = state.copyWith(errorMessage: 'Kode SKU sudah digunakan barang jadi lain');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final good = FinishedGood(
      id: id,
      name: name.trim(),
      sku: sku.trim(),
      unit: unit.trim(),
      currentStock: initialStock,
      defaultUnitPrice: defaultUnitPrice,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.finishedGoodsBox.put(id, good);
    loadFinishedGoods();
    return true;
  }

  Future<bool> updateFinishedGood({
    required String id,
    required String name,
    required String unit,
    required double defaultUnitPrice,
  }) async {
    final good = DatabaseService.finishedGoodsBox.get(id);
    if (good == null || good.isDeleted) {
      state = state.copyWith(errorMessage: 'Barang jadi tidak ditemukan');
      return false;
    }

    if (name.trim().isEmpty || unit.trim().isEmpty || defaultUnitPrice < 0) {
      state = state.copyWith(errorMessage: 'Nama, satuan, dan harga jual wajib diisi');
      return false;
    }

    good.name = name.trim();
    good.unit = unit.trim();
    good.defaultUnitPrice = defaultUnitPrice;
    good.updatedAt = DateTime.now();

    await good.save();
    loadFinishedGoods();
    return true;
  }

  Future<bool> deleteFinishedGood(String id) async {
    final good = DatabaseService.finishedGoodsBox.get(id);
    if (good == null) return false;

    // Check if used in active BOM
    final isUsedInBOM = DatabaseService.bomBox.values
        .any((bom) => bom.finishedGoodId == id);

    if (isUsedInBOM) {
      state = state.copyWith(
        errorMessage: 'Barang jadi ini tidak dapat dihapus karena memiliki formula BOM aktif.',
      );
      return false;
    }

    good.isDeleted = true;
    good.updatedAt = DateTime.now();
    await good.save();
    loadFinishedGoods();
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final finishedGoodProvider = StateNotifierProvider<FinishedGoodNotifier, FinishedGoodState>((ref) {
  return FinishedGoodNotifier();
});
