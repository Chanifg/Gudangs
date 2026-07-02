import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/outbound_provider.dart';
import '../../core/formatters.dart';
import '../../models/outbound_record.dart';

class OutboundListScreen extends ConsumerStatefulWidget {
  const OutboundListScreen({super.key});

  @override
  ConsumerState<OutboundListScreen> createState() => _OutboundListScreenState();
}

class _OutboundListScreenState extends ConsumerState<OutboundListScreen> {
  DateTimeRange? _selectedDateRange;
  OutboundStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(outboundProvider.notifier).loadOutboundRecords();
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
    ref.read(outboundProvider.notifier).setFilters(
          dateRange: _selectedDateRange,
          status: _selectedStatus,
        );
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedStatus = null;
    });
    ref.read(outboundProvider.notifier).clearFilters();
  }

  Color _getStatusColor(OutboundStatus status) {
    switch (status) {
      case OutboundStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case OutboundStatus.terkirim:
        return const Color(0xFF006E2F); // Green
      case OutboundStatus.dibatalkan:
        return const Color(0xFFBA1A1A); // Red
    }
  }

  String _getStatusText(OutboundStatus status) {
    switch (status) {
      case OutboundStatus.pending:
        return 'PENDING';
      case OutboundStatus.terkirim:
        return 'TERKIRIM';
      case OutboundStatus.dibatalkan:
        return 'DIBATALKAN';
    }
  }

  void _showStatusUpdateDialog(BuildContext context, OutboundRecord record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Status Pengiriman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: OutboundStatus.values.map((status) {
              return ListTile(
                title: Text(_getStatusText(status)),
                leading: Radio<OutboundStatus>(
                  value: status,
                  groupValue: record.status,
                  onChanged: (val) async {
                    Navigator.pop(context);
                    if (val != null) {
                      final success = await ref.read(outboundProvider.notifier).updateStatus(record.id, val);
                      if (!success && context.mounted) {
                        final err = ref.read(outboundProvider).errorMessage ?? 'Gagal memperbarui status';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err), backgroundColor: const Color(0xFFBA1A1A)),
                        );
                        ref.read(outboundProvider.notifier).clearError();
                      }
                    }
                  },
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final outboundState = ref.watch(outboundProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Keluar (Outbound)'),
        actions: [
          if (_selectedDateRange != null || _selectedStatus != null)
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
          // Filter Row
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
                  ],
                ),
                const SizedBox(height: 8),

                // Status Chips filter Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua', style: TextStyle(fontSize: 11)),
                        selected: _selectedStatus == null,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending', style: TextStyle(fontSize: 11)),
                        selected: _selectedStatus == OutboundStatus.pending,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = OutboundStatus.pending;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Terkirim', style: TextStyle(fontSize: 11)),
                        selected: _selectedStatus == OutboundStatus.terkirim,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = OutboundStatus.terkirim;
                          });
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Dibatalkan', style: TextStyle(fontSize: 11)),
                        selected: _selectedStatus == OutboundStatus.dibatalkan,
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = OutboundStatus.dibatalkan;
                          });
                          _applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Financial Revenue summary box
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
                        'Total Pendapatan Terkirim & Pending:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF565E74), fontWeight: FontWeight.w500),
                      ),
                      Text(
                        Formatters.formatRupiah(ref.read(outboundProvider.notifier).totalOutboundValue),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF006E2F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: outboundState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : outboundState.records.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada transaksi barang keluar',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text('Silakan catat outbound menggunakan tombol (+)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(outboundProvider.notifier).loadOutboundRecords();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: outboundState.records.length,
                          itemBuilder: (context, index) {
                            final rec = outboundState.records[index];
                            final statusColor = _getStatusColor(rec.status);

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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'SKU: ${rec.productSku}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        InkWell(
                                          onTap: () => _showStatusUpdateDialog(context, rec),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _getStatusText(rec.status),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(Icons.arrow_drop_down, size: 14, color: statusColor),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tujuan: ${rec.destination}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0B1C30)),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${rec.quantity} unit @ ${Formatters.formatRupiah(rec.sellingPricePerUnit)}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF565E74)),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('Nilai Transaksi', style: TextStyle(fontSize: 11, color: Color(0xFF565E74))),
                                            const SizedBox(height: 2),
                                            Text(
                                              Formatters.formatRupiah(rec.totalValue),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: rec.status == OutboundStatus.dibatalkan ? Colors.grey : const Color(0xFF006E2F),
                                                decoration: rec.status == OutboundStatus.dibatalkan ? TextDecoration.lineThrough : null,
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
          context.push('/transactions/outbound/add');
        },
        tooltip: 'Catat Barang Keluar',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
