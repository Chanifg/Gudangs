import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/inbound_record.dart';
import '../services/database_service.dart';
import 'raw_material_provider.dart';
import 'stock_movement_provider.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';
import '../core/formatters.dart';

class InboundState {
  final List<InboundRecord> records;
  final DateTimeRange? dateFilter;
  final String? productFilterId;
  final String? errorMessage;
  final bool isLoading;

  InboundState({
    required this.records,
    this.dateFilter,
    this.productFilterId,
    this.errorMessage,
    this.isLoading = false,
  });

  InboundState copyWith({
    List<InboundRecord>? records,
    DateTimeRange? dateFilter,
    String? productFilterId,
    String? errorMessage,
    bool? isLoading,
  }) {
    return InboundState(
      records: records ?? this.records,
      dateFilter: dateFilter ?? this.dateFilter,
      productFilterId: productFilterId ?? this.productFilterId,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class InboundNotifier extends StateNotifier<InboundState> {
  final Ref _ref;

  InboundNotifier(this._ref) : super(InboundState(records: [])) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        loadInboundRecords();
      }
    });
    loadInboundRecords();
  }

  void loadInboundRecords() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    
    var allRecords = DatabaseService.inboundBox.values.toList();

    // Apply Product Filter
    if (state.productFilterId != null) {
      allRecords = allRecords.where((rec) => rec.productId == state.productFilterId).toList();
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

  void setFilters({DateTimeRange? dateRange, String? productId}) {
    state = state.copyWith(dateFilter: dateRange, productFilterId: productId);
    loadInboundRecords();
  }

  void clearFilters() {
    state = InboundState(records: []);
    loadInboundRecords();
  }

  // Record Inbound
  Future<bool> addInbound({
    required String productId,
    required double quantity,
    required double pricePerUnit,
    required DateTime date,
    String? notes,
  }) async {
    if (productId.isEmpty || quantity <= 0 || pricePerUnit < 0) {
      state = state.copyWith(errorMessage: 'Jumlah harus lebih besar dari 0 dan harga minimal 0');
      return false;
    }

    final product = DatabaseService.rawMaterialsBox.get(productId);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Bahan baku tidak ditemukan');
      return false;
    }

    final id = const Uuid().v4();
    final totalCost = quantity * pricePerUnit;

    final record = InboundRecord(
      id: id,
      productId: productId,
      productName: product.name,
      productSku: product.sku,
      quantity: quantity,
      pricePerUnit: pricePerUnit,
      totalCost: totalCost,
      date: date,
      notes: notes?.trim(),
      createdAt: DateTime.now(),
    );

    // 1. Save Inbound Record
    await DatabaseService.inboundBox.put(id, record);

    // 2. Recalculate stock and Weighted Average Cost (WAC)
    final double prevStock = product.currentStock;
    final double prevCost = product.defaultUnitCost;
    final double activePrevStock = prevStock > 0 ? prevStock : 0.0;
    final double newStock = prevStock + quantity;
    
    double newWac = prevCost;
    if (newStock > 0) {
      newWac = ((activePrevStock * prevCost) + (quantity * pricePerUnit)) / (activePrevStock + quantity);
    }

    product.currentStock = newStock;
    product.defaultUnitCost = newWac;
    product.updatedAt = DateTime.now();
    await product.save();

    // 3. Log stock movement
    await _ref.read(stockMovementProvider.notifier).logMovement(
      itemId: product.id,
      itemName: product.name,
      itemType: 'raw_material',
      type: 'inbound',
      quantity: quantity,
      previousStock: prevStock,
      newStock: newStock,
      unitCost: pricePerUnit,
      notes: notes?.trim() ?? 'Penerimaan bahan baku',
    );

    // 4. Log audit activity
    await _ref.read(auditLogProvider.notifier).logActivity(
      action: 'INBOUND_BAHAN_BAKU',
      description: 'Menerima bahan baku: ${product.name} (Qty: $quantity ${product.unit}, Harga/Unit: ${Formatters.formatRupiah(pricePerUnit)}, Total Biaya: ${Formatters.formatRupiah(totalCost)})',
    );

    // 5. Refresh Providers
    loadInboundRecords();
    _ref.read(rawMaterialProvider.notifier).loadRawMaterials();

    return true;
  }

  // Edit Inbound Record
  Future<bool> updateInbound({
    required String id,
    required double quantity,
    required double pricePerUnit,
    required DateTime date,
    String? notes,
  }) async {
    final record = DatabaseService.inboundBox.get(id);
    if (record == null) {
      state = state.copyWith(errorMessage: 'Catatan inbound tidak ditemukan');
      return false;
    }

    if (quantity <= 0 || pricePerUnit < 0) {
      state = state.copyWith(errorMessage: 'Jumlah harus lebih besar dari 0 dan harga minimal 0');
      return false;
    }

    final product = DatabaseService.rawMaterialsBox.get(record.productId);
    if (product == null || product.isDeleted) {
      state = state.copyWith(errorMessage: 'Bahan baku tidak ditemukan');
      return false;
    }

    // Calculate stock delta
    final delta = quantity - record.quantity;

    // Validate that adjusting stock won't result in negative stock
    if (product.currentStock + delta < 0) {
      state = state.copyWith(
        errorMessage: 'Penyesuaian jumlah tidak dapat disimpan karena akan menyebabkan total stok menjadi negatif (${product.currentStock + delta} ${product.unit})',
      );
      return false;
    }

    final double oldQty = record.quantity;
    final double oldPrice = record.pricePerUnit;
    
    // 1. Update Inbound Record
    record.quantity = quantity;
    record.pricePerUnit = pricePerUnit;
    record.totalCost = quantity * pricePerUnit;
    record.date = date;
    record.notes = notes?.trim();
    await record.save();

    // 2. Adjust WAC and Stock
    final double stockBeforeRevert = product.currentStock;
    final double wacBeforeRevert = product.defaultUnitCost;
    
    final double stockAfterRevert = stockBeforeRevert - oldQty;
    double wacAfterRevert = wacBeforeRevert;
    if (stockAfterRevert > 0) {
      wacAfterRevert = ((stockBeforeRevert * wacBeforeRevert) - (oldQty * oldPrice)) / stockAfterRevert;
      if (wacAfterRevert < 0) wacAfterRevert = product.defaultUnitCost;
    }
    
    final double stockFinal = stockAfterRevert + quantity;
    double wacFinal = wacAfterRevert;
    if (stockFinal > 0) {
      wacFinal = ((stockAfterRevert * wacAfterRevert) + (quantity * pricePerUnit)) / stockFinal;
    }

    product.currentStock = stockFinal;
    product.defaultUnitCost = wacFinal;
    product.updatedAt = DateTime.now();
    await product.save();

    // 3. Log stock movement
    await _ref.read(stockMovementProvider.notifier).logMovement(
      itemId: product.id,
      itemName: product.name,
      itemType: 'raw_material',
      type: 'inbound',
      quantity: quantity,
      previousStock: stockBeforeRevert,
      newStock: stockFinal,
      unitCost: pricePerUnit,
      notes: 'Koreksi Inbound: ${notes?.trim() ?? ""}',
    );

    // 4. Log audit activity
    await _ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_INBOUND_BAHAN_BAKU',
      description: 'Mengubah catatan inbound ${product.name}: Qty $oldQty -> $quantity, Harga/Unit: ${Formatters.formatRupiah(oldPrice)} -> ${Formatters.formatRupiah(pricePerUnit)}',
    );

    // 5. Refresh Providers
    loadInboundRecords();
    _ref.read(rawMaterialProvider.notifier).loadRawMaterials();

    return true;
  }

  // Get total purchase cost of active filter range
  double get totalInboundCost {
    return state.records.fold(0.0, (sum, rec) => sum + rec.totalCost);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final inboundProvider = StateNotifierProvider<InboundNotifier, InboundState>((ref) {
  return InboundNotifier(ref);
});
