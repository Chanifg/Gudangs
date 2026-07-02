import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';
import '../../services/database_service.dart';
import '../../core/formatters.dart';

class RawMaterialDetailScreen extends ConsumerWidget {
  final String materialId;
  const RawMaterialDetailScreen({super.key, required this.materialId});

  List<Map<String, dynamic>> _getStockHistory(String materialId) {
    final List<Map<String, dynamic>> history = [];

    // Fetch Inbound Records (Raw Material Incoming)
    final inbounds = DatabaseService.inboundBox.values
        .where((rec) => rec.productId == materialId)
        .toList();
    for (final rec in inbounds) {
      history.add({
        'type': 'inbound',
        'quantity': rec.quantity,
        'date': rec.date,
        'title': 'Bahan Baku Masuk',
        'subtitle': rec.notes ?? 'Penerimaan bahan baku',
      });
    }

    // Fetch Production Usage (Raw Material Outgoing)
    final productions = DatabaseService.productionBox.values
        .where((prod) => prod.materialsUsed.any((mu) => mu.rawMaterialId == materialId))
        .toList();
    for (final prod in productions) {
      final usage = prod.materialsUsed.firstWhere((mu) => mu.rawMaterialId == materialId);
      history.add({
        'type': 'production_usage',
        'quantity': usage.quantityUsed,
        'date': prod.date,
        'title': 'Dipakai Produksi',
        'subtitle': 'Produksi: ${prod.finishedGoodName}',
      });
    }

    // Sort by date descending
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return history;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(rawMaterialProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final material = state.rawMaterials.firstWhere(
      (m) => m.id == materialId,
      orElse: () => DatabaseService.rawMaterialsBox.get(materialId)!,
    );

    final history = _getStockHistory(materialId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Bahan Baku'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              context.push('/raw-materials/$materialId/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Bahan Baku'),
                  content: const Text('Apakah Anda yakin ingin menghapus bahan baku ini?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Hapus'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final success = await ref.read(rawMaterialProvider.notifier).deleteRawMaterial(materialId);
                if (success && context.mounted) {
                  context.pop();
                } else if (context.mounted) {
                  final err = ref.read(rawMaterialProvider).errorMessage ?? 'Gagal menghapus';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info Card
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      material.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Bahan Baku',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        material.sku,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Satuan: ${material.unit}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STOK SAAT INI',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${material.currentStock.toStringAsFixed(material.currentStock % 1 == 0 ? 0 : 1)} ${material.unit}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: material.currentStock < 10 ? Colors.red : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HARGA BELI DEFAULT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatRupiah(material.defaultUnitCost),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // History Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Riwayat Transaksi Stok',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada riwayat transaksi untuk bahan baku ini.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: history.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final isIncoming = item['type'] == 'inbound';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                                    fontSize: 15,
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
}
