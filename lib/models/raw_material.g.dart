// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'raw_material.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RawMaterialAdapter extends TypeAdapter<RawMaterial> {
  @override
  final int typeId = 8;

  @override
  RawMaterial read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RawMaterial(
      id: fields[0] as String,
      name: fields[1] as String,
      sku: fields[2] as String,
      unit: fields[3] as String,
      currentStock: fields[4] as double,
      defaultUnitCost: fields[5] as double,
      isDeleted: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RawMaterial obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.defaultUnitCost)
      ..writeByte(6)
      ..write(obj.isDeleted)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawMaterialAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
