import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bom_provider.dart';
import '../../providers/production_provider.dart';
import '../../core/formatters.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  const ProductionScreen({super.key});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedBOMId;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bomProvider.notifier).loadBOMs();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _executeProduction(bool isStockEnough) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBOMId == null) return;
    if (!isStockEnough) return;

    final qty = double.tryParse(_qtyController.text) ?? 0.0;
    if (qty <= 0) return;

    setState(() => _isSubmitting = true);

    final success = await ref.read(productionProvider.notifier).executeProduction(
          bomId: _selectedBOMId!,
          quantityProduced: qty,
          date: _selectedDate,
          note: _noteController.text,
        );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF006E2F)),
                  SizedBox(width: 8),
                  Text('Produksi Berhasil'),
                ],
              ),
              content: const Text(
                'Proses produksi berhasil dicatat. Stok bahan baku otomatis dikurangi, dan stok barang jadi otomatis bertambah.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // pop screen
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        final err = ref.read(productionProvider).errorMessage ?? 'Gagal memproses produksi';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: const Color(0xFFBA1A1A)),
        );
        ref.read(productionProvider.notifier).clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bomState = ref.watch(bomProvider);

    // Run live validation if BOM and quantity are entered
    final qtyText = _qtyController.text;
    final qty = double.tryParse(qtyText) ?? 0.0;

    ProductionValidationResult? validationResult;
    if (_selectedBOMId != null && qty > 0) {
      validationResult = ref.read(productionProvider.notifier).validateStock(_selectedBOMId!, qty);
    }

    final bool isStockEnough = validationResult?.isEnough ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eksekusi Produksi'),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : bomState.boms.isEmpty && !bomState.isLoading
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.precision_manufacturing_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'Formula BOM Belum Tersedia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Anda memerlukan minimal satu formula BOM (resep produksi) sebelum dapat mengeksekusi produksi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            // Navigate to BOM screen or let user create one
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Form Produksi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0B1C30),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Select Formula BOM
                              DropdownButtonFormField<String>(
                                initialValue: _selectedBOMId,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Formula BOM (Resep)',
                                ),
                                items: bomState.boms.map((bom) {
                                  return DropdownMenuItem<String>(
                                    value: bom.id,
                                    child: Text(bom.name),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedBOMId = val;
                                  });
                                },
                                validator: (val) {
                                  if (val == null) return 'Pilih formula BOM';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Production Quantity Input
                              TextFormField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Jumlah Produksi (Unit)',
                                  hintText: 'Misal: 50',
                                ),
                                onChanged: (_) {
                                  // Trigger rebuild to update live validation
                                  setState(() {});
                                },
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Jumlah produksi wajib diisi';
                                  }
                                  final parsed = double.tryParse(val);
                                  if (parsed == null || parsed <= 0) {
                                    return 'Kuantitas harus lebih besar dari 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Date Input field
                              InkWell(
                                onTap: _selectDate,
                                child: IgnorePointer(
                                  child: TextFormField(
                                    decoration: InputDecoration(
                                      labelText: 'Tanggal Produksi',
                                      hintText: Formatters.formatDate(_selectedDate),
                                      prefixIcon: const Icon(Icons.calendar_today),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Notes (Catatan)
                              TextFormField(
                                controller: _noteController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Catatan Produksi (Opsional)',
                                  hintText: 'Catatan tambahan terkait produksi...',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Live Checklist of Raw Materials
                      if (validationResult != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kebutuhan Bahan Baku',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C30),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: validationResult.details.length,
                                  separatorBuilder: (context, index) => const Divider(height: 16),
                                  itemBuilder: (context, idx) {
                                    final detail = validationResult!.details[idx];
                                    return Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          detail.isEnough ? Icons.check_circle : Icons.warning_amber_rounded,
                                          color: detail.isEnough ? const Color(0xFF006E2F) : const Color(0xFFBA1A1A),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detail.rawMaterialName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0B1C30),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Dibutuhkan: ${detail.requiredQty} ${detail.unit} | Tersedia: ${detail.availableQty} ${detail.unit}',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!detail.isEnough)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Kurang ${detail.deficit.toStringAsFixed(1)}',
                                              style: const TextStyle(
                                                color: Color(0xFFBA1A1A),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Financial Cost Summary
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimasi Biaya Produksi',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C30),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Biaya Material', style: TextStyle(fontSize: 13, color: Color(0xFF565E74))),
                                    Text(
                                      Formatters.formatRupiah(validationResult.estimatedTotalCost),
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('HPP per Unit (Hasil Jadi)', style: TextStyle(fontSize: 13, color: Color(0xFF565E74))),
                                    Text(
                                      Formatters.formatRupiah(validationResult.estimatedHPP),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006E2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Insufficient Stock Banner Warning
                        if (!isStockEnough) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBA1A1A).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.error_outline, color: Color(0xFFBA1A1A)),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Bahan Baku Tidak Cukup. Silakan lakukan pembelian bahan baku terlebih dahulu.',
                                    style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // Execution action button
                      ElevatedButton(
                        onPressed: _selectedBOMId != null && qty > 0 && isStockEnough
                            ? () => _executeProduction(isStockEnough)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isStockEnough ? const Color(0xFF006E2F) : Colors.grey[400],
                        ),
                        child: const Text('MULAI PRODUKSI'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
