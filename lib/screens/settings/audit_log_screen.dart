import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/audit_log_provider.dart';
import '../../core/formatters.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getActionColor(String action, ColorScheme colorScheme) {
    if (action.contains('TAMBAH')) {
      return Colors.green;
    } else if (action.contains('HAPUS')) {
      return Colors.red;
    } else if (action.contains('EDIT') || action.contains('KOREKSI') || action.contains('UBAH')) {
      return Colors.orange;
    } else if (action.contains('PRODUKSI')) {
      return colorScheme.primary;
    }
    return colorScheme.secondary;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('TAMBAH')) {
      return Icons.add_circle_outline;
    } else if (action.contains('HAPUS')) {
      return Icons.delete_sweep_outlined;
    } else if (action.contains('EDIT') || action.contains('UBAH')) {
      return Icons.edit_note_outlined;
    } else if (action.contains('KOREKSI')) {
      return Icons.scale_outlined;
    } else if (action.contains('PRODUKSI')) {
      return Icons.precision_manufacturing_outlined;
    } else if (action.contains('LOGIN') || action.contains('PIN')) {
      return Icons.lock_open_outlined;
    }
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditLogProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Filter logs based on search keyword
    final logs = state.logs.where((log) {
      final query = _searchKeyword.toLowerCase();
      return log.action.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query) ||
          log.operatorName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas Sistem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Log',
            onPressed: () {
              ref.read(auditLogProvider.notifier).loadLogs();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari aksi, deskripsi, atau operator...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchKeyword = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value.trim();
                });
              },
            ),
          ),

          // List of Logs
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              _searchKeyword.isEmpty
                                  ? 'Belum ada log aktivitas yang tercatat.'
                                  : 'Tidak ditemukan log yang cocok.',
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: logs.length,
                        separatorBuilder: (context, index) => Divider(height: 1, color: colorScheme.outlineVariant),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final actionColor = _getActionColor(log.action, colorScheme);
                          final actionIcon = _getActionIcon(log.action);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Icon Indicator
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: actionColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    actionIcon,
                                    color: actionColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Details content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Action Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: actionColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              log.action,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: actionColor,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                          // Operator name tag
                                          Row(
                                            children: [
                                              Icon(Icons.person_outline, size: 12, color: colorScheme.onSurfaceVariant),
                                              const SizedBox(width: 2),
                                              Text(
                                                log.operatorName,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        log.description,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Formatters.formatDateTime(log.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
