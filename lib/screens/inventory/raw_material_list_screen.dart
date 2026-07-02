import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/raw_material_provider.dart';
import '../../core/formatters.dart';

class RawMaterialListScreen extends ConsumerWidget {
  const RawMaterialListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialState = ref.watch(rawMaterialProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bahan Baku'),
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
                  'Inventori Bahan Baku',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar bahan baku mentah yang disimpan di gudang untuk keperluan produksi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(rawMaterialProvider.notifier).setSearchKeyword(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama bahan baku atau SKU...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: materialState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : materialState.rawMaterials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Bahan baku tidak ditemukan',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan item bahan baku baru untuk memulai pencatatan.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(rawMaterialProvider.notifier).loadRawMaterials();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: materialState.rawMaterials.length,
                          itemBuilder: (context, index) {
                            final material = materialState.rawMaterials[index];
                            final isStockOut = material.currentStock <= 0;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  context.push('/inventory/raw-materials/${material.id}');
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
                                              material.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0B1C30),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'SKU: ${material.sku}',
                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                const Text(
                                                  'Harga Beli: ',
                                                  style: TextStyle(fontSize: 12, color: Color(0xFF565E74)),
                                                ),
                                                Text(
                                                  Formatters.formatRupiah(material.defaultUnitCost),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0B1C30),
                                                  ),
                                                ),
                                                Text(
                                                  ' / ${material.unit}',
                                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                            '${material.currentStock} ${material.unit}',
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
          context.push('/inventory/raw-materials/add');
        },
        tooltip: 'Tambah Bahan Baku',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
