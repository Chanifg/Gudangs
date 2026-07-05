import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finished_good_provider.dart';
import '../../services/database_service.dart';

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

  bool _skuManuallyEdited = false;

  bool get _isEdit => widget.goodId != null;

  /// Generate SKU: PJ-[3-letter abbreviation from name]-[NNN]
  String _generateSku(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    String abbr;
    if (words.length == 1) {
      abbr = words[0].substring(0, words[0].length.clamp(0, 3)).toUpperCase();
    } else {
      abbr = words.take(3).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
      if (abbr.length < 2 && words[0].length >= 2) {
        abbr = words[0].substring(0, 2).toUpperCase() + abbr.substring(abbr.length == 1 ? 1 : 0);
      }
    }
    abbr = abbr.replaceAll(RegExp(r'[^A-Z]'), '');
    if (abbr.isEmpty) abbr = 'XX';

    final count = DatabaseService.isOperationalOpen
        ? DatabaseService.finishedGoodsBox.values.where((g) => !g.isDeleted).length
        : 0;
    final seq = (count + 1).toString().padLeft(3, '0');
    return 'PJ-$abbr-$seq';
  }

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
    } else {
      _nameController.addListener(() {
        if (!_skuManuallyEdited && !_isEdit) {
          final generated = _generateSku(_nameController.text);
          _skuController.text = generated;
        }
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

                // Nama
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang Jadi *',
                    hintText: 'Contoh: Kemeja Pria L',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // SKU (hanya saat tambah)
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _skuController,
                    onChanged: (val) {
                      final expected = _generateSku(_nameController.text);
                      setState(() {
                        _skuManuallyEdited = val != expected;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kode SKU *',
                      hintText: 'Contoh: PJ-KPL-001',
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

