import 'package:hive/hive.dart';

part 'audit_log.g.dart';

@HiveType(typeId: 15)
class AuditLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String operatorName;

  @HiveField(2)
  final String action; // e.g. 'TAMBAH_KARYAWAN', 'EDIT_BAHAN_BAKU', 'KOREKSI_STOK', etc.

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime timestamp;

  AuditLog({
    required this.id,
    required this.operatorName,
    required this.action,
    required this.description,
    required this.timestamp,
  });
}
