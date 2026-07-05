import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';
import '../../services/database_service.dart';
import '../../core/formatters.dart';

class RawMaterialFormScreen extends ConsumerStatefulWidget {
  final String? materialId;
  const RawMaterialFormScreen({super.key, this.materialId});

  @override
  ConsumerState<RawMaterialFormScreen> createState() => _RawMaterialFormScreenState();
}

class _RawMaterialFormScreenState extends ConsumerState<RawMaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _minimumStockController = TextEditingController();

  // For edit mode: direct unit cost
  final _unitCostController = TextEditingController();

  double _calculatedUnitCost = 0.0;

  bool _skuManuallyEdited = false;

  bool get _isEdit => widget.materialId != null;

  /// Generate SKU: BB-[3-letter abbreviation from name]-[NNN]
  String _generateSku(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    String abbr;
    if (words.length == 1) {
      abbr = words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    } else {
      abbr = words.take(3).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
      // Pad to at least 2 chars
      if (abbr.length < 2 && words[0].length >= 2) {
        abbr = words[0].substring(0, 2).toUpperCase() + abbr.substring(abbr.length == 1 ? 1 : 0);
      }
    }
    abbr = abbr.replaceAll(RegExp(r'[^A-Z]'), '');
    if (abbr.isEmpty) abbr = 'XX';

    final count = DatabaseService.isOperationalOpen
        ? DatabaseService.rawMaterialsBox.values.where((m) => !m.isDeleted).length
        : 0;
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'BB-$abbr-$seq';
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(rawMaterialProvider);
        final mat = state.rawMaterials.firstWhere((m) => m.id == widget.materialId);
        _nameController.text = mat.name;
        _skuController.text = mat.sku;
        _unitController.text = mat.unit;
        _unitCostController.text = mat.defaultUnitCost.toStringAsFixed(0);
        _minimumStockController.text = mat.minimumStock == 0.0 ? '' : mat.minimumStock.toStringAsFixed(0);
      });
    } else {
      _stockController.addListener(_updateCalculatedCost);
      _totalCostController.addListener(_updateCalculatedCost);
      _nameController.addListener(() {
        if (!_skuManuallyEdited && !_isEdit) {
          final generated = _generateSku(_nameController.text);
          _skuController.text = generated;
        }
      });
    }
  }

  void _updateCalculatedCost() {
    final qty = double.tryParse(_stockController.text) ?? 0.0;
    final total = double.tryParse(_totalCostController.text) ?? 0.0;
    setState(() {
      _calculatedUnitCost = (qty > 0) ? total / qty : 0.0;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _totalCostController.dispose();
    _unitCostController.dispose();
    _minimumStockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(rawMaterialProvider.notifier).clearError();

    bool success;
    if (_isEdit) {
      success = await ref.read(rawMaterialProvider.notifier).updateRawMaterial(
            id: widget.materialId!,
            name: _nameController.text.trim(),
            unit: _unitController.text.trim(),
            defaultUnitCost: double.tryParse(_unitCostController.text) ?? 0.0,
            minimumStock: double.tryParse(_minimumStockController.text) ?? 0.0,
          );
    } else {
      final qty = double.tryParse(_stockController.text) ?? 0.0;
      final totalCost = double.tryParse(_totalCostController.text) ?? 0.0;
      final unitCost = qty > 0 ? totalCost / qty : 0.0;

      success = await ref.read(rawMaterialProvider.notifier).addRawMaterial(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            unit: _unitController.text.trim(),
            initialStock: qty,
            defaultUnitCost: unitCost,
          );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rawMaterialProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Bahan Baku' : 'Tambah Bahan Baku'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Nama
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bahan Baku *',
                    hintText: 'Contoh: Besi Hollow',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // SKU (hanya saat tambah)
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _skuController,
                    onChanged: (val) {
                      // Jika user mengetik sendiri, tandai sebagai manual
                      final expected = _generateSku(_nameController.text);
                      setState(() {
                        _skuManuallyEdited = val != expected;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kode SKU *',
                      hintText: 'Contoh: BB-BSH-001',
                      helperText: _skuManuallyEdited ? 'SKU diedit manual' : 'Dibuat otomatis dari nama',
                      helperStyle: TextStyle(
                        color: _skuManuallyEdited ? colorScheme.tertiary : colorScheme.primary,
                        fontSize: 11,
                      ),
                      suffixIcon: _skuManuallyEdited
                          ? IconButton(
                              icon: const Icon(Icons.refresh, size: 18),
                              tooltip: 'Reset ke SKU otomatis',
                              onPressed: () {
                                setState(() {
                                  _skuController.text = _generateSku(_nameController.text);
                                  _skuManuallyEdited = false;
                                });
                              },
                            )
                          : Icon(Icons.auto_fix_high, size: 18, color: colorScheme.primary),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'SKU wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Satuan
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan *',
                    hintText: 'Contoh: meter, roll, kg, ml',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Satuan wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // Mode TAMBAH: Input stok awal + total harga beli
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _stockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Jumlah Stok Awal *',
                      hintText: '0',
                      suffixText: _unitController.text.isNotEmpty ? _unitController.text : 'unit',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Stok awal wajib diisi';
                      final d = double.tryParse(val);
                      if (d == null || d < 0) return 'Stok harus berupa angka >= 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _totalCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total Harga Beli *',
                      hintText: '50000',
                      prefixText: 'Rp ',
                      helperText: 'Total harga yang dibayar untuk semua stok awal di atas',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Total harga beli wajib diisi';
                      final d = double.tryParse(val);
                      if (d == null || d < 0) return 'Harga harus berupa angka >= 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ringkasan harga per unit (real-time)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Harga per ${_unitController.text.isNotEmpty ? _unitController.text : "unit"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          _calculatedUnitCost > 0
                              ? Formatters.formatRupiah(_calculatedUnitCost)
                              : '— ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Mode EDIT: Input harga per unit langsung + stok minimum
                if (_isEdit) ...[
                  TextFormField(
                    controller: _unitCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Harga Beli Default Per Unit (Rp) *',
                      prefixText: 'Rp ',
                      hintText: '0',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Harga beli wajib diisi';
                      final d = double.tryParse(val);
                      if (d == null || d < 0) return 'Harga harus berupa angka >= 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumStockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Stok Minimum',
                      hintText: '0',
                      helperText: 'Alert merah muncul jika stok di bawah angka ini',
                      suffixText: _unitController.text.isNotEmpty ? _unitController.text : 'unit',
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Bahan Baku'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

