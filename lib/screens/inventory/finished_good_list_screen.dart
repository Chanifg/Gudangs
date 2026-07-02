import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/finished_good_provider.dart';
import '../../core/formatters.dart';

class FinishedGoodListScreen extends ConsumerWidget {
  const FinishedGoodListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finishedGoodState = ref.watch(finishedGoodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang Jadi'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventori Barang Jadi',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar barang jadi siap jual yang dihasilkan dari proses produksi di gudang.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(finishedGoodProvider.notifier).setSearchKeyword(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama barang jadi atau SKU...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: finishedGoodState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : finishedGoodState.finishedGoods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Barang jadi tidak ditemukan',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan barang jadi baru untuk memulai pencatatan.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: finishedGoodState.finishedGoods.length,
                          itemBuilder: (context, index) {
                            final item = finishedGoodState.finishedGoods[index];
                            final isStockOut = item.currentStock <= 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  context.push('/inventory/finished-goods/${item.id}');
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0B1C30),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'SKU: ${item.sku}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Harga Jual: ',
                                                  style: TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                                                ),
                                                Text(
                                                  Formatters.formatRupiah(item.defaultUnitPrice),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0B1C30),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (item.lastHPP != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Text(
                                                    'HPP Terakhir: ',
                                                    style: TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                                                  ),
                                                  Text(
                                                    Formatters.formatRupiah(item.lastHPP!),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF006E2F),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item.currentStock} ${item.unit}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isStockOut ? const Color(0xFFBA1A1A) : const Color(0xFF0B1C30),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isStockOut
                                                  ? const Color(0xFFBA1A1A).withValues(alpha: 0.1)
                                                  : const Color(0xFF006E2F).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              isStockOut ? 'HABIS' : 'TERSEDIA',
                                              style: TextStyle(
                                                color: isStockOut ? const Color(0xFFBA1A1A) : const Color(0xFF006E2F),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
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
          context.push('/inventory/finished-goods/add');
        },
        tooltip: 'Tambah Barang Jadi',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
