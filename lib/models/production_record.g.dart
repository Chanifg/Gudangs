// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaterialUsageAdapter extends TypeAdapter<MaterialUsage> {
  @override
  final int typeId = 13;

  @override
  MaterialUsage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialUsage(
      rawMaterialId: fields[0] as String,
      rawMaterialName: fields[1] as String,
      rawMaterialUnit: fields[2] as String,
      quantityUsed: fields[3] as double,
      unitCostAtTime: fields[4] as double,
      totalCost: fields[5] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialUsage obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.rawMaterialId)
      ..writeByte(1)
      ..write(obj.rawMaterialName)
      ..writeByte(2)
      ..write(obj.rawMaterialUnit)
      ..writeByte(3)
      ..write(obj.quantityUsed)
      ..writeByte(4)
      ..write(obj.unitCostAtTime)
      ..writeByte(5)
      ..write(obj.totalCost);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialUsageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductionRecordAdapter extends TypeAdapter<ProductionRecord> {
  @override
  final int typeId = 12;

  @override
  ProductionRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductionRecord(
      id: fields[0] as String,
      bomId: fields[1] as String,
      bomName: fields[2] as String,
      finishedGoodId: fields[3] as String,
      finishedGoodName: fields[4] as String,
      quantityProduced: fields[5] as double,
      materialsUsed: (fields[6] as List).cast<MaterialUsage>(),
      totalMaterialCost: fields[7] as double,
      hpp: fields[8] as double,
      date: fields[9] as DateTime,
      note: fields[10] as String?,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProductionRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.bomId)
      ..writeByte(2)
      ..write(obj.bomName)
      ..writeByte(3)
      ..write(obj.finishedGoodId)
      ..writeByte(4)
      ..write(obj.finishedGoodName)
      ..writeByte(5)
      ..write(obj.quantityProduced)
      ..writeByte(6)
      ..write(obj.materialsUsed)
      ..writeByte(7)
      ..write(obj.totalMaterialCost)
      ..writeByte(8)
      ..write(obj.hpp)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.note)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductionRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
