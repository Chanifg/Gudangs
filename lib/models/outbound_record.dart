import 'package:hive/hive.dart';

part 'outbound_record.g.dart';

@HiveType(typeId: 7)
enum OutboundStatus {
  @HiveField(0)
  pending,

  @HiveField(1)
  terkirim,

  @HiveField(2)
  dibatalkan,
}

@HiveType(typeId: 2)
class OutboundRecord extends HiveObject {
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
  double sellingPricePerUnit;

  @HiveField(6)
  double totalValue;

  @HiveField(7)
  String destination;

  @HiveField(8)
  OutboundStatus status;

  @HiveField(9)
  DateTime date;

  @HiveField(10)
  String? notes;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  OutboundRecord({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.quantity,
    required this.sellingPricePerUnit,
    required this.totalValue,
    required this.destination,
    required this.status,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
