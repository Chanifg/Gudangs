import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/inbound_provider.dart';
import '../../providers/outbound_provider.dart';
import '../../providers/activity_provider.dart';
import '../../core/formatters.dart';
import '../../models/outbound_record.dart';

class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboundState = ref.watch(inboundProvider);
    final outboundState = ref.watch(outboundProvider);
    final activityState = ref.watch(activityProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: CircleAvatar(
              backgroundColor: colorScheme.surfaceVariant,
              child: const Icon(Icons.person, color: Color(0xFF006E2F)),
            ),
          ),
          title: const Text('Histori Catatan'),
          bottom: TabBar(
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.secondary,
            indicatorColor: colorScheme.primary,
            tabs: const [
              Tab(text: 'Transaksi Gudang'),
              Tab(text: 'Aktivitas Karyawan'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
              color: colorScheme.primary,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Transaksi Gudang (Inbound & Outbound)
            _buildWarehouseTransactionsTab(context, inboundState, outboundState, ref),
            
            // Tab 2: Aktivitas Harian Karyawan
            _buildEmployeeActivitiesTab(context, activityState, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseTransactionsTab(
    BuildContext context,
    InboundState inboundState,
    OutboundState outboundState,
    WidgetRef ref,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    // Combine inbound and outbound records
    final List<Map<String, dynamic>> combinedList = [];

    for (final rec in inboundState.records) {
      combinedList.add({
        'type': 'inbound',
        'record': rec,
        'date': rec.date,
      });
    }

    for (final rec in outboundState.records) {
      combinedList.add({
        'type': 'outbound',
        'record': rec,
        'date': rec.date,
      });
    }

    // Sort by date descending
    combinedList.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return Column(
      children: [
        // Action Shortcut bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/transactions/inbound/add'),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Catat Masuk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/transactions/outbound/add'),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Catat Keluar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: combinedList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Belum ada transaksi tercatat.', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(inboundProvider.notifier).loadInboundRecords();
                    ref.read(outboundProvider.notifier).loadOutboundRecords();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: combinedList.length,
                    itemBuilder: (context, index) {
                      final item = combinedList[index];
                      final isInbound = item['type'] == 'inbound';
                      
                      if (isInbound) {
                        final rec = item['record'];
                        return _buildInboundTile(context, rec);
                      } else {
                        final rec = item['record'];
                        return _buildOutboundTile(context, rec, ref);
                      }
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInboundTile(BuildContext context, dynamic rec) {
    final colorScheme = Theme.of(context).colorScheme;
    final qtyStr = rec.quantity.toStringAsFixed(rec.quantity % 1 == 0 ? 0 : 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primaryContainer.withOpacity(0.15),
              child: Icon(Icons.arrow_downward, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penerimaan ${rec.productName}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.formatDate(rec.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+$qtyStr unit',
                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatRupiah(rec.totalCost),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutboundTile(BuildContext context, dynamic rec, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final qtyStr = rec.quantity.toStringAsFixed(rec.quantity % 1 == 0 ? 0 : 1);
    final isCancelled = rec.status == OutboundStatus.dibatalkan;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isCancelled
                      ? Colors.grey[200]
                      : colorScheme.error.withOpacity(0.15),
                  child: Icon(
                    Icons.arrow_upward,
                    color: isCancelled ? Colors.grey[600] : colorScheme.error,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kirim ke ${rec.destination}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCancelled ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${rec.productName} • ${Formatters.formatDate(rec.date)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-$qtyStr unit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? Colors.grey : colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatRupiah(rec.totalValue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isCancelled ? Colors.grey : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Render status badge click dropdown to quickly toggle status
                PopupMenuButton<OutboundStatus>(
                  initialValue: rec.status,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.grey[200]
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isCancelled ? Colors.grey[300]! : colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Status: ${_getStatusText(rec.status)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCancelled ? Colors.grey[600] : colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 14),
                      ],
                    ),
                  ),
                  onSelected: (OutboundStatus newStatus) {
                    ref.read(outboundProvider.notifier).updateStatus(rec.id, newStatus);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: OutboundStatus.pending, child: Text('Pending (Menunggu)')),
                    const PopupMenuItem(value: OutboundStatus.terkirim, child: Text('Terkirim')),
                    const PopupMenuItem(value: OutboundStatus.dibatalkan, child: Text('Dibatalkan')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(OutboundStatus status) {
    switch (status) {
      case OutboundStatus.pending:
        return 'Pending';
      case OutboundStatus.terkirim:
        return 'Terkirim';
      case OutboundStatus.dibatalkan:
        return 'Dibatalkan';
    }
  }

  Widget _buildEmployeeActivitiesTab(BuildContext context, ActivityState activityState, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Action Shortcut bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => context.push('/transactions/activity/add'),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Catat Kerja Karyawan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ),

        // List View
        Expanded(
          child: activityState.records.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('Belum ada catatan aktivitas karyawan.', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(activityProvider.notifier).loadActivityRecords();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: activityState.records.length,
                    itemBuilder: (context, index) {
                      final act = activityState.records[index];
                      final unitStr = act.units.toStringAsFixed(act.units % 1 == 0 ? 0 : 1);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.surfaceVariant,
                            child: const Icon(Icons.badge_outlined, color: Color(0xFF006E2F)),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(act.employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                Formatters.formatRupiah(act.estimatedWage),
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${act.jobTypeName} • $unitStr unit'),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    Formatters.formatDate(act.date),
                                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                  // Edit / Delete Action buttons
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          context.push('/transactions/activity/${act.id}/edit');
                                        },
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          ref.read(activityProvider.notifier).deleteActivity(act.id);
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
