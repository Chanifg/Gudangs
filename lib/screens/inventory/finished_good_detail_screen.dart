import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finished_good_provider.dart';
import '../../services/database_service.dart';
import '../../core/formatters.dart';
import '../../models/finished_good.dart';

class FinishedGoodDetailScreen extends ConsumerWidget {
  final String finishedGoodId;

  const FinishedGoodDetailScreen({super.key, required this.finishedGoodId});

  List<Map<String, dynamic>> _getStockHistory(String finishedGoodId) {
    if (!DatabaseService.isOperationalOpen) return [];
    final List<Map<String, dynamic>> history = [];

    // Fetch unified Stock Movements for this product
    final movements = DatabaseService.stockMovementsBox.values
        .where((m) => m.itemId == finishedGoodId && m.itemType == 'product')
        .toList();

    // Sort by date descending
    movements.sort((a, b) => b.date.compareTo(a.date));

    for (final m in movements) {
      final isIncoming = m.type == 'inbound' || m.type == 'production_in' || m.type == 'adjustment_add';
      String title = 'Koreksi Stok';
      if (m.type == 'inbound') title = 'Barang Masuk';
      if (m.type == 'production_in') title = 'Hasil Produksi';
      if (m.type == 'outbound') title = 'Barang Keluar';
      if (m.type == 'adjustment_add') title = 'Koreksi (Tambah)';
      if (m.type == 'adjustment_sub') title = 'Koreksi (Kurang)';
      if (m.type == 'opname') title = 'Stock Opname';

      history.add({
        'type': m.type,
        'quantity': m.quantity,
        'date': m.date,
        'title': title,
        'subtitle': m.notes ?? '',
        'isIncoming': isIncoming,
      });
    }

    return history;
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FinishedGood finishedGood) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Barang Jadi'),
          content: Text('Apakah Anda yakin ingin menghapus barang jadi "${finishedGood.name}"?\n\nTindakan ini tidak dapat dibatalkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                final success = await ref.read(finishedGoodProvider.notifier).deleteFinishedGood(finishedGood.id);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barang jadi berhasil dihapus')),
                    );
                    Navigator.pop(context); // Go back to list
                  } else {
                    final err = ref.read(finishedGoodProvider).errorMessage ?? 'Gagal menghapus barang jadi';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: const Color(0xFFBA1A1A)),
                    );
                    ref.read(finishedGoodProvider.notifier).clearError();
                  }
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Color(0xFFBA1A1A))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch finishedGoodProvider to rebuild if changes occur
    ref.watch(finishedGoodProvider);

    final finishedGood = DatabaseService.finishedGoodsBox.get(finishedGoodId);
    final colorScheme = Theme.of(context).colorScheme;

    if (finishedGood == null || finishedGood.isDeleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Barang Jadi')),
        body: const Center(
          child: Text('Barang jadi tidak ditemukan atau telah dihapus'),
        ),
      );
    }

    final isStockOut = finishedGood.currentStock <= 0;
    final history = _getStockHistory(finishedGoodId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang Jadi'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/more/stock-adjustment?itemId=${finishedGood.id}&itemType=product');
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Sesuaikan Stok',
          ),
          IconButton(
            onPressed: () {
              context.push('/inventory/finished-goods/${finishedGood.id}/edit');
            },
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Barang Jadi',
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref, finishedGood),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
            tooltip: 'Hapus Barang Jadi',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Product Header Card
          Container(
            color: colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Icon(Icons.inventory_2, size: 36, color: colorScheme.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  finishedGood.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${finishedGood.sku}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isStockOut
                        ? const Color(0xFFBA1A1A).withOpacity(0.1)
                        : const Color(0xFF006E2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isStockOut ? 'STOK HABIS' : 'STOK TERSEDIA',
                    style: TextStyle(
                      color: isStockOut ? const Color(0xFFBA1A1A) : const Color(0xFF006E2F),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      label: 'Stok Saat Ini',
                      value: '${finishedGood.currentStock} ${finishedGood.unit}',
                      valueColor: isStockOut ? const Color(0xFFBA1A1A) : colorScheme.onSurface,
                      isBold: true,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      label: 'Satuan',
                      value: finishedGood.unit,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      label: 'Harga Jual Standard',
                      value: Formatters.formatRupiah(finishedGood.defaultUnitPrice),
                      isBold: true,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      label: 'Estimasi HPP Terakhir',
                      value: finishedGood.lastHPP != null
                          ? Formatters.formatRupiah(finishedGood.lastHPP!)
                          : 'Belum diproduksi',
                      valueColor: finishedGood.lastHPP != null ? const Color(0xFF006E2F) : Colors.grey,
                      isBold: finishedGood.lastHPP != null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // History Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Riwayat Transaksi Stok',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada riwayat transaksi untuk barang jadi ini.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: colorScheme.outlineVariant),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isIncoming = item['isIncoming'] as bool;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isIncoming ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isIncoming ? Colors.green : Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle'] as String,
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isIncoming ? "+" : "-"}${item['quantity'].toStringAsFixed(item['quantity'] % 1 == 0 ? 0 : 1)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isIncoming ? Colors.green : Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDate(item['date'] as DateTime),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF565E74)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
