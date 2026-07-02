import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/outbound_record.dart';
import '../services/database_service.dart';
import 'inventory_provider.dart';

class OutboundState {
  final List<OutboundRecord> records;
  final DateTimeRange? dateFilter;
  final String? productFilterId;
  final String? destinationFilter;
  final OutboundStatus? statusFilter;
  final String? errorMessage;
  final bool isLoading;

  OutboundState({
    required this.records,
    this.dateFilter,
    this.productFilterId,
    this.destinationFilter,
    this.statusFilter,
    this.errorMessage,
    this.isLoading = false,
  });

  OutboundState copyWith({
    List<OutboundRecord>? records,
    DateTimeRange? dateFilter,
    String? productFilterId,
    String? destinationFilter,
    OutboundStatus? statusFilter,
    String? errorMessage,
    bool? isLoading,
  }) {
    return OutboundState(
      records: records ?? this.records,
      dateFilter: dateFilter ?? this.dateFilter,
      productFilterId: productFilterId ?? this.productFilterId,
      destinationFilter: destinationFilter ?? this.destinationFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OutboundNotifier extends StateNotifier<OutboundState> {
  final Ref _ref;

  OutboundNotifier(this._ref) : super(OutboundState(records: [])) {
    loadOutboundRecords();
  }

  void loadOutboundRecords() {
    state = state.copyWith(isLoading: true);
    
    var allRecords = DatabaseService.outboundBox.values.toList();

    // Apply Product Filter
    if (state.productFilterId != null) {
      allRecords = allRecords.where((rec) => rec.productId == state.productFilterId).toList();
    }

    // Apply Status Filter
    if (state.statusFilter != null) {
      allRecords = allRecords.where((rec) => rec.status == state.statusFilter).toList();
    }

    // Apply Destination Filter
    if (state.destinationFilter != null && state.destinationFilter!.isNotEmpty) {
      final query = state.destinationFilter!.toLowerCase();
      allRecords = allRecords.where((rec) => rec.destination.toLowerCase().contains(query)).toList();
    }

    // Apply Date Range Filter
    if (state.dateFilter != null) {
      allRecords = allRecords.where((rec) {
        final date = rec.date;
        return date.isAfter(state.dateFilter!.start.subtract(const Duration(seconds: 1))) &&
            date.isBefore(state.dateFilter!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date descending
    allRecords.sort((a, b) => b.date.compareTo(a.date));

    state = state.copyWith(records: allRecords, isLoading: false);
  }

  void setFilters({
    DateTimeRange? dateRange,
    String? productId,
    String? destination,
    OutboundStatus? status,
  }) {
    state = state.copyWith(
      dateFilter: dateRange,
      productFilterId: productId,
      destinationFilter: destination,
      statusFilter: status,
    );
    loadOutboundRecords();
  }

  void clearFilters() {
    state = OutboundState(records: []);
    loadOutboundRecords();
  }

  // Record Outbound
  Future<bool> addOutbound({
    required String productId,
    required double quantity,
    required double sellingPricePerUnit,
    required String destination,
    required DateTime date,
    OutboundStatus status = OutboundStatus.pending,
    String? notes,
  }) async {
    if (productId.isEmpty || quantity <= 0 || sellingPricePerUnit < 0 || destination.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Jumlah & harga jual harus > 0, dan tujuan wajib diisi.');
      return false;
    }

    final product = DatabaseService.productsBox.get(productId);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Produk tidak ditemukan');
      return false;
    }

    // Check stock availability (only if status is not Cancelled/Dibatalkan)
    if (status != OutboundStatus.dibatalkan && product.currentStock < quantity) {
      state = state.copyWith(
        errorMessage: 'Stok tidak mencukupi. Stok saat ini: ${product.currentStock} ${product.unit}, diminta: $quantity ${product.unit}',
      );
      return false;
    }

    final id = const Uuid().v4();
    final totalValue = quantity * sellingPricePerUnit;
    final now = DateTime.now();

    final record = OutboundRecord(
      id: id,
      productId: productId,
      productName: product.name,
      productSku: product.sku,
      quantity: quantity,
      sellingPricePerUnit: sellingPricePerUnit,
      totalValue: totalValue,
      destination: destination.trim(),
      status: status,
      date: date,
      notes: notes?.trim(),
      createdAt: now,
      updatedAt: now,
    );

    // 1. Save Outbound Record
    await DatabaseService.outboundBox.put(id, record);

    // 2. Reduce Product Stock (only if status is not dibatalkan)
    if (status != OutboundStatus.dibatalkan) {
      product.currentStock -= quantity;
      product.updatedAt = now;
      await product.save();
    }

    // 3. Refresh Providers
    loadOutboundRecords();
    _ref.read(inventoryProvider.notifier).loadProducts();

    return true;
  }

  // Update Outbound Status (Pending, Terkirim, Dibatalkan)
  Future<bool> updateStatus(String id, OutboundStatus newStatus) async {
    final record = DatabaseService.outboundBox.get(id);
    if (record == null) {
      state = state.copyWith(errorMessage: 'Catatan pengiriman tidak ditemukan');
      return false;
    }

    if (record.status == newStatus) return true;

    final product = DatabaseService.productsBox.get(record.productId);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Produk tidak ditemukan');
      return false;
    }

    final now = DateTime.now();

    // Case 1: Changing FROM Dibatalkan TO Pending/Terkirim (reduces stock)
    if (record.status == OutboundStatus.dibatalkan && newStatus != OutboundStatus.dibatalkan) {
      if (product.currentStock < record.quantity) {
        state = state.copyWith(
          errorMessage: 'Stok tidak mencukupi untuk mengaktifkan kembali pengiriman ini. Stok saat ini: ${product.currentStock} ${product.unit}, dibutuhkan: ${record.quantity} ${product.unit}',
        );
        return false;
      }
      product.currentStock -= record.quantity;
      product.updatedAt = now;
      await product.save();
    }
    // Case 2: Changing FROM Pending/Terkirim TO Dibatalkan (restores stock)
    else if (record.status != OutboundStatus.dibatalkan && newStatus == OutboundStatus.dibatalkan) {
      product.currentStock += record.quantity;
      product.updatedAt = now;
      await product.save();
    }

    // Update status
    record.status = newStatus;
    record.updatedAt = now;
    await record.save();

    // Refresh
    loadOutboundRecords();
    _ref.read(inventoryProvider.notifier).loadProducts();
    return true;
  }

  // Edit Outbound Record
  Future<bool> updateOutbound({
    required String id,
    required double quantity,
    required double sellingPricePerUnit,
    required String destination,
    required DateTime date,
    String? notes,
  }) async {
    final record = DatabaseService.outboundBox.get(id);
    if (record == null) {
      state = state.copyWith(errorMessage: 'Catatan pengiriman tidak ditemukan');
      return false;
    }

    if (quantity <= 0 || sellingPricePerUnit < 0 || destination.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Jumlah & harga jual harus > 0, dan tujuan wajib diisi.');
      return false;
    }

    final product = DatabaseService.productsBox.get(record.productId);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Produk tidak ditemukan');
      return false;
    }

    final now = DateTime.now();

    // If outbound is active (not dibatalkan), check stock adjustments
    if (record.status != OutboundStatus.dibatalkan) {
      final delta = quantity - record.quantity; // positive means we are taking MORE stock

      if (product.currentStock - delta < 0) {
        state = state.copyWith(
          errorMessage: 'Stok tidak mencukupi untuk penyesuaian ini. Stok saat ini: ${product.currentStock} ${product.unit}, dibutuhkan tambahan: $delta ${product.unit}',
        );
        return false;
      }

      product.currentStock -= delta;
      product.updatedAt = now;
      await product.save();
    }

    // Update fields
    record.quantity = quantity;
    record.sellingPricePerUnit = sellingPricePerUnit;
    record.totalValue = quantity * sellingPricePerUnit;
    record.destination = destination.trim();
    record.date = date;
    record.notes = notes?.trim();
    record.updatedAt = now;

    await record.save();

    // Refresh
    loadOutboundRecords();
    _ref.read(inventoryProvider.notifier).loadProducts();

    return true;
  }

  // Get total value of active filter range (excluding dibatalkan)
  double get totalOutboundValue {
    return state.records
        .where((rec) => rec.status != OutboundStatus.dibatalkan)
        .fold(0.0, (sum, rec) => sum + rec.totalValue);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final outboundProvider = StateNotifierProvider<OutboundNotifier, OutboundState>((ref) {
  return OutboundNotifier(ref);
});
