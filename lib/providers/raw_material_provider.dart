import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/raw_material.dart';
import '../services/database_service.dart';
import 'stock_movement_provider.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';

class RawMaterialState {
  final List<RawMaterial> rawMaterials;
  final String searchKeyword;
  final String? errorMessage;
  final bool isLoading;

  RawMaterialState({
    required this.rawMaterials,
    this.searchKeyword = '',
    this.errorMessage,
    this.isLoading = false,
  });

  RawMaterialState copyWith({
    List<RawMaterial>? rawMaterials,
    String? searchKeyword,
    String? errorMessage,
    bool? isLoading,
  }) {
    return RawMaterialState(
      rawMaterials: rawMaterials ?? this.rawMaterials,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class RawMaterialNotifier extends StateNotifier<RawMaterialState> {
  final Ref ref;

  RawMaterialNotifier(this.ref) : super(RawMaterialState(rawMaterials: [])) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        loadRawMaterials();
      }
    });
    loadRawMaterials();
  }

  void loadRawMaterials() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    final allMaterials = DatabaseService.rawMaterialsBox.values
        .where((m) => !m.isDeleted)
        .toList();

    List<RawMaterial> filtered = allMaterials;
    if (state.searchKeyword.isNotEmpty) {
      final query = state.searchKeyword.toLowerCase();
      filtered = filtered
          .where((m) =>
              m.name.toLowerCase().contains(query) ||
              m.sku.toLowerCase().contains(query))
          .toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    state = state.copyWith(
      rawMaterials: filtered,
      isLoading: false,
    );
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadRawMaterials();
  }

  Future<bool> addRawMaterial({
    required String name,
    required String sku,
    required String unit,
    required double initialStock,
    required double defaultUnitCost,
  }) async {
    if (name.trim().isEmpty || sku.trim().isEmpty || unit.trim().isEmpty || initialStock < 0 || defaultUnitCost < 0) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi dengan benar');
      return false;
    }

    final skuExists = DatabaseService.rawMaterialsBox.values
        .any((m) => m.sku.toLowerCase() == sku.trim().toLowerCase() && !m.isDeleted);
    
    if (skuExists) {
      state = state.copyWith(errorMessage: 'Kode SKU sudah digunakan bahan baku lain');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final material = RawMaterial(
      id: id,
      name: name.trim(),
      sku: sku.trim(),
      unit: unit.trim(),
      currentStock: initialStock,
      defaultUnitCost: defaultUnitCost,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.rawMaterialsBox.put(id, material);

    // Log Stock Movement for initial stock
    if (initialStock > 0) {
      await ref.read(stockMovementProvider.notifier).logMovement(
        itemId: material.id,
        itemName: material.name,
        itemType: 'raw_material',
        type: 'inbound',
        quantity: initialStock,
        previousStock: 0.0,
        newStock: initialStock,
        unitCost: defaultUnitCost,
        notes: 'Stok Awal',
      );
    }

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'TAMBAH_BAHAN_BAKU',
      description: 'Menambahkan bahan baku baru: ${material.name} (SKU: ${material.sku}, Qty Awal: $initialStock ${material.unit})',
    );

    loadRawMaterials();
    return true;
  }

  Future<bool> updateRawMaterial({
    required String id,
    required String name,
    required String unit,
    required double defaultUnitCost,
    double minimumStock = 0.0,
  }) async {
    final material = DatabaseService.rawMaterialsBox.get(id);
    if (material == null || material.isDeleted) {
      state = state.copyWith(errorMessage: 'Bahan baku tidak ditemukan');
      return false;
    }

    if (name.trim().isEmpty || unit.trim().isEmpty || defaultUnitCost < 0) {
      state = state.copyWith(errorMessage: 'Nama, satuan, dan harga beli wajib diisi');
      return false;
    }

    final oldName = material.name;
    final oldCost = material.defaultUnitCost;
    material.name = name.trim();
    material.unit = unit.trim();
    material.defaultUnitCost = defaultUnitCost;
    material.minimumStock = minimumStock < 0 ? 0.0 : minimumStock;
    material.updatedAt = DateTime.now();

    await material.save();

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_BAHAN_BAKU',
      description: 'Mengubah bahan baku: $oldName -> ${material.name} (Harga Beli: $oldCost -> $defaultUnitCost, Stok Min: ${material.minimumStock})',
    );

    loadRawMaterials();
    return true;
  }

  Future<bool> deleteRawMaterial(String id) async {
    final material = DatabaseService.rawMaterialsBox.get(id);
    if (material == null) return false;

    // Check if used in active BOM
    final isUsedInBOM = DatabaseService.bomBox.values
        .any((bom) => bom.components.any((comp) => comp.rawMaterialId == id));

    if (isUsedInBOM) {
      state = state.copyWith(
        errorMessage: 'Bahan baku ini tidak dapat dihapus karena masih digunakan dalam formula BOM aktif.',
      );
      return false;
    }

    material.isDeleted = true;
    material.updatedAt = DateTime.now();
    await material.save();

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'HAPUS_BAHAN_BAKU',
      description: 'Menghapus bahan baku (soft delete): ${material.name} (SKU: ${material.sku})',
    );

    loadRawMaterials();
    return true;
  }

  // Stock Adjustment / Stock Opname for Raw Materials
  Future<bool> adjustStock({
    required String id,
    required String type, // 'adjustment_add', 'adjustment_sub', 'opname'
    required double quantity,
    required String notes,
  }) async {
    final material = DatabaseService.rawMaterialsBox.get(id);
    if (material == null || material.isDeleted) {
      state = state.copyWith(errorMessage: 'Bahan baku tidak ditemukan');
      return false;
    }

    if (quantity < 0) {
      state = state.copyWith(errorMessage: 'Jumlah penyesuaian tidak boleh negatif');
      return false;
    }

    final double prevStock = material.currentStock;
    double newStock = prevStock;
    double delta = quantity;

    if (type == 'adjustment_add') {
      newStock = prevStock + quantity;
      delta = quantity;
    } else if (type == 'adjustment_sub') {
      newStock = prevStock - quantity;
      delta = -quantity;
    } else if (type == 'opname') {
      newStock = quantity;
      delta = quantity - prevStock;
    }

    if (newStock < 0) {
      state = state.copyWith(errorMessage: 'Stok tidak boleh negatif setelah penyesuaian');
      return false;
    }

    material.currentStock = newStock;
    material.updatedAt = DateTime.now();
    await material.save();

    // Log Stock Movement
    await ref.read(stockMovementProvider.notifier).logMovement(
      itemId: material.id,
      itemName: material.name,
      itemType: 'raw_material',
      type: type,
      quantity: delta.abs(),
      previousStock: prevStock,
      newStock: newStock,
      unitCost: material.defaultUnitCost,
      notes: notes.trim(),
    );

    // Log Audit Trail
    final actionLabel = type == 'adjustment_add'
        ? 'Tambah Stok'
        : type == 'adjustment_sub'
            ? 'Kurang Stok'
            : 'Stock Opname';
    
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'KOREKSI_STOK_BAHAN_BAKU',
      description: 'Penyesuaian stok ${material.name} ($actionLabel): $prevStock -> $newStock (Alasan: $notes)',
    );

    loadRawMaterials();
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final rawMaterialProvider = StateNotifierProvider<RawMaterialNotifier, RawMaterialState>((ref) {
  return RawMaterialNotifier(ref);
});
