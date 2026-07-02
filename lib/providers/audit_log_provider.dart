import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_log.dart';
import '../services/database_service.dart';

class AuditLogState {
  final List<AuditLog> logs;
  final bool isLoading;

  AuditLogState({
    required this.logs,
    this.isLoading = false,
  });

  AuditLogState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
  }) {
    return AuditLogState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuditLogNotifier extends StateNotifier<AuditLogState> {
  AuditLogNotifier() : super(AuditLogState(logs: [])) {
    loadLogs();
  }

  void loadLogs() {
    if (!DatabaseService.isOperationalOpen) return;
    state = state.copyWith(isLoading: true);
    final allLogs = DatabaseService.auditLogsBox.values.toList();
    // Sort chronologically descending (newest first)
    allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = AuditLogState(logs: allLogs, isLoading: false);
  }

  Future<void> logActivity({
    required String action,
    required String description,
  }) async {
    if (!DatabaseService.isOperationalOpen) return;
    final operatorName = DatabaseService.settingsBox.get('settings')?.profileName ?? 'Admin';
    final log = AuditLog(
      id: const Uuid().v4(),
      operatorName: operatorName,
      action: action,
      description: description,
      timestamp: DateTime.now(),
    );
    await DatabaseService.auditLogsBox.put(log.id, log);
    loadLogs();
  }
}

final auditLogProvider = StateNotifierProvider<AuditLogNotifier, AuditLogState>((ref) {
  return AuditLogNotifier();
});
