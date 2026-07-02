// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_of_materials.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BOMComponentAdapter extends TypeAdapter<BOMComponent> {
  @override
  final int typeId = 11;

  @override
  BOMComponent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BOMComponent(
      rawMaterialId: fields[0] as String,
      rawMaterialName: fields[1] as String,
      rawMaterialUnit: fields[2] as String,
      quantityPerUnit: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BOMComponent obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.rawMaterialId)
      ..writeByte(1)
      ..write(obj.rawMaterialName)
      ..writeByte(2)
      ..write(obj.rawMaterialUnit)
      ..writeByte(3)
      ..write(obj.quantityPerUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BOMComponentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BillOfMaterialsAdapter extends TypeAdapter<BillOfMaterials> {
  @override
  final int typeId = 10;

  @override
  BillOfMaterials read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillOfMaterials(
      id: fields[0] as String,
      name: fields[1] as String,
      finishedGoodId: fields[2] as String,
      finishedGoodName: fields[3] as String,
      components: (fields[4] as List).cast<BOMComponent>(),
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BillOfMaterials obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.finishedGoodId)
      ..writeByte(3)
      ..write(obj.finishedGoodName)
      ..writeByte(4)
      ..write(obj.components)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillOfMaterialsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
