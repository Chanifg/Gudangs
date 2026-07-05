import 'package:hive/hive.dart';

part 'bill_of_materials.g.dart';

@HiveType(typeId: 11)
class BOMComponent extends HiveObject {
  @HiveField(0)
  String rawMaterialId;

  @HiveField(1)
  String rawMaterialName;

  @HiveField(2)
  String rawMaterialUnit;

  @HiveField(3)
  double quantityPerUnit;

  BOMComponent({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.rawMaterialUnit,
    required this.quantityPerUnit,
  });
}

@HiveType(typeId: 10)
class BillOfMaterials extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String finishedGoodId;

  @HiveField(3)
  String finishedGoodName;

  @HiveField(4)
  List<BOMComponent> components;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  double laborCost;

  BillOfMaterials({
    required this.id,
    required this.name,
    required this.finishedGoodId,
    required this.finishedGoodName,
    required this.components,
    required this.createdAt,
    required this.updatedAt,
    this.laborCost = 0.0,
  });
}
