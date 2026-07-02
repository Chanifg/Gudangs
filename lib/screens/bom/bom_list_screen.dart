import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bom_provider.dart';
import '../../core/formatters.dart';
import '../../models/bill_of_materials.dart';

class BomListScreen extends ConsumerWidget {
  const BomListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bomState = ref.watch(bomProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formula BOM'),
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
                  'Bill of Materials (BOM)',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daftar formula produksi untuk merakit bahan baku mentah menjadi barang jadi.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(bomProvider.notifier).setSearchKeyword(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari nama formula atau barang jadi...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: bomState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bomState.boms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada formula BOM',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tambahkan formula untuk mulai memproduksi barang jadi.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push('/inventory/bom/add');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Buat Formula'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(bomProvider.notifier).loadBOMs();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: bomState.boms.length,
                          itemBuilder: (context, index) {
                            final bom = bomState.boms[index];
                            return _buildBOMCard(context, ref, bom, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/inventory/bom/add');
        },
        tooltip: 'Tambah Formula BOM',
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBOMCard(
    BuildContext context,
    WidgetRef ref,
    BillOfMaterials bom,
    ColorScheme colorScheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/inventory/bom/${bom.id}/edit');
        },
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
                          bom.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.label_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                bom.finishedGoodName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF565E74),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _confirmDelete(context, ref, bom),
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A)),
                        tooltip: 'Hapus Formula',
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'Komponen Bahan Baku:',
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
                itemCount: bom.components.length,
                itemBuilder: (context, idx) {
                  final comp = bom.components[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '• ${comp.rawMaterialName}',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0B1C30)),
                        ),
                        Text(
                          '${comp.quantityPerUnit} ${comp.rawMaterialUnit}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF006E2F),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Dibuat: ${Formatters.formatDate(bom.createdAt)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, BillOfMaterials bom) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Formula BOM'),
          content: Text('Apakah Anda yakin ingin menghapus formula BOM "${bom.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(bomProvider.notifier).deleteBOM(bom.id);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Formula BOM berhasil dihapus')),
                    );
                  } else {
                    final err = ref.read(bomProvider).errorMessage ?? 'Gagal menghapus formula';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: const Color(0xFFBA1A1A)),
                    );
                    ref.read(bomProvider.notifier).clearError();
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
}
