import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/raw_material.dart';
import '../services/database_service.dart';

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
  RawMaterialNotifier() : super(RawMaterialState(rawMaterials: [])) {
    loadRawMaterials();
  }

  void loadRawMaterials() {
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
    loadRawMaterials();
    return true;
  }

  Future<bool> updateRawMaterial({
    required String id,
    required String name,
    required String unit,
    required double defaultUnitCost,
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

    material.name = name.trim();
    material.unit = unit.trim();
    material.defaultUnitCost = defaultUnitCost;
    material.updatedAt = DateTime.now();

    await material.save();
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
    loadRawMaterials();
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final rawMaterialProvider = StateNotifierProvider<RawMaterialNotifier, RawMaterialState>((ref) {
  return RawMaterialNotifier();
});
