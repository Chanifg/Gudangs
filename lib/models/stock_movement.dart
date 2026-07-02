import 'package:hive/hive.dart';

part 'stock_movement.g.dart';

@HiveType(typeId: 14)
class StockMovement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String itemId;

  @HiveField(2)
  final String itemName;

  @HiveField(3)
  final String itemType; // 'product' or 'raw_material'

  @HiveField(4)
  final String type; // 'inbound', 'outbound', 'production_in', 'production_out', 'adjustment_add', 'adjustment_sub', 'opname'

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final double previousStock;

  @HiveField(7)
  final double newStock;

  @HiveField(8)
  final double unitCost;

  @HiveField(9)
  final String operatorName;

  @HiveField(10)
  final DateTime date;

  @HiveField(11)
  final String? notes;

  StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.unitCost,
    required this.operatorName,
    required this.date,
    this.notes,
  });
}
