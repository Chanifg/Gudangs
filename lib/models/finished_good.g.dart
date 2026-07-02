// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finished_good.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinishedGoodAdapter extends TypeAdapter<FinishedGood> {
  @override
  final int typeId = 9;

  @override
  FinishedGood read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinishedGood(
      id: fields[0] as String,
      name: fields[1] as String,
      sku: fields[2] as String,
      unit: fields[3] as String,
      currentStock: fields[4] as double,
      defaultUnitPrice: fields[5] as double,
      lastHPP: fields[6] as double?,
      isDeleted: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FinishedGood obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.currentStock)
      ..writeByte(5)
      ..write(obj.defaultUnitPrice)
      ..writeByte(6)
      ..write(obj.lastHPP)
      ..writeByte(7)
      ..write(obj.isDeleted)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinishedGoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
