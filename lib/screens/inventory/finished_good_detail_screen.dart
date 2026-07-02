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

    return Scaffold(
      appBar: AppBar(
        title: Text(finishedGood.name),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Visual Product Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Icon(Icons.inventory_2, size: 40, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    finishedGood.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${finishedGood.sku}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isStockOut
                          ? const Color(0xFFBA1A1A).withValues(alpha: 0.1)
                          : const Color(0xFF006E2F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isStockOut ? 'STOK HABIS' : 'STOK TERSEDIA',
                      style: TextStyle(
                        color: isStockOut ? const Color(0xFFBA1A1A) : const Color(0xFF006E2F),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detail Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Barang',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(
                    label: 'Stok Saat Ini',
                    value: '${finishedGood.currentStock} ${finishedGood.unit}',
                    valueColor: isStockOut ? const Color(0xFFBA1A1A) : const Color(0xFF0B1C30),
                    isBold: true,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Satuan',
                    value: finishedGood.unit,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Harga Jual Standard',
                    value: Formatters.formatRupiah(finishedGood.defaultUnitPrice),
                    valueColor: const Color(0xFF0B1C30),
                    isBold: true,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Estimasi HPP Terakhir',
                    value: finishedGood.lastHPP != null
                        ? Formatters.formatRupiah(finishedGood.lastHPP!)
                        : 'Belum diproduksi',
                    valueColor: finishedGood.lastHPP != null ? const Color(0xFF006E2F) : Colors.grey,
                    isBold: finishedGood.lastHPP != null,
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Tanggal Ditambahkan',
                    value: Formatters.formatDate(finishedGood.createdAt),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    label: 'Pembaruan Terakhir',
                    value: Formatters.formatDate(finishedGood.updatedAt),
                  ),
                ],
              ),
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
            color: valueColor ?? const Color(0xFF0B1C30),
          ),
        ),
      ],
    );
  }
}
