import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_of_materials.dart';
import '../services/database_service.dart';
import '../core/formatters.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';

class BOMState {
  final List<BillOfMaterials> boms;
  final String searchKeyword;
  final String? errorMessage;
  final bool isLoading;

  BOMState({
    required this.boms,
    this.searchKeyword = '',
    this.errorMessage,
    this.isLoading = false,
  });

  BOMState copyWith({
    List<BillOfMaterials>? boms,
    String? searchKeyword,
    String? errorMessage,
    bool? isLoading,
  }) {
    return BOMState(
      boms: boms ?? this.boms,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BOMNotifier extends StateNotifier<BOMState> {
  final Ref ref;

  BOMNotifier(this.ref) : super(BOMState(boms: [])) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        loadBOMs();
      }
    });
    loadBOMs();
  }

  void loadBOMs() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    final allBoms = DatabaseService.bomBox.values.toList();

    List<BillOfMaterials> filtered = allBoms;
    if (state.searchKeyword.isNotEmpty) {
      final query = state.searchKeyword.toLowerCase();
      filtered = filtered
          .where((bom) =>
              bom.name.toLowerCase().contains(query) ||
              bom.finishedGoodName.toLowerCase().contains(query))
          .toList();
    }

    filtered.sort((a, b) => a.name.compareTo(b.name));

    state = state.copyWith(
      boms: filtered,
      isLoading: false,
    );
  }

  void setSearchKeyword(String keyword) {
    state = state.copyWith(searchKeyword: keyword);
    loadBOMs();
  }

  Future<bool> addBOM({
    required String name,
    required String finishedGoodId,
    required List<BOMComponent> components,
    double laborCost = 0.0,
  }) async {
    if (name.trim().isEmpty || finishedGoodId.isEmpty || components.isEmpty) {
      state = state.copyWith(errorMessage: 'Semua field wajib diisi dan minimal terdapat 1 komponen');
      return false;
    }

    // Validate 1 FinishedGood has only 1 BOM
    final fgHasBOM = DatabaseService.bomBox.values
        .any((bom) => bom.finishedGoodId == finishedGoodId);

    if (fgHasBOM) {
      state = state.copyWith(errorMessage: 'Barang jadi ini sudah memiliki formula BOM aktif');
      return false;
    }

    final finishedGood = DatabaseService.finishedGoodsBox.get(finishedGoodId);
    if (finishedGood == null || finishedGood.isDeleted) {
      state = state.copyWith(errorMessage: 'Barang jadi tidak ditemukan');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final bom = BillOfMaterials(
      id: id,
      name: name.trim(),
      finishedGoodId: finishedGoodId,
      finishedGoodName: finishedGood.name,
      components: components,
      createdAt: now,
      updatedAt: now,
      laborCost: laborCost,
    );

    await DatabaseService.bomBox.put(id, bom);

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'TAMBAH_BOM',
      description: 'Menambahkan formula BOM baru: ${bom.name} untuk produk ${bom.finishedGoodName} (Upah Tenaga: ${Formatters.formatRupiah(laborCost)})',
    );

    loadBOMs();
    return true;
  }

  Future<bool> updateBOM({
    required String id,
    required String name,
    required List<BOMComponent> components,
    double laborCost = 0.0,
  }) async {
    final bom = DatabaseService.bomBox.get(id);
    if (bom == null) {
      state = state.copyWith(errorMessage: 'BOM tidak ditemukan');
      return false;
    }

    if (name.trim().isEmpty || components.isEmpty) {
      state = state.copyWith(errorMessage: 'Nama dan minimal 1 komponen wajib diisi');
      return false;
    }

    final oldName = bom.name;
    bom.name = name.trim();
    bom.components = components;
    bom.laborCost = laborCost;
    bom.updatedAt = DateTime.now();

    await bom.save();

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_BOM',
      description: 'Mengubah formula BOM: $oldName -> ${bom.name} (Upah Tenaga: ${Formatters.formatRupiah(laborCost)})',
    );

    loadBOMs();
    return true;
  }

  Future<bool> deleteBOM(String id) async {
    final bom = DatabaseService.bomBox.get(id);
    if (bom == null) return false;

    final name = bom.name;
    final finishedGoodName = bom.finishedGoodName;

    await bom.delete();

    // Log Audit Trail
    await ref.read(auditLogProvider.notifier).logActivity(
      action: 'HAPUS_BOM',
      description: 'Menghapus formula BOM: $name (Produk: $finishedGoodName)',
    );

    loadBOMs();
    return true;
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final bomProvider = StateNotifierProvider<BOMNotifier, BOMState>((ref) {
  return BOMNotifier(ref);
});
