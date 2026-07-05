import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/production_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../core/formatters.dart';
import '../../models/production_record.dart';

class ProductionHistoryScreen extends ConsumerStatefulWidget {
  const ProductionHistoryScreen({super.key});

  @override
  ConsumerState<ProductionHistoryScreen> createState() => _ProductionHistoryScreenState();
}

class _ProductionHistoryScreenState extends ConsumerState<ProductionHistoryScreen> {
  DateTimeRange? _selectedDateRange;
  String? _selectedFinishedGoodId;
  final Set<String> _expandedRecordIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
      ref.read(productionProvider.notifier).loadProductionRecords();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    ref.read(productionProvider.notifier).setFilters(
          dateRange: _selectedDateRange,
          finishedGoodId: _selectedFinishedGoodId,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedFinishedGoodId = null;
    });
    ref.read(productionProvider.notifier).clearFilters();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedRecordIds.contains(id)) {
        _expandedRecordIds.remove(id);
      } else {
        _expandedRecordIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prodState = ref.watch(productionProvider);
    final fgState = ref.watch(finishedGoodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate total summary of loaded records
    double totalQtyProduced = 0.0;
    double totalCost = 0.0;
    for (final rec in prodState.records) {
      totalQtyProduced += rec.quantityProduced;
      totalCost += rec.hpp * rec.quantityProduced;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Produksi'),
        actions: [
          if (_selectedDateRange != null || _selectedFinishedGoodId != null)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Reset Filter',
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Date Filter Chip button
                    Expanded(
                      child: InkWell(
                        onTap: _pickDateRange,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedDateRange == null
                                      ? 'Semua Tanggal'
                                      : '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}',
                                  style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Finished Good Filter Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFinishedGoodId,
                            hint: const Text('Semua Produk', style: TextStyle(fontSize: 12)),
                            isExpanded: true,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Semua Produk', style: TextStyle(fontSize: 12)),
                              ),
                              ...fgState.finishedGoods.map((fg) {
                                return DropdownMenuItem<String>(
                                  value: fg.id,
                                  child: Text(fg.name, style: const TextStyle(fontSize: 12)),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedFinishedGoodId = val;
                              });
                              _applyFilters();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Financial & Production summary box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Produksi', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                            const SizedBox(height: 4),
                            Text(
                              '${totalQtyProduced.toStringAsFixed(0)} Unit',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Nilai HPP', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatRupiah(totalCost),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006E2F)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: prodState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prodState.records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada riwayat produksi',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text('Silakan lakukan transaksi produksi terlebih dahulu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(productionProvider.notifier).loadProductionRecords();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: prodState.records.length,
                          itemBuilder: (context, index) {
                            final record = prodState.records[index];
                            final isExpanded = _expandedRecordIds.contains(record.id);

                            return _buildRecordCard(context, record, isExpanded, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    ProductionRecord record,
    bool isExpanded,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _toggleExpand(record.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.finishedGoodName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.bookmark_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              record.bomName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${record.quantityProduced.toStringAsFixed(0)} Unit',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006E2F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatDate(record.date),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Biaya Material', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatRupiah(record.totalMaterialCost),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                        ),
                        if (record.laborCost > 0) ...[
                          const SizedBox(height: 6),
                          const Text('Total Biaya Tenaga Kerja', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatRupiah(record.laborCost * record.quantityProduced),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('HPP per Unit', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatRupiah(record.hpp),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006E2F)),
                      ),
                      if (record.laborCost > 0) ...[
                        const SizedBox(height: 6),
                        const Text('Upah Tenaga/Unit', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatRupiah(record.laborCost),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF565E74)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              if (record.note != null && record.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Catatan: "${record.note}"',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],

              // Collapsed/Expanded Raw Material Usage Details
              if (isExpanded) ...[
                const Divider(height: 24),
                const Text(
                  'Detail Pemakaian Bahan Baku:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF565E74),
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: record.materialsUsed.length,
                  itemBuilder: (context, idx) {
                    final usage = record.materialsUsed[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• ${usage.rawMaterialName} (${usage.quantityUsed} ${usage.rawMaterialUnit})',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF0B1C30)),
                            ),
                          ),
                          Text(
                            Formatters.formatRupiah(usage.totalCost),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0B1C30)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 4),
              Center(
                child: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
