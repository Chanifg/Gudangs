import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';
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
  final _totalCostController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedProductId;
  DateTime _selectedDate = DateTime.now();

  double _unitPrice = 0.0;
  double _totalCost = 0.0;
  String _selectedUnit = '';

  @override
  void initState() {
    super.initState();
    _qtyController.addListener(_updateCalculations);
    _totalCostController.addListener(_updateCalculations);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rawMaterialProvider.notifier).loadRawMaterials();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _totalCostController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final total = double.tryParse(_totalCostController.text) ?? 0.0;
    setState(() {
      _totalCost = total;
      _unitPrice = (qty > 0) ? total / qty : 0.0;
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

    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    final total = double.tryParse(_totalCostController.text) ?? 0.0;
    final computedUnitPrice = qty > 0 ? total / qty : 0.0;

    final success = await ref.read(inboundProvider.notifier).addInbound(
          productId: _selectedProductId!,
          quantity: qty,
          pricePerUnit: computedUnitPrice,
          date: _selectedDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text,
        );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawMaterialState = ref.watch(rawMaterialProvider);
    final inboundState = ref.watch(inboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activeProducts = rawMaterialState.rawMaterials;

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
                    labelText: 'Pilih Bahan Baku *',
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
                      // Update unit label
                      if (val != null) {
                        final mat = activeProducts.firstWhere((p) => p.id == val);
                        _selectedUnit = mat.unit;
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Wajib memilih bahan baku' : null,
                ),
                const SizedBox(height: 16),

                // Quantity Input
                TextFormField(
                  controller: _qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Jumlah yang Diterima *',
                    hintText: '0',
                    suffixText: _selectedUnit.isNotEmpty ? _selectedUnit : 'unit',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Jumlah tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n <= 0) {
                      return 'Jumlah harus berupa angka > 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Total purchase cost input
                TextFormField(
                  controller: _totalCostController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Total Harga Beli *',
                    hintText: '50000',
                    prefixText: 'Rp ',
                    helperText: 'Total harga yang kamu bayar untuk semua barang di atas',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Total harga beli tidak boleh kosong';
                    }
                    final n = double.tryParse(value);
                    if (n == null || n < 0) {
                      return 'Harga harus berupa angka >= 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Real-time unit price card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga per ${_selectedUnit.isNotEmpty ? _selectedUnit : "unit"}',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _unitPrice > 0 ? Formatters.formatRupiah(_unitPrice) : '—',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: colorScheme.outlineVariant,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Biaya',
                              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _totalCost > 0 ? Formatters.formatRupiah(_totalCost) : '—',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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

