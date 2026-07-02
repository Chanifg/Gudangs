import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/production_record.dart';
import '../models/bill_of_materials.dart';
import '../models/raw_material.dart';
import '../models/finished_good.dart';
import '../services/database_service.dart';
import 'raw_material_provider.dart';
import 'finished_good_provider.dart';
import 'stock_movement_provider.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';
import '../core/formatters.dart';

class ProductionState {
  final List<ProductionRecord> records;
  final DateTimeRange? dateFilter;
  final String? finishedGoodFilterId;
  final String? errorMessage;
  final bool isLoading;

  ProductionState({
    required this.records,
    this.dateFilter,
    this.finishedGoodFilterId,
    this.errorMessage,
    this.isLoading = false,
  });

  ProductionState copyWith({
    List<ProductionRecord>? records,
    DateTimeRange? dateFilter,
    String? finishedGoodFilterId,
    String? errorMessage,
    bool? isLoading,
  }) {
    return ProductionState(
      records: records ?? this.records,
      dateFilter: dateFilter ?? this.dateFilter,
      finishedGoodFilterId: finishedGoodFilterId ?? this.finishedGoodFilterId,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProductionValidationResult {
  final bool isEnough;
  final List<ComponentValidationDetail> details;
  final double estimatedTotalCost;
  final double estimatedHPP;

  ProductionValidationResult({
    required this.isEnough,
    required this.details,
    required this.estimatedTotalCost,
    required this.estimatedHPP,
  });
}

class ComponentValidationDetail {
  final String rawMaterialName;
  final String unit;
  final double requiredQty;
  final double availableQty;
  final double deficit;
  final bool isEnough;

  ComponentValidationDetail({
    required this.rawMaterialName,
    required this.unit,
    required this.requiredQty,
    required this.availableQty,
    required this.deficit,
    required this.isEnough,
  });
}

class ProductionNotifier extends StateNotifier<ProductionState> {
  final Ref _ref;

  ProductionNotifier(this._ref) : super(ProductionState(records: [])) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        loadProductionRecords();
      }
    });
    loadProductionRecords();
  }

  void loadProductionRecords() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    var allRecords = DatabaseService.productionBox.values.toList();

    // Apply FinishedGood filter
    if (state.finishedGoodFilterId != null) {
      allRecords = allRecords.where((r) => r.finishedGoodId == state.finishedGoodFilterId).toList();
    }

    // Apply Date Filter
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

  void setFilters({DateTimeRange? dateRange, String? finishedGoodId}) {
    state = state.copyWith(dateFilter: dateRange, finishedGoodFilterId: finishedGoodId);
    loadProductionRecords();
  }

  void clearFilters() {
    state = ProductionState(records: []);
    loadProductionRecords();
  }

  // Validate stock of all components in BOM for a given production quantity
  ProductionValidationResult validateStock(String bomId, double quantityProduced) {
    if (quantityProduced <= 0) {
      return ProductionValidationResult(
        isEnough: false,
        details: [],
        estimatedTotalCost: 0,
        estimatedHPP: 0,
      );
    }

    final bom = DatabaseService.bomBox.get(bomId);
    if (bom == null) {
      return ProductionValidationResult(
        isEnough: false,
        details: [],
        estimatedTotalCost: 0,
        estimatedHPP: 0,
      );
    }

    bool allEnough = true;
    List<ComponentValidationDetail> details = [];
    double totalCost = 0.0;

    for (final comp in bom.components) {
      final rawMat = DatabaseService.rawMaterialsBox.get(comp.rawMaterialId);
      final currentStock = rawMat?.currentStock ?? 0.0;
      final requiredQty = comp.quantityPerUnit * quantityProduced;
      final isEnough = currentStock >= requiredQty;
      final deficit = isEnough ? 0.0 : requiredQty - currentStock;

      if (!isEnough) {
        allEnough = false;
      }

      final costPerUnit = rawMat?.defaultUnitCost ?? 0.0;
      totalCost += requiredQty * costPerUnit;

      details.add(ComponentValidationDetail(
        rawMaterialName: comp.rawMaterialName,
        unit: comp.rawMaterialUnit,
        requiredQty: requiredQty,
        availableQty: currentStock,
        deficit: deficit,
        isEnough: isEnough,
      ));
    }

    return ProductionValidationResult(
      isEnough: allEnough,
      details: details,
      estimatedTotalCost: totalCost,
      estimatedHPP: totalCost / quantityProduced,
    );
  }

  // Execute production process
  Future<bool> executeProduction({
    required String bomId,
    required double quantityProduced,
    required DateTime date,
    String? note,
  }) async {
    if (bomId.isEmpty || quantityProduced <= 0) {
      state = state.copyWith(errorMessage: 'BOM dan kuantitas produksi tidak boleh kosong');
      return false;
    }

    final bom = DatabaseService.bomBox.get(bomId);
    if (bom == null) {
      state = state.copyWith(errorMessage: 'Formula BOM tidak ditemukan');
      return false;
    }

    final finishedGood = DatabaseService.finishedGoodsBox.get(bom.finishedGoodId);
    if (finishedGood == null || finishedGood.isDeleted) {
      state = state.copyWith(errorMessage: 'Barang jadi tidak ditemukan');
      return false;
    }

    // 1. Validate stock again to prevent concurrency issues
    final validation = validateStock(bomId, quantityProduced);
    if (!validation.isEnough) {
      state = state.copyWith(errorMessage: 'Stok bahan baku tidak mencukupi untuk melakukan produksi ini.');
      return false;
    }

    try {
      final recordId = const Uuid().v4();
      final now = DateTime.now();

      double totalMaterialCost = 0.0;
      List<MaterialUsage> materialsUsed = [];

      // 2. Prepare material updates & usage snapshots
      List<RawMaterial> updatedMaterials = [];
      for (final comp in bom.components) {
        final rawMat = DatabaseService.rawMaterialsBox.get(comp.rawMaterialId);
        if (rawMat == null) throw Exception('Bahan baku ${comp.rawMaterialName} tidak ditemukan');
        
        final costAtTime = rawMat.defaultUnitCost;
        final qtyUsed = comp.quantityPerUnit * quantityProduced;
        final compTotalCost = qtyUsed * costAtTime;
        
        totalMaterialCost += compTotalCost;
        materialsUsed.add(MaterialUsage(
          rawMaterialId: comp.rawMaterialId,
          rawMaterialName: comp.rawMaterialName,
          rawMaterialUnit: comp.rawMaterialUnit,
          quantityUsed: qtyUsed,
          unitCostAtTime: costAtTime,
          totalCost: compTotalCost,
        ));

        // Deduct stock
        rawMat.currentStock -= qtyUsed;
        rawMat.updatedAt = now;
        updatedMaterials.add(rawMat);
      }

      final hpp = totalMaterialCost / quantityProduced;

      // 3. Atomically write changes (save list)
      for (final rawMat in updatedMaterials) {
        final double prevStock = rawMat.currentStock + (compQtyPerUnit(bom, rawMat.id) * quantityProduced);
        await rawMat.save();

        // Log Stock Movement for raw material deduction
        await _ref.read(stockMovementProvider.notifier).logMovement(
          itemId: rawMat.id,
          itemName: rawMat.name,
          itemType: 'raw_material',
          type: 'production_out',
          quantity: compQtyPerUnit(bom, rawMat.id) * quantityProduced,
          previousStock: prevStock,
          newStock: rawMat.currentStock,
          unitCost: rawMat.defaultUnitCost,
          notes: 'Dihabiskan untuk produksi batch ${bom.name}',
        );
      }

      final double prevProductStock = finishedGood.currentStock;
      
      // Update finished good
      finishedGood.currentStock += quantityProduced;
      finishedGood.lastHPP = hpp;
      finishedGood.updatedAt = now;
      await finishedGood.save();

      // Log Stock Movement for finished good addition
      await _ref.read(stockMovementProvider.notifier).logMovement(
        itemId: finishedGood.id,
        itemName: finishedGood.name,
        itemType: 'product',
        type: 'production_in',
        quantity: quantityProduced,
        previousStock: prevProductStock,
        newStock: finishedGood.currentStock,
        unitCost: hpp,
        notes: 'Hasil produksi batch ${bom.name}',
      );

      // Save ProductionRecord
      final record = ProductionRecord(
        id: recordId,
        bomId: bomId,
        bomName: bom.name,
        finishedGoodId: bom.finishedGoodId,
        finishedGoodName: bom.finishedGoodName,
        quantityProduced: quantityProduced,
        materialsUsed: materialsUsed,
        totalMaterialCost: totalMaterialCost,
        hpp: hpp,
        date: date,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
        createdAt: now,
      );

      await DatabaseService.productionBox.put(recordId, record);

      // Log Audit Trail
      await _ref.read(auditLogProvider.notifier).logActivity(
        action: 'PRODUKSI_BARANG_JADI',
        description: 'Mengeksekusi produksi barang jadi ${finishedGood.name} (Jumlah: $quantityProduced ${finishedGood.unit}, HPP/Unit: ${Formatters.formatRupiah(hpp)}, Total Biaya Bahan: ${Formatters.formatRupiah(totalMaterialCost)})',
      );

      // 4. Refresh providers
      loadProductionRecords();
      _ref.read(rawMaterialProvider.notifier).loadRawMaterials();
      _ref.read(finishedGoodProvider.notifier).loadFinishedGoods();

      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengeksekusi produksi: $e');
      return false;
    }
  }

  double compQtyPerUnit(BillOfMaterials bom, String materialId) {
    try {
      return bom.components.firstWhere((comp) => comp.rawMaterialId == materialId).quantityPerUnit;
    } catch (_) {
      return 0.0;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final productionProvider = StateNotifierProvider<ProductionNotifier, ProductionState>((ref) {
  return ProductionNotifier(ref);
});
