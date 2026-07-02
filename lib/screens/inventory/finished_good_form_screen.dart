import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finished_good_provider.dart';

class FinishedGoodFormScreen extends ConsumerStatefulWidget {
  final String? goodId;
  const FinishedGoodFormScreen({super.key, this.goodId});

  @override
  ConsumerState<FinishedGoodFormScreen> createState() => _FinishedGoodFormScreenState();
}

class _FinishedGoodFormScreenState extends ConsumerState<FinishedGoodFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();

  bool get _isEdit => widget.goodId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(finishedGoodProvider);
        final good = state.finishedGoods.firstWhere((g) => g.id == widget.goodId);
        _nameController.text = good.name;
        _skuController.text = good.sku;
        _unitController.text = good.unit;
        _priceController.text = good.defaultUnitPrice.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(finishedGoodProvider.notifier).clearError();

    bool success;
    if (_isEdit) {
      success = await ref.read(finishedGoodProvider.notifier).updateFinishedGood(
            id: widget.goodId!,
            name: _nameController.text.trim(),
            unit: _unitController.text.trim(),
            defaultUnitPrice: double.tryParse(_priceController.text) ?? 0.0,
          );
    } else {
      success = await ref.read(finishedGoodProvider.notifier).addFinishedGood(
            name: _nameController.text.trim(),
            sku: _skuController.text.trim(),
            unit: _unitController.text.trim(),
            initialStock: double.tryParse(_stockController.text) ?? 0.0,
            defaultUnitPrice: double.tryParse(_priceController.text) ?? 0.0,
          );
    }

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finishedGoodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Ubah Barang Jadi' : 'Tambah Barang Jadi'),
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
                    labelText: 'Nama Barang Jadi *',
                    hintText: 'Contoh: Kemeja Pria L',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _skuController,
                  enabled: !_isEdit,
                  decoration: const InputDecoration(
                    labelText: 'Kode SKU *',
                    hintText: 'Contoh: BJ-KMJ-L',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'SKU wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan *',
                    hintText: 'Contoh: pcs, lusin',
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
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual Default Per Unit (Rp) *',
                    prefixText: 'Rp ',
                    hintText: '0',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Harga jual wajib diisi';
                    final d = double.tryParse(val);
                    if (d == null || d < 0) return 'Harga harus berupa angka >= 0';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Barang Jadi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
