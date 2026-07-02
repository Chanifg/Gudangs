import 'package:hive/hive.dart';

part 'employee.g.dart';

@HiveType(typeId: 3)
class Employee extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String fullName;

  @HiveField(2)
  String phoneNumber;

  @HiveField(3)
  String position;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  bool? isDeleted;

  Employee({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.position,
    this.isActive = true,
    bool? isDeleted,
    required this.createdAt,
    required this.updatedAt,
  }) : isDeleted = isDeleted ?? false;

  Employee copyWith({
    String? fullName,
    String? phoneNumber,
    String? position,
    bool? isActive,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Employee(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
