import 'package:hive/hive.dart';

part 'finished_good.g.dart';

@HiveType(typeId: 9)
class FinishedGood extends HiveObject {
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
  double defaultUnitPrice;

  @HiveField(6)
  double? lastHPP;

  @HiveField(7)
  bool isDeleted;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  FinishedGood({
    required this.id,
    required this.name,
    required this.sku,
    required this.unit,
    required this.currentStock,
    required this.defaultUnitPrice,
    this.lastHPP,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  FinishedGood copyWith({
    String? name,
    String? sku,
    String? unit,
    double? currentStock,
    double? defaultUnitPrice,
    double? lastHPP,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return FinishedGood(
      id: id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      defaultUnitPrice: defaultUnitPrice ?? this.defaultUnitPrice,
      lastHPP: lastHPP ?? this.lastHPP,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
