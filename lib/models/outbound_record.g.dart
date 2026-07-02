// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbound_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutboundRecordAdapter extends TypeAdapter<OutboundRecord> {
  @override
  final int typeId = 2;

  @override
  OutboundRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutboundRecord(
      id: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      productSku: fields[3] as String,
      quantity: fields[4] as double,
      sellingPricePerUnit: fields[5] as double,
      totalValue: fields[6] as double,
      destination: fields[7] as String,
      status: fields[8] as OutboundStatus,
      date: fields[9] as DateTime,
      notes: fields[10] as String?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, OutboundRecord obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.productSku)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.sellingPricePerUnit)
      ..writeByte(6)
      ..write(obj.totalValue)
      ..writeByte(7)
      ..write(obj.destination)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.notes)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboundRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OutboundStatusAdapter extends TypeAdapter<OutboundStatus> {
  @override
  final int typeId = 7;

  @override
  OutboundStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OutboundStatus.pending;
      case 1:
        return OutboundStatus.terkirim;
      case 2:
        return OutboundStatus.dibatalkan;
      default:
        return OutboundStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OutboundStatus obj) {
    switch (obj) {
      case OutboundStatus.pending:
        writer.writeByte(0);
        break;
      case OutboundStatus.terkirim:
        writer.writeByte(1);
        break;
      case OutboundStatus.dibatalkan:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboundStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
