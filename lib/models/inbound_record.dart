import 'package:hive/hive.dart';

part 'inbound_record.g.dart';

@HiveType(typeId: 1)
class InboundRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productId;

  @HiveField(2)
  final String productName;

  @HiveField(3)
  final String productSku;

  @HiveField(4)
  double quantity;

  @HiveField(5)
  double pricePerUnit;

  @HiveField(6)
  double totalCost;

  @HiveField(7)
  DateTime date;

  @HiveField(8)
  String? notes;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  String? itemType;

  InboundRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalCost,
    required this.date,
    this.notes,
    required this.createdAt,
    this.itemType = 'raw_material',
  });
}
