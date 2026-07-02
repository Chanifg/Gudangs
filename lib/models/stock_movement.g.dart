// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockMovementAdapter extends TypeAdapter<StockMovement> {
  @override
  final int typeId = 14;

  @override
  StockMovement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockMovement(
      id: fields[0] as String,
      itemId: fields[1] as String,
      itemName: fields[2] as String,
      itemType: fields[3] as String,
      type: fields[4] as String,
      quantity: fields[5] as double,
      previousStock: fields[6] as double,
      newStock: fields[7] as double,
      unitCost: fields[8] as double,
      operatorName: fields[9] as String,
      date: fields[10] as DateTime,
      notes: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StockMovement obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.itemId)
      ..writeByte(2)
      ..write(obj.itemName)
      ..writeByte(3)
      ..write(obj.itemType)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.previousStock)
      ..writeByte(7)
      ..write(obj.newStock)
      ..writeByte(8)
      ..write(obj.unitCost)
      ..writeByte(9)
      ..write(obj.operatorName)
      ..writeByte(10)
      ..write(obj.date)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
