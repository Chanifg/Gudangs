import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/database_service.dart';
import '../../core/formatters.dart';
import '../../providers/inbound_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../providers/activity_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/inbound_record.dart';
import '../../models/outbound_record.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedFilter = 'week'; // 'week', 'month', 'custom'
  DateTimeRange? _customDateRange;

  DateTimeRange get _activeRange {
    final now = DateTime.now();
    if (_selectedFilter == 'week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    } else if (_selectedFilter == 'month') {
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    } else {
      return _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );
    }
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih Rentang Kustom',
    );
    if (picked != null) {
      setState(() {
        _selectedFilter = 'custom';
        _customDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers to trigger reactive updates when DB changes
    ref.watch(inboundProvider);
    ref.watch(outboundProvider);
    ref.watch(activityProvider);
    ref.watch(inventoryProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final range = _activeRange;

    // 1. Fetch real records from DB
    final allInbounds = DatabaseService.inboundBox.values.toList();
    final allOutbounds = DatabaseService.outboundBox.values.toList();
    final allActivities = DatabaseService.activityBox.values.toList();

    final filteredInbounds = allInbounds.where((r) => r.date.isAfter(range.start.subtract(const Duration(seconds: 1))) && r.date.isBefore(range.end.add(const Duration(seconds: 1)))).toList();
    final filteredOutbounds = allOutbounds.where((r) => r.date.isAfter(range.start.subtract(const Duration(seconds: 1))) && r.date.isBefore(range.end.add(const Duration(seconds: 1)))).toList();
    final filteredActivities = allActivities.where((r) => r.date.isAfter(range.start.subtract(const Duration(seconds: 1))) && r.date.isBefore(range.end.add(const Duration(seconds: 1)))).toList();

    // Check if we should fall back to mockup data (if there are no real transactions)
    final bool useMockup = filteredInbounds.isEmpty && filteredOutbounds.isEmpty && filteredActivities.isEmpty;

    // 2. Calculations
    double grossMargin = 24.5;
    double avgInbound = 142;
    double avgOutbound = 98;
    double totalInboundCost = 68000000;
    double totalOutboundValue = 90000000;

    List<EmployeeStatsItem> employeeStats = [];
    List<PopularProductItem> popularProducts = [];

    if (!useMockup) {
      totalInboundCost = filteredInbounds.fold(0.0, (sum, r) => sum + r.totalCost);
      totalOutboundValue = filteredOutbounds.where((r) => r.status != OutboundStatus.dibatalkan).fold(0.0, (sum, r) => sum + r.totalValue);

      if (totalOutboundValue > 0) {
        grossMargin = ((totalOutboundValue - totalInboundCost) / totalOutboundValue) * 100;
      } else {
        grossMargin = totalInboundCost > 0 ? -100.0 : 0.0;
      }

      final days = range.end.difference(range.start).inDays + 1;
      final double totalInboundUnits = filteredInbounds.fold(0.0, (sum, r) => sum + r.quantity);
      final double totalOutboundUnits = filteredOutbounds.where((r) => r.status != OutboundStatus.dibatalkan).fold(0.0, (sum, r) => sum + r.quantity);

      avgInbound = days > 0 ? totalInboundUnits / days : totalInboundUnits;
      avgOutbound = days > 0 ? totalOutboundUnits / days : totalOutboundUnits;

      // Group activities by employee
      final Map<String, int> empActivityCount = {};
      final Map<String, String> empNames = {};
      for (final act in filteredActivities) {
        empActivityCount[act.employeeId] = (empActivityCount[act.employeeId] ?? 0) + 1;
        empNames[act.employeeId] = act.employeeName;
      }

      final sortedEmpIds = empActivityCount.keys.toList()..sort((a, b) => empActivityCount[b]!.compareTo(empActivityCount[a]!));
      int maxAct = sortedEmpIds.isNotEmpty ? empActivityCount[sortedEmpIds.first]! : 1;

      employeeStats = sortedEmpIds.map((id) {
        final name = empNames[id]!;
        final count = empActivityCount[id]!;
        final progress = maxAct > 0 ? count / maxAct : 0.0;
        return EmployeeStatsItem(name: name, count: count, progress: progress);
      }).toList();

      // Group outbound quantities by product
      final Map<String, double> prodOutboundQty = {};
      final Map<String, String> prodNames = {};
      final Map<String, String> prodSkus = {};
      for (final ob in filteredOutbounds) {
        if (ob.status != OutboundStatus.dibatalkan) {
          prodOutboundQty[ob.productId] = (prodOutboundQty[ob.productId] ?? 0.0) + ob.quantity;
          prodNames[ob.productId] = ob.productName;
          prodSkus[ob.productId] = ob.productSku;
        }
      }

      final sortedProdIds = prodOutboundQty.keys.toList()..sort((a, b) => prodOutboundQty[b]!.compareTo(prodOutboundQty[a]!));
      popularProducts = sortedProdIds.map((id) {
        return PopularProductItem(
          name: prodNames[id]!,
          sku: prodSkus[id]!,
          quantity: prodOutboundQty[id]!,
        );
      }).toList();
    } else {
      // Setup Mockup Employee & Product Stats
      employeeStats = [
        EmployeeStatsItem(name: 'Budi Santoso', count: 120, progress: 0.85),
        EmployeeStatsItem(name: 'Ani Lestari', count: 108, progress: 0.72),
        EmployeeStatsItem(name: 'Dedi Wijaya', count: 95, progress: 0.60),
      ];
      popularProducts = [
        PopularProductItem(name: 'Beras Premium 5kg', sku: 'BRS-PRM-05', quantity: 124),
        PopularProductItem(name: 'Minyak Goreng 2L', sku: 'MYK-GRG-02', quantity: 98),
        PopularProductItem(name: 'Tepung Terigu 1kg', sku: 'TPG-TRG-01', quantity: 75),
      ];
    }

    final dateRangeStr = '${Formatters.formatDate(range.start)} - ${Formatters.formatDate(range.end)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Statistik Operasional'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Filter Row
            Row(
              children: [
                _buildFilterButton(
                  label: 'Minggu Ini',
                  isActive: _selectedFilter == 'week',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'week';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  label: 'Bulan Ini',
                  isActive: _selectedFilter == 'month',
                  onTap: () {
                    setState(() {
                      _selectedFilter = 'month';
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterButton(
                  label: 'Kustom',
                  isActive: _selectedFilter == 'custom',
                  icon: Icons.calendar_today,
                  onTap: () => _selectCustomRange(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateRangeStr,
              style: const TextStyle(fontSize: 12, color: Color(0xFF565E74), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (useMockup) ...[
              Card(
                color: colorScheme.primary.withValues(alpha: 0.05),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF006E2F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Menampilkan data simulasi (mockup) karena belum ada catatan transaksi pada rentang ini.',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Bento Grid Summary Performance Cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card 1: Gross Margin
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'MARGIN KOTOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF565E74),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF4FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.trending_up,
                                color: Color(0xFF006E2F),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${grossMargin.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0B1C30),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  grossMargin >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: grossMargin >= 0 ? const Color(0xFF22C55E) : const Color(0xFFBA1A1A),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${grossMargin >= 0 ? "+" : ""}${grossMargin.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: grossMargin >= 0 ? const Color(0xFF22C55E) : const Color(0xFFBA1A1A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Card 2 & 3 vertical stack
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Inbound Average
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RATA-RATA INBOUND',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF565E74),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avgInbound.toStringAsFixed(0)} item/hari',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0B1C30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.south_east,
                              color: Color(0xFF22C55E),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Outbound Average
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RATA-RATA OUTBOUND',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF565E74),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avgOutbound.toStringAsFixed(0)} item/hari',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0B1C30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.north_east,
                              color: Color(0xFF565E74),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Line Chart: Stock Movement Trends
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tren Pergerakan Stok',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(color: const Color(0xFF22C55E), label: 'Inbound'),
                          const SizedBox(width: 8),
                          _buildLegendDot(color: const Color(0xFF0B1C30), label: 'Outbound'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      _buildLineChartData(useMockup, filteredInbounds, filteredOutbounds),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bar Chart: Transaction Values
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Nilai Transaksi (Juta Rp)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      _buildBarChartData(useMockup, filteredInbounds, filteredOutbounds),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendSquare(color: const Color(0xFF22C55E), label: 'Biaya Inbound'),
                      const SizedBox(width: 16),
                      _buildLegendSquare(color: const Color(0xFFBCCBB9), label: 'Nilai Outbound'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Employees Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Performa Karyawan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                  ),
                  const SizedBox(height: 16),
                  if (employeeStats.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tidak ada aktivitas pencatatan karyawan',
                          style: TextStyle(color: Color(0xFF565E74), fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...employeeStats.take(3).map((item) => _buildEmployeeRow(item)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Products Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Produk Terpopuler (Keluar)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                  ),
                  const SizedBox(height: 16),
                  if (popularProducts.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tidak ada barang keluar',
                          style: TextStyle(color: Color(0xFF565E74), fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...popularProducts.take(3).map((item) => _buildProductRow(item)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isActive,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF22C55E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? Colors.white : const Color(0xFF565E74),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF565E74),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF565E74), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendSquare({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF565E74), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmployeeRow(EmployeeStatsItem item) {
    final clean = item.name.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final parts = clean.split(RegExp(r'\s+'));
    final initials = parts.isEmpty
        ? '?'
        : parts.length == 1
            ? parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase()
            : (parts[0][0] + parts[1][0]).toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF4FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006E2F),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                    ),
                    const Text(
                      'Staf Gudang',
                      style: TextStyle(fontSize: 11, color: Color(0xFF565E74)),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.count} Aktivitas',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF006E2F)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: const Color(0xFFEFF4FF),
              color: const Color(0xFF22C55E),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(PopularProductItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF565E74), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${item.sku}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF565E74), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0B1C30)),
              ),
              const Text(
                'unit',
                style: TextStyle(fontSize: 10, color: Color(0xFF565E74)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(
    bool useMockup,
    List<InboundRecord> inbounds,
    List<OutboundRecord> outbounds,
  ) {
    List<FlSpot> inboundSpots = [];
    List<FlSpot> outboundSpots = [];

    if (useMockup) {
      inboundSpots = const [
        FlSpot(0, 80),
        FlSpot(1, 60),
        FlSpot(2, 90),
        FlSpot(3, 50),
        FlSpot(4, 10),
        FlSpot(5, 70),
        FlSpot(6, 30),
      ];
      outboundSpots = const [
        FlSpot(0, 100),
        FlSpot(1, 110),
        FlSpot(2, 70),
        FlSpot(3, 90),
        FlSpot(4, 110),
        FlSpot(5, 50),
        FlSpot(6, 80),
      ];
    } else {
      // Group by weekday (1 = Monday, 7 = Sunday)
      final Map<int, double> inQty = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
      final Map<int, double> outQty = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

      for (final r in inbounds) {
        inQty[r.date.weekday] = (inQty[r.date.weekday] ?? 0.0) + r.quantity;
      }
      for (final r in outbounds) {
        if (r.status != OutboundStatus.dibatalkan) {
          outQty[r.date.weekday] = (outQty[r.date.weekday] ?? 0.0) + r.quantity;
        }
      }

      for (int i = 1; i <= 7; i++) {
        inboundSpots.add(FlSpot((i - 1).toDouble(), inQty[i]!));
        outboundSpots.add(FlSpot((i - 1).toDouble(), outQty[i]!));
      }
    }

    return LineChartData(
      gridData: const FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 30,
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
              if (val >= 0 && val < days.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[val.toInt()],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF565E74), fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: inboundSpots,
          isCurved: true,
          color: const Color(0xFF22C55E),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF22C55E),
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: outboundSpots,
          isCurved: true,
          color: const Color(0xFF0B1C30),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: const Color(0xFF0B1C30),
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(
    bool useMockup,
    List<InboundRecord> inbounds,
    List<OutboundRecord> outbounds,
  ) {
    List<BarChartGroupData> barGroups = [];

    if (useMockup) {
      final mockData = [
        {'day': 0, 'in': 12.0, 'out': 8.0},
        {'day': 1, 'in': 15.0, 'out': 10.0},
        {'day': 2, 'in': 8.0, 'out': 12.0},
        {'day': 3, 'in': 18.0, 'out': 9.0},
        {'day': 4, 'in': 20.0, 'out': 15.0},
      ];

      barGroups = mockData.map((data) {
        return BarChartGroupData(
          x: (data['day'] as num).toInt(),
          barRods: [
            BarChartRodData(
              toY: (data['in'] as num).toDouble(),
              color: const Color(0xFF22C55E),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: (data['out'] as num).toDouble(),
              color: const Color(0xFFBCCBB9),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
        );
      }).toList();
    } else {
      // Group by weekday (1=Sen, 5=Jum) in Millions
      final Map<int, double> inVal = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final Map<int, double> outVal = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

      for (final r in inbounds) {
        if (r.date.weekday <= 5) {
          inVal[r.date.weekday] = (inVal[r.date.weekday] ?? 0.0) + (r.totalCost / 1000000);
        }
      }
      for (final r in outbounds) {
        if (r.status != OutboundStatus.dibatalkan && r.date.weekday <= 5) {
          outVal[r.date.weekday] = (outVal[r.date.weekday] ?? 0.0) + (r.totalValue / 1000000);
        }
      }

      for (int i = 1; i <= 5; i++) {
        barGroups.add(
          BarChartGroupData(
            x: i - 1,
            barRods: [
              BarChartRodData(
                toY: inVal[i]!,
                color: const Color(0xFF22C55E),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
              BarChartRodData(
                toY: outVal[i]!,
                color: const Color(0xFFBCCBB9),
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
              ),
            ],
          ),
        );
      }
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];
              if (val >= 0 && val < days.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[val.toInt()],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF565E74), fontWeight: FontWeight.bold),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }
}

class EmployeeStatsItem {
  final String name;
  final int count;
  final double progress;

  EmployeeStatsItem({required this.name, required this.count, required this.progress});
}

class PopularProductItem {
  final String name;
  final String sku;
  final double quantity;

  PopularProductItem({required this.name, required this.sku, required this.quantity});
}
