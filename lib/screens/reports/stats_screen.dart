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
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return DateTimeRange(
        start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
        end: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
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



    // 2. Calculations
    double grossMargin = 0.0;
    double avgInbound = 0.0;
    double avgOutbound = 0.0;
    double totalInboundCost = 0.0;
    double totalOutboundValue = 0.0;

    List<EmployeeStatsItem> employeeStats = [];
    List<PopularProductItem> popularProducts = [];

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

    final dateRangeStr = '${Formatters.formatDate(range.start)} - ${Formatters.formatDate(range.end)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Operasional'),
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
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),



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
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
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
                            Text(
                              'MARGIN KOTOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.trending_up,
                                color: colorScheme.primary,
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
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  grossMargin >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: grossMargin >= 0 ? Colors.green : Colors.red,
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${grossMargin >= 0 ? "+" : ""}${grossMargin.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: grossMargin >= 0 ? Colors.green : Colors.red,
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
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RATA-RATA INBOUND',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avgInbound.toStringAsFixed(0)} item/hari',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.south_east,
                              color: colorScheme.primary,
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
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RATA-RATA OUTBOUND',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${avgOutbound.toStringAsFixed(0)} item/hari',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.north_east,
                              color: colorScheme.onSurfaceVariant,
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tren Pergerakan Stok',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                      Row(
                        children: [
                          _buildLegendDot(color: colorScheme.primary, label: 'Inbound'),
                          const SizedBox(width: 8),
                          _buildLegendDot(color: colorScheme.onSurface, label: 'Outbound'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      _buildLineChartData(filteredInbounds, filteredOutbounds, range, colorScheme),
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Nilai Transaksi (Juta Rp)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 160,
                    child: BarChart(
                      _buildBarChartData(filteredInbounds, filteredOutbounds, range, colorScheme),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendSquare(color: colorScheme.primary, label: 'Biaya Inbound'),
                      const SizedBox(width: 16),
                      _buildLegendSquare(color: colorScheme.primary.withValues(alpha: 0.3), label: 'Nilai Outbound'),
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
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Performa Karyawan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  if (employeeStats.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tidak ada aktivitas pencatatan karyawan',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...employeeStats.take(3).map((item) => _buildEmployeeRow(item, colorScheme)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Products Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Produk Terpopuler (Keluar)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  if (popularProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Tidak ada barang keluar',
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ...popularProducts.take(3).map((item) => _buildProductRow(item, colorScheme)),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primary : colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
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
                  color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot({required Color color, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLegendSquare({required Color color, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
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
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildEmployeeRow(EmployeeStatsItem item, ColorScheme colorScheme) {
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
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    Text(
                      'Staf Gudang',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.count} Aktivitas',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: item.progress,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
              color: colorScheme.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(PopularProductItem item, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.inventory_2_outlined, color: colorScheme.onSurfaceVariant, size: 18),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  'SKU: ${item.sku}',
                  style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontFamily: 'monospace'),
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
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
              ),
              Text(
                'unit',
                style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData(
    List<InboundRecord> inbounds,
    List<OutboundRecord> outbounds,
    DateTimeRange range,
    ColorScheme colorScheme,
  ) {
    List<FlSpot> inboundSpots = [];
    List<FlSpot> outboundSpots = [];

    final int daysCount = range.end.difference(range.start).inDays + 1;
    List<DateTime> dateList = [];
    for (int i = 0; i < daysCount; i++) {
      dateList.add(range.start.add(Duration(days: i)));
    }

    final Map<String, double> inQty = {};
    final Map<String, double> outQty = {};

    String formatDateKey(DateTime date) {
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    for (final r in inbounds) {
      final key = formatDateKey(r.date);
      inQty[key] = (inQty[key] ?? 0.0) + r.quantity;
    }
    for (final r in outbounds) {
      if (r.status != OutboundStatus.dibatalkan) {
        final key = formatDateKey(r.date);
        outQty[key] = (outQty[key] ?? 0.0) + r.quantity;
      }
    }

    for (int i = 0; i < daysCount; i++) {
      final key = formatDateKey(dateList[i]);
      inboundSpots.add(FlSpot(i.toDouble(), inQty[key] ?? 0.0));
      outboundSpots.add(FlSpot(i.toDouble(), outQty[key] ?? 0.0));
    }

    double interval = 1.0;
    if (daysCount > 7 && daysCount <= 14) {
      interval = 2.0;
    } else if (daysCount > 14 && daysCount <= 31) {
      interval = 5.0;
    } else if (daysCount > 31) {
      interval = (daysCount / 6).floorToDouble();
      if (interval < 1.0) interval = 1.0;
    }

    return LineChartData(
      minX: -0.5,
      maxX: daysCount > 1 ? (daysCount - 1).toDouble() + 0.5 : 1.5,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot touchedSpot) => const Color(0xFF1E293B),
          tooltipBorder: BorderSide(color: colorScheme.primary, width: 1.5),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((LineBarSpot touchedSpot) {
              final idx = touchedSpot.x.toInt();
              String dateStr = '';
              if (idx >= 0 && idx < dateList.length) {
                final d = dateList[idx];
                dateStr = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} - ";
              }
              return LineTooltipItem(
                '$dateStr${touchedSpot.y.toStringAsFixed(0)} item',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
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
            interval: interval,
            getTitlesWidget: (val, meta) {
              final index = val.toInt();
              if (index >= 0 && index < daysCount) {
                final date = dateList[index];
                String label = '';
                if (_selectedFilter == 'week') {
                  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                  label = days[(date.weekday - 1) % 7];
                } else {
                  label = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
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
          color: colorScheme.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: colorScheme.primary,
              strokeWidth: 1,
              strokeColor: colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
        LineChartBarData(
          spots: outboundSpots,
          isCurved: true,
          color: colorScheme.onSurface,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: colorScheme.onSurface,
              strokeWidth: 1,
              strokeColor: colorScheme.surface,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      ],
    );
  }
  BarChartData _buildBarChartData(
    List<InboundRecord> inbounds,
    List<OutboundRecord> outbounds,
    DateTimeRange range,
    ColorScheme colorScheme,
  ) {
    List<BarChartGroupData> barGroups = [];

    final int daysCount = range.end.difference(range.start).inDays + 1;
    List<DateTime> dateList = [];
    for (int i = 0; i < daysCount; i++) {
      dateList.add(range.start.add(Duration(days: i)));
    }

    final Map<String, double> inVal = {};
    final Map<String, double> outVal = {};

    String formatDateKey(DateTime date) {
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }

    for (final r in inbounds) {
      final key = formatDateKey(r.date);
      inVal[key] = (inVal[key] ?? 0.0) + (r.totalCost / 1000000);
    }
    for (final r in outbounds) {
      if (r.status != OutboundStatus.dibatalkan) {
        final key = formatDateKey(r.date);
        outVal[key] = (outVal[key] ?? 0.0) + (r.totalValue / 1000000);
      }
    }

    for (int i = 0; i < daysCount; i++) {
      final key = formatDateKey(dateList[i]);
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: inVal[key] ?? 0.0,
              color: colorScheme.primary,
              width: daysCount > 15 ? 4 : 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
            BarChartRodData(
              toY: outVal[key] ?? 0.0,
              color: colorScheme.primary.withValues(alpha: 0.3),
              width: daysCount > 15 ? 4 : 10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ],
        ),
      );
    }

    double interval = 1.0;
    if (daysCount > 7 && daysCount <= 14) {
      interval = 2.0;
    } else if (daysCount > 14 && daysCount <= 31) {
      interval = 5.0;
    } else if (daysCount > 31) {
      interval = (daysCount / 6).floorToDouble();
      if (interval < 1.0) interval = 1.0;
    }

    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (BarChartGroupData group) => const Color(0xFF1E293B),
          tooltipBorder: BorderSide(color: colorScheme.primary, width: 1.5),
          getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
            final String prefix = rodIndex == 0 ? 'Biaya Inbound' : 'Nilai Outbound';
            final idx = group.x.toInt();
            String dateStr = '';
            if (idx >= 0 && idx < dateList.length) {
              final d = dateList[idx];
              dateStr = "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}\n";
            }
            return BarTooltipItem(
              '$dateStr$prefix\nRp ${rod.toY.toStringAsFixed(2)} Jt',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            );
          },
        ),
      ),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: interval,
            getTitlesWidget: (val, meta) {
              final index = val.toInt();
              if (index % interval.toInt() != 0) {
                return const SizedBox();
              }
              if (index >= 0 && index < daysCount) {
                final date = dateList[index];
                String label = '';
                if (_selectedFilter == 'week') {
                  const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                  label = days[(date.weekday - 1) % 7];
                } else {
                  label = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}";
                }
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
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
