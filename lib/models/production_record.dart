import 'package:hive/hive.dart';

part 'production_record.g.dart';

@HiveType(typeId: 13)
class MaterialUsage extends HiveObject {
  @HiveField(0)
  String rawMaterialId;

  @HiveField(1)
  String rawMaterialName;

  @HiveField(2)
  String rawMaterialUnit;

  @HiveField(3)
  double quantityUsed;

  @HiveField(4)
  double unitCostAtTime;

  @HiveField(5)
  double totalCost;

  MaterialUsage({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.rawMaterialUnit,
    required this.quantityUsed,
    required this.unitCostAtTime,
    required this.totalCost,
  });
}

@HiveType(typeId: 12)
class ProductionRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String bomId;

  @HiveField(2)
  String bomName;

  @HiveField(3)
  String finishedGoodId;

  @HiveField(4)
  String finishedGoodName;

  @HiveField(5)
  double quantityProduced;

  @HiveField(6)
  List<MaterialUsage> materialsUsed;

  @HiveField(7)
  double totalMaterialCost;

  @HiveField(8)
  double hpp;

  @HiveField(9)
  DateTime date;

  @HiveField(10)
  String? note;

  @HiveField(11)
  final DateTime createdAt;

  ProductionRecord({
    required this.id,
    required this.bomId,
    required this.bomName,
    required this.finishedGoodId,
    required this.finishedGoodName,
    required this.quantityProduced,
    required this.materialsUsed,
    required this.totalMaterialCost,
    required this.hpp,
    required this.date,
    this.note,
    required this.createdAt,
  });
}
