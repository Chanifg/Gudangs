import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inventory_provider.dart';
import '../../services/database_service.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitController = TextEditingController();
  final _stockController = TextEditingController();

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadProductData();
    }
  }

  void _loadProductData() {
    final product = DatabaseService.productsBox.get(widget.productId);
    if (product != null) {
      _nameController.text = product.name;
      _skuController.text = product.sku;
      _categoryController.text = product.category ?? '';
      _unitController.text = product.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    ref.read(inventoryProvider.notifier).clearError();
    bool success = false;

    if (_isEditing) {
      success = await ref.read(inventoryProvider.notifier).updateProduct(
            id: widget.productId!,
            name: _nameController.text,
            category: _categoryController.text.trim().isEmpty ? null : _categoryController.text,
            unit: _unitController.text,
          );
    } else {
      success = await ref.read(inventoryProvider.notifier).addProduct(
            name: _nameController.text,
            sku: _skuController.text,
            category: _categoryController.text.trim().isEmpty ? null : _categoryController.text,
            initialStock: double.tryParse(_stockController.text) ?? 0.0,
            unit: _unitController.text,
          );
    }

    if (success && mounted) {
      context.pop(); // Go back to inventory list/detail
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Ubah Produk' : 'Tambah Produk Baru'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error message banner
                if (inventoryState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      inventoryState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Product Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Produk *',
                    hintText: 'Masukkan nama lengkap produk',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // SKU Field (Disabled if editing)
                TextFormField(
                  controller: _skuController,
                  enabled: !_isEditing,
                  decoration: InputDecoration(
                    labelText: 'Kode SKU *',
                    hintText: 'Contoh: BR-001',
                    helperText: _isEditing ? 'Kode SKU tidak dapat diubah.' : 'SKU harus unik di sistem.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kode SKU tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Field
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Contoh: Sembako, Elektronik',
                  ),
                ),
                const SizedBox(height: 16),

                // Satuan Unit Field
                TextFormField(
                  controller: _unitController,
                  decoration: const InputDecoration(
                    labelText: 'Satuan Unit *',
                    hintText: 'Contoh: kg, pcs, btl, unit',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Satuan unit wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Initial Stock (Only visible when adding new product)
                if (!_isEditing) ...[
                  TextFormField(
                    controller: _stockController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Stok Awal *',
                      hintText: '0',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stok awal tidak boleh kosong';
                      }
                      final n = double.tryParse(value);
                      if (n == null || n < 0) {
                        return 'Stok awal harus berupa angka >= 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit Button
                ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(_isEditing ? 'Simpan Perubahan' : 'Tambah Produk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
