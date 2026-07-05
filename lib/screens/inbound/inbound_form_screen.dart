import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../providers/inbound_provider.dart';
import '../../models/raw_material.dart';
import '../../models/finished_good.dart';
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

  String _itemType = 'raw_material'; // 'raw_material' or 'product'
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
      ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
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
        SnackBar(content: Text(_itemType == 'product' ? 'Pilih barang jadi terlebih dahulu' : 'Pilih bahan baku terlebih dahulu')),
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
          itemType: _itemType,
        );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawMaterialState = ref.watch(rawMaterialProvider);
    final finishedGoodState = ref.watch(finishedGoodProvider);
    final inboundState = ref.watch(inboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final activeItems = _itemType == 'product'
        ? finishedGoodState.finishedGoods.where((fg) => !fg.isDeleted).toList()
        : rawMaterialState.rawMaterials;

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

                // Segmented toggle button for Bahan Baku vs Barang Jadi
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_itemType != 'raw_material') {
                              setState(() {
                                _itemType = 'raw_material';
                                _selectedProductId = null;
                                _selectedUnit = '';
                                _updateCalculations();
                              });
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _itemType == 'raw_material' ? colorScheme.primary : colorScheme.surfaceVariant,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                              border: Border.all(color: _itemType == 'raw_material' ? colorScheme.primary : colorScheme.outlineVariant),
                            ),
                            child: Text(
                              'Bahan Baku',
                              style: TextStyle(
                                color: _itemType == 'raw_material' ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            if (_itemType != 'product') {
                              setState(() {
                                _itemType = 'product';
                                _selectedProductId = null;
                                _selectedUnit = '';
                                _updateCalculations();
                              });
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _itemType == 'product' ? colorScheme.primary : colorScheme.surfaceVariant,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              border: Border.all(color: _itemType == 'product' ? colorScheme.primary : colorScheme.outlineVariant),
                            ),
                            child: Text(
                              'Barang Jadi (Reseller)',
                              style: TextStyle(
                                color: _itemType == 'product' ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Dropdown Selection
                DropdownButtonFormField<String>(
                  value: _selectedProductId,
                  key: ValueKey('${_itemType}_dropdown'),
                  decoration: InputDecoration(
                    labelText: _itemType == 'product' ? 'Pilih Barang Jadi *' : 'Pilih Bahan Baku *',
                  ),
                  items: activeItems.map((prod) {
                    final String displaySku = (prod is RawMaterial) ? prod.sku : (prod as FinishedGood).sku;
                    final String displayId = (prod is RawMaterial) ? prod.id : (prod as FinishedGood).id;
                    final String displayName = (prod is RawMaterial) ? prod.name : (prod as FinishedGood).name;
                    return DropdownMenuItem<String>(
                      value: displayId,
                      child: Text('$displayName ($displaySku)'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProductId = val;
                      if (val != null) {
                        final item = activeItems.firstWhere((p) {
                          final pId = (p is RawMaterial) ? p.id : (p as FinishedGood).id;
                          return pId == val;
                        });
                        _selectedUnit = (item is RawMaterial) ? item.unit : (item as FinishedGood).unit;
                      }
                    });
                  },
                  validator: (value) => value == null
                      ? (_itemType == 'product' ? 'Wajib memilih barang jadi' : 'Wajib memilih bahan baku')
                      : null,
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

