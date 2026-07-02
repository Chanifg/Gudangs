import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inventory_provider.dart';
import '../../core/formatters.dart';
import '../../services/database_service.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari inventori aktif? Riwayat transaksi lama akan tetap dipertahankan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(inventoryProvider.notifier).deleteProduct(productId);
              Navigator.pop(ctx); // Close dialog
              context.pop(); // Go back to list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inventoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Find the product in state
    final product = DatabaseService.productsBox.get(productId);
    
    if (product == null || product.isDeleted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: const Center(child: Text('Produk tidak ditemukan atau telah dihapus.')),
      );
    }

    final history = ref.read(inventoryProvider.notifier).getStockHistory(productId);
    final isLowStock = product.currentStock < 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Produk'),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/inventory/$productId/edit');
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _showDeleteConfirm(context, ref, product.name),
            icon: const Icon(Icons.delete_outline),
            color: colorScheme.error,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Main Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isLowStock
                              ? colorScheme.error.withOpacity(0.1)
                              : colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                          color: isLowStock ? colorScheme.error : colorScheme.secondary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'SKU: ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  product.sku,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Product Info Sections
              Text(
                'Informasi Stok & Kategori',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(context, 'Kategori', product.category ?? 'Tanpa Kategori'),
                      const Divider(color: Color(0xFFF1F5F9)),
                      _buildInfoRow(
                        context,
                        'Stok Tersedia',
                        '${product.currentStock.toStringAsFixed(product.currentStock % 1 == 0 ? 0 : 1)} ${product.unit}',
                        valueColor: isLowStock ? colorScheme.error : colorScheme.primaryContainer,
                        valueFontWeight: FontWeight.bold,
                      ),
                      const Divider(color: Color(0xFFF1F5F9)),
                      _buildInfoRow(context, 'Satuan Unit', product.unit),
                      const Divider(color: Color(0xFFF1F5F9)),
                      _buildInfoRow(context, 'Dibuat Pada', Formatters.formatDate(product.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Timeline Stock History
              Text(
                'Riwayat Mutasi Stok',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              if (history.isEmpty) ...[
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('Belum ada riwayat masuk/keluar produk ini.'),
                    ),
                  ),
                ),
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isIncoming = item['type'] == 'inbound';
                    final qtyVal = item['quantity'] as double;
                    final qtyStr = qtyVal.toStringAsFixed(qtyVal % 1 == 0 ? 0 : 1);
                    final date = item['date'] as DateTime;

                    return IntrinsicHeight(
                      child: Row(
                        children: [
                          // Left side line & dot
                          Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isIncoming ? colorScheme.primaryContainer : colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: index == history.length - 1 ? Colors.transparent : Colors.grey[300],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          
                          // Card content
                          Expanded(
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item['subtitle'] as String,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          Formatters.formatDate(date),
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      isIncoming ? '+$qtyStr' : '-$qtyStr',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isIncoming ? colorScheme.primaryContainer : colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? Theme.of(context).colorScheme.onBackground,
                  fontWeight: valueFontWeight ?? FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
