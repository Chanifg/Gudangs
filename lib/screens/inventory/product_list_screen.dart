import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inventory_provider.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: colorScheme.surfaceVariant,
            child: const Icon(Icons.person, color: Color(0xFF006E2F)),
          ),
        ),
        title: const Text('Halo, Admin Gudang'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            color: colorScheme.primary,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventori Stok',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                TextField(
                  onChanged: (val) {
                    ref.read(inventoryProvider.notifier).setSearchKeyword(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Categories Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: inventoryState.categories.length,
                    itemBuilder: (context, index) {
                      final category = inventoryState.categories[index];
                      final isSelected = inventoryState.selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(inventoryProvider.notifier).setCategoryFilter(category);
                          },
                          selectedColor: colorScheme.primaryContainer.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.secondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? colorScheme.primaryContainer : colorScheme.outlineVariant,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Inventory List
          Expanded(
            child: inventoryState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : inventoryState.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Produk tidak ditemukan',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(inventoryProvider.notifier).loadProducts();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: inventoryState.products.length,
                          itemBuilder: (context, index) {
                            final product = inventoryState.products[index];
                            
                            // Low stock threshold definition (e.g. less than 10 units)
                            final isLowStock = product.currentStock < 10;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: InkWell(
                                onTap: () {
                                  context.push('/inventory/${product.id}');
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isLowStock
                                        ? Border(
                                            left: BorderSide(color: colorScheme.error, width: 4),
                                            top: const BorderSide(color: Color(0xFFE2E8F0)),
                                            right: const BorderSide(color: Color(0xFFE2E8F0)),
                                            bottom: const BorderSide(color: Color(0xFFE2E8F0)),
                                          )
                                        : Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      // Product icon container
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isLowStock
                                              ? colorScheme.error.withOpacity(0.1)
                                              : colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isLowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                                          color: isLowStock ? colorScheme.error : colorScheme.secondary,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Product Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.name,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.surfaceVariant,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    product.sku,
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                          fontFamily: 'monospace',
                                                          fontSize: 10,
                                                        ),
                                                  ),
                                                ),
                                                if (product.category != null && product.category!.isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    '•  ${product.category}',
                                                    style: Theme.of(context).textTheme.bodySmall,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Product Stock
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${product.currentStock.toStringAsFixed(product.currentStock % 1 == 0 ? 0 : 1)} ${product.unit}',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock ? colorScheme.error : colorScheme.primaryContainer,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isLowStock ? 'Stok Menipis' : 'Tersedia',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 10,
                                                  color: isLowStock ? colorScheme.error : colorScheme.secondary,
                                                  fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                                ),
                                          ),
                                        ],
                                      ),
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
          context.push('/inventory/add');
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
