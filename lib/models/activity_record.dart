import 'package:hive/hive.dart';

part 'activity_record.g.dart';

@HiveType(typeId: 4)
class ActivityRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String employeeId;

  @HiveField(2)
  final String employeeName;

  @HiveField(3)
  final String jobTypeId;

  @HiveField(4)
  final String jobTypeName;

  @HiveField(5)
  double units;

  @HiveField(6)
  double ratePerUnit;

  @HiveField(7)
  double estimatedWage;

  @HiveField(8)
  DateTime date;

  @HiveField(9)
  String? notes;

  @HiveField(10)
  final DateTime createdAt;

  ActivityRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.jobTypeId,
    required this.jobTypeName,
    required this.units,
    required this.ratePerUnit,
    required this.estimatedWage,
    required this.date,
    this.notes,
    required this.createdAt,
  });
}
