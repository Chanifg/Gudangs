import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../core/formatters.dart';
import '../../widgets/theme_toggle_button.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rawSearchController = TextEditingController();
  final _finishedSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to update active tab index and FAB
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rawMaterialProvider.notifier).loadRawMaterials();
      ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawSearchController.dispose();
    _finishedSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawMaterialState = ref.watch(rawMaterialProvider);
    final finishedGoodState = ref.watch(finishedGoodProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate tab aggregates
    final rawMaterials = rawMaterialState.rawMaterials;
    final rawMaterialSkuCount = rawMaterials.length;
    final rawMaterialUnitCount = rawMaterials.fold(0.0, (sum, m) => sum + m.currentStock);

    final finishedGoods = finishedGoodState.finishedGoods;
    final finishedGoodSkuCount = finishedGoods.length;
    final finishedGoodUnitCount = finishedGoods.fold(0.0, (sum, f) => sum + f.currentStock);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventori Gudang'),
        actions: const [
          ThemeToggleButton(),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF006E2F),
          labelColor: const Color(0xFF006E2F),
          unselectedLabelColor: const Color(0xFF565E74),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.category_outlined),
              text: 'Bahan Baku',
            ),
            Tab(
              icon: Icon(Icons.inventory_2_outlined),
              text: 'Barang Jadi',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Bahan Baku Tab Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner & Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B1C30), Color(0xFF1E2E42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Total SKU', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('$rawMaterialSkuCount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white24),
                          Column(
                            children: [
                              const Text('Total Unit', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.decimalPattern('id_ID').format(rawMaterialUnitCount),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      controller: _rawSearchController,
                      onChanged: (val) {
                        ref.read(rawMaterialProvider.notifier).setSearchKeyword(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari bahan baku atau SKU...',
                        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                        suffixIcon: _rawSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _rawSearchController.clear();
                                  ref.read(rawMaterialProvider.notifier).setSearchKeyword('');
                                },
                              )
                            : null,
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Raw Material List
              Expanded(
                child: rawMaterialState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : rawMaterials.isEmpty
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
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.read(rawMaterialProvider.notifier).loadRawMaterials();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: rawMaterials.length,
                              itemBuilder: (context, index) {
                                final material = rawMaterials[index];
                                final isStockOut = material.currentStock <= 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
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
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
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
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.onSurface,
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
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isStockOut ? const Color(0xFFBA1A1A) : colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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

          // 2. Barang Jadi Tab Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner & Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF006E2F), Color(0xFF005222)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Total SKU', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('$finishedGoodSkuCount', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white24),
                          Column(
                            children: [
                              const Text('Total Unit', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.decimalPattern('id_ID').format(finishedGoodUnitCount),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Search Bar
                    TextField(
                      controller: _finishedSearchController,
                      onChanged: (val) {
                        ref.read(finishedGoodProvider.notifier).setSearchKeyword(val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari barang jadi atau SKU...',
                        prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                        suffixIcon: _finishedSearchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _finishedSearchController.clear();
                                  ref.read(finishedGoodProvider.notifier).setSearchKeyword('');
                                },
                              )
                            : null,
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Finished Good List
              Expanded(
                child: finishedGoodState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : finishedGoods.isEmpty
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
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: finishedGoods.length,
                              itemBuilder: (context, index) {
                                final item = finishedGoods[index];
                                final isStockOut = item.currentStock <= 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
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
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.onSurface,
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
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.onSurface,
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
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: isStockOut ? const Color(0xFFBA1A1A) : colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/inventory/raw-materials/add');
          } else {
            context.push('/inventory/finished-goods/add');
          }
        },
        tooltip: _tabController.index == 0 ? 'Tambah Bahan Baku' : 'Tambah Barang Jadi',
        backgroundColor: const Color(0xFF006E2F),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
