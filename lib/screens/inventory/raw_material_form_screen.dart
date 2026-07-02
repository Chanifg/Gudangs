import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';

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
  final _costController = TextEditingController();

  bool get _isEdit => widget.materialId != null;

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
        _costController.text = mat.defaultUnitCost.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _costController.dispose();
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
            defaultUnitCost: double.tryParse(_costController.text) ?? 0.0,
          );
    } else {
      success = await ref.read(rawMaterialProvider.notifier).addRawMaterial(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            unit: _unitController.text.trim(),
            initialStock: double.tryParse(_stockController.text) ?? 0.0,
            defaultUnitCost: double.tryParse(_costController.text) ?? 0.0,
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bahan Baku *',
                    hintText: 'Contoh: Kain Katun',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _skuController,
                  enabled: !_isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Kode SKU *',
                    hintText: 'Contoh: BB-KTN-01',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'SKU wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan *',
                    hintText: 'Contoh: meter, roll, kg',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Satuan wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _stockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Stok Awal *',
                      hintText: '0',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Stok awal wajib diisi';
                      final d = double.tryParse(val);
                      if (d == null || d < 0) return 'Stok harus berupa angka >= 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _costController,
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
