import 'package:hive/hive.dart';

part 'job_type.g.dart';

@HiveType(typeId: 5)
class JobType extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double ratePerUnit;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  JobType({
    required this.id,
    required this.name,
    required this.ratePerUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  JobType copyWith({
    String? name,
    double? ratePerUnit,
    DateTime? updatedAt,
  }) {
    return JobType(
      id: id,
      name: name ?? this.name,
      ratePerUnit: ratePerUnit ?? this.ratePerUnit,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
