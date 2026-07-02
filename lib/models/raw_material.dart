import 'package:hive/hive.dart';

part 'raw_material.g.dart';

@HiveType(typeId: 8)
class RawMaterial extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String sku;

  @HiveField(3)
  String unit;

  @HiveField(4)
  double currentStock;

  @HiveField(5)
  double defaultUnitCost;

  @HiveField(6)
  bool isDeleted;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  RawMaterial({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    required this.defaultUnitCost,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  RawMaterial copyWith({
    String? name,
    String? sku,
    String? unit,
    double? currentStock,
    double? defaultUnitCost,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return RawMaterial(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      defaultUnitCost: defaultUnitCost ?? this.defaultUnitCost,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
