import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/inbound_provider.dart';
import '../../core/formatters.dart';

class InboundFormScreen extends ConsumerStatefulWidget {
  const InboundFormScreen({super.key});

  @override
  ConsumerState<InboundFormScreen> createState() => _InboundFormScreenState();
}

class _InboundFormScreenState extends ConsumerState<InboundFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProductId;
  DateTime _selectedDate = DateTime.now();
  double _totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateTotalCost);
    _priceController.addListener(_updateTotalCost);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTotalCost() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalCost = qty * price;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveInbound() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }

    ref.read(inboundProvider.notifier).clearError();

    final success = await ref.read(inboundProvider.notifier).addInbound(
          productId: _selectedProductId!,
          quantity: double.tryParse(_qtyController.text) ?? 0.0,
          pricePerUnit: double.tryParse(_priceController.text) ?? 0.0,
          date: _selectedDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
        );

    if (success && mounted) {
      context.pop(); // Go back to transactions list
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final inboundState = ref.watch(inboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activeProducts = inventoryState.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Barang Masuk'),
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
                if (inboundState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      inboundState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Product Dropdown Selection
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Produk *',
                  ),
                  items: activeProducts.map((prod) {
                    return DropdownMenuItem<String>(
                      value: prod.id,
                      child: Text('${prod.name} (${prod.sku})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = val;
                    });
                  },
                  validator: (value) => value == null ? 'Wajib memilih produk' : null,
                ),
                const SizedBox(height: 16),

                // Quantity Input
                TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Unit Masuk *',
                    hintText: '0',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jumlah unit tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Jumlah harus berupa angka > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cost price per unit Input
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Harga Beli Per Unit (Rupiah) *',
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga per unit tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n < 0) {
                      return 'Harga harus berupa angka >= 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Picker Button
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Penerimaan *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      Formatters.formatDate(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Contoh: Supplier PT Maju Bersama',
                  ),
                ),
                const SizedBox(height: 24),

                // Real-time Cost Estimation Card
                Card(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL ESTIMASI BIAYA',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          Formatters.formatRupiah(_totalCost),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _saveInbound,
                  child: const Text('Simpan Barang Masuk'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
