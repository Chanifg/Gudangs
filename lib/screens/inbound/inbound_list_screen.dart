import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inbound_provider.dart';
import '../../core/formatters.dart';

class InboundListScreen extends ConsumerStatefulWidget {
  const InboundListScreen({super.key});

  @override
  ConsumerState<InboundListScreen> createState() => _InboundListScreenState();
}

class _InboundListScreenState extends ConsumerState<InboundListScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inboundProvider.notifier).loadInboundRecords();
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
      ref.read(inboundProvider.notifier).setFilters(dateRange: _selectedDateRange);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
    });
    ref.read(inboundProvider.notifier).clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final inboundState = ref.watch(inboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Masuk (Inbound)'),
        actions: [
          if (_selectedDateRange != null)
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                                      ? 'Pilih Rentang Tanggal'
                                      : '${Formatters.formatDate(_selectedDateRange!.start)} - ${Formatters.formatDate(_selectedDateRange!.end)}',
                                  style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Financial summary box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pengeluaran Pembelian:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF565E74), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        Formatters.formatRupiah(inboundState.records.fold(0.0, (sum, rec) => sum + rec.totalCost)),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006E2F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: inboundState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inboundState.records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_returned_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada transaksi barang masuk',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text('Silakan catat inbound menggunakan tombol (+)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(inboundProvider.notifier).loadInboundRecords();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: inboundState.records.length,
                          itemBuilder: (context, index) {
                            final rec = inboundState.records[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            rec.productName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0B1C30),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          Formatters.formatDate(rec.date),
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'SKU: ${rec.productSku}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Jumlah & Harga Satuan', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${rec.quantity} unit @ ${Formatters.formatRupiah(rec.pricePerUnit)}',
                                              style: const TextStyle(fontSize: 12, color: Color(0xFF0B1C30)),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Total Biaya', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                                            const SizedBox(height: 2),
                                            Text(
                                              Formatters.formatRupiah(rec.totalCost),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF006E2F),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (rec.notes != null && rec.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Catatan: "${rec.notes}"',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/transactions/inbound/add');
        },
        tooltip: 'Catat Barang Masuk',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
