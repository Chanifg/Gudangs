import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finished_good_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../core/formatters.dart';
import '../../models/outbound_record.dart';

class OutboundFormScreen extends ConsumerStatefulWidget {
  const OutboundFormScreen({super.key});

  @override
  ConsumerState<OutboundFormScreen> createState() => _OutboundFormScreenState();
}

class _OutboundFormScreenState extends ConsumerState<OutboundFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProductId;
  double _availableStock = 0.0;
  String _productUnit = '';
  DateTime _selectedDate = DateTime.now();
  OutboundStatus _selectedStatus = OutboundStatus.pending;
  double _totalValue = 0.0;

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateTotalValue);
    _priceController.addListener(_updateTotalValue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTotalValue() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    setState(() {
      _totalValue = qty * price;
    });
  }

  void _onProductChanged(String? productId, WidgetRef ref) {
    if (productId == null) return;
    
    // Find selected product to show stock limits
    final products = ref.read(finishedGoodProvider).finishedGoods;
    final product = products.firstWhere((p) => p.id == productId);

    setState(() {
      _selectedProductId = productId;
      _availableStock = product.currentStock;
      _productUnit = product.unit;
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

  Future<void> _saveOutbound() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk terlebih dahulu')),
      );
      return;
    }

    ref.read(outboundProvider.notifier).clearError();

    final success = await ref.read(outboundProvider.notifier).addOutbound(
          productId: _selectedProductId!,
          quantity: double.tryParse(_qtyController.text) ?? 0.0,
          sellingPricePerUnit: double.tryParse(_priceController.text) ?? 0.0,
          destination: _destinationController.text,
          date: _selectedDate,
          status: _selectedStatus,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
        );

    if (success && mounted) {
      context.pop(); // Go back to transactions list
    }
  }

  @override
  Widget build(BuildContext context) {
    final finishedGoodState = ref.watch(finishedGoodProvider);
    final outboundState = ref.watch(outboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activeProducts = finishedGoodState.finishedGoods;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catat Barang Keluar'),
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
                if (outboundState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.error),
                    ),
                    child: Text(
                      outboundState.errorMessage!,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Product Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Produk *',
                  ),
                  items: activeProducts.map((prod) {
                    return DropdownMenuItem<String>(
                      value: prod.id,
                      child: Text('${prod.name} (${prod.sku})'),
                    );
                  }).toList(),
                  onChanged: (val) => _onProductChanged(val, ref),
                  validator: (value) => value == null ? 'Wajib memilih produk' : null,
                ),
                
                // Available Stock Info Banner
                if (_selectedProductId != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      'Stok Tersedia: ${_availableStock.toStringAsFixed(_availableStock % 1 == 0 ? 0 : 1)} $_productUnit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _availableStock < 10 ? colorScheme.error : colorScheme.primaryContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Quantity Input
                TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Unit Keluar *',
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
                    if (_selectedStatus != OutboundStatus.dibatalkan && n > _availableStock) {
                      return 'Stok tidak mencukupi (Tersedia: $_availableStock)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Selling price input
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual Per Unit (Rupiah) *',
                    hintText: '0',
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Harga jual tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n < 0) {
                      return 'Harga harus berupa angka >= 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Destination Input
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Tujuan Pengiriman *',
                    hintText: 'Contoh: Toko Jaya Sentosa',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tujuan pengiriman wajib diisi';
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
                      labelText: 'Tanggal Pengiriman *',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      Formatters.formatDate(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<OutboundStatus>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Pengiriman *',
                  ),
                  items: const [
                    DropdownMenuItem(value: OutboundStatus.pending, child: Text('Pending (Menunggu)')),
                    DropdownMenuItem(value: OutboundStatus.terkirim, child: Text('Terkirim')),
                    DropdownMenuItem(value: OutboundStatus.dibatalkan, child: Text('Dibatalkan')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Keterangan',
                    hintText: 'Contoh: Pengiriman via kurir motor',
                  ),
                ),
                const SizedBox(height: 24),

                // Real-time Value Card
                Card(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL ESTIMASI NILAI',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          Formatters.formatRupiah(_totalValue),
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
                  onPressed: _saveOutbound,
                  child: const Text('Simpan Barang Keluar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
