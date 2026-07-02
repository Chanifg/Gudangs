import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../providers/raw_material_provider.dart';
import '../../providers/finished_good_provider.dart';
import '../../providers/inbound_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../providers/activity_provider.dart';
import '../../core/formatters.dart';
import '../../models/outbound_record.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawMaterialState = ref.watch(rawMaterialProvider);
    final finishedGoodState = ref.watch(finishedGoodProvider);
    final inboundState = ref.watch(inboundProvider);
    final outboundState = ref.watch(outboundProvider);
    final activityState = ref.watch(activityProvider);
    final settingsState = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 1. Calculate Bento Grid Summary
    final activeRawMaterials = rawMaterialState.rawMaterials;
    final activeFinishedGoods = finishedGoodState.finishedGoods;
    final totalSku = activeRawMaterials.length + activeFinishedGoods.length;
    final totalUnits = activeRawMaterials.fold(0.0, (sum, m) => sum + m.currentStock) +
                       activeFinishedGoods.fold(0.0, (sum, f) => sum + f.currentStock);

    // 2. Calculate Today's Inbound / Outbound Transactions
    final allInbounds = inboundState.records;
    final allOutbounds = outboundState.records;
    final inboundTodayCount = allInbounds.where((rec) => _isToday(rec.date)).length;
    final outboundTodayCount = allOutbounds.where((rec) => _isToday(rec.date) && rec.status != OutboundStatus.dibatalkan).length;

    // 3. Calculate Financial Summary (Current Month)
    final monthlyInboundCost = allInbounds.where((rec) => _isCurrentMonth(rec.date)).fold(0.0, (sum, rec) => sum + rec.totalCost);
    final monthlyOutboundValue = allOutbounds.where((rec) => _isCurrentMonth(rec.date) && rec.status != OutboundStatus.dibatalkan).fold(0.0, (sum, rec) => sum + rec.totalValue);
    final monthlyMargin = monthlyOutboundValue - monthlyInboundCost;

    // 4. Weekly Trend (Last 7 Days)
    final last7Days = List.generate(7, (index) {
      return DateTime.now().subtract(Duration(days: 6 - index));
    });

    final List<BarChartGroupData> barGroups = [];
    double maxVal = 10.0; // default max Y limit

    for (int i = 0; i < 7; i++) {
      final day = last7Days[i];
      final dayInbound = allInbounds
          .where((rec) => rec.date.year == day.year && rec.date.month == day.month && rec.date.day == day.day)
          .fold(0.0, (sum, rec) => sum + rec.quantity);
      final dayOutbound = allOutbounds
          .where((rec) => rec.date.year == day.year && rec.date.month == day.month && rec.date.day == day.day && rec.status != OutboundStatus.dibatalkan)
          .fold(0.0, (sum, rec) => sum + rec.quantity);

      final totalMovement = dayInbound + dayOutbound;
      if (totalMovement > maxVal) {
        maxVal = totalMovement;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: totalMovement,
              color: i == 6 ? colorScheme.primary : colorScheme.primaryContainer.withOpacity(0.3),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ProfileAvatar(
            imagePath: settingsState.profileImagePath,
            name: settingsState.profileName,
            radius: 20,
          ),
        ),
        title: Text('Halo, ${settingsState.profileName}'),
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(rawMaterialProvider.notifier).loadRawMaterials();
          ref.read(finishedGoodProvider.notifier).loadFinishedGoods();
          ref.read(inboundProvider.notifier).loadInboundRecords();
          ref.read(outboundProvider.notifier).loadOutboundRecords();
          ref.read(activityProvider.notifier).loadActivityRecords();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Ringkasan Stok (Bento Grid Style)
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL SKU',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  Icon(
                                    Icons.inventory_2,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalSku',
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Produk aktif',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'TOTAL UNIT',
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                  Icon(
                                    Icons.layers,
                                    color: colorScheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                NumberFormat.decimalPattern('id_ID').format(totalUnits),
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unit barang',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Aktivitas Hari Ini
                Text(
                  'Aktivitas Hari Ini',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_downward, color: colorScheme.primary),
                              ),
                              const SizedBox(height: 8),
                              Text('BARANG MASUK', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text('$inboundTodayCount', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 80, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_upward, color: colorScheme.error),
                              ),
                              const SizedBox(height: 8),
                              Text('BARANG KELUAR', style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 4),
                              Text('$outboundTodayCount', style: Theme.of(context).textTheme.headlineMedium),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Ringkasan Keuangan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Keuangan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Bulan Ini',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B1C30), Color(0xFF213145)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B1C30).withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Decorative blurred bubbles
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MARGIN KOTOR',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Formatters.formatRupiah(monthlyMargin),
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    color: monthlyMargin >= 0 ? const Color(0xFF4AE176) : colorScheme.error,
                                    fontSize: 28,
                                  ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12, height: 1),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_downward, color: colorScheme.primaryContainer, size: 14),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'INBOUND',
                                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.formatCompactRupiah(monthlyInboundCost),
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.arrow_upward, color: colorScheme.error, size: 14),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'OUTBOUND',
                                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.formatCompactRupiah(monthlyOutboundValue),
                                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                    ],
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
                const SizedBox(height: 20),

                // 4. Tren Mingguan Chart
                Text(
                  'Tren Mingguan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PERGERAKAN STOK (INBOUND + OUTBOUND)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 20),
                        
                        // FL Bar Chart
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: maxVal * 1.2,
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index >= 0 && index < 7) {
                                        final day = last7Days[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            DateFormat('E', 'id_ID').format(day),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: index == 6 ? FontWeight.bold : FontWeight.normal,
                                              color: index == 6 ? colorScheme.primary : colorScheme.secondary,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: barGroups,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
