// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityRecordAdapter extends TypeAdapter<ActivityRecord> {
  @override
  final int typeId = 4;

  @override
  ActivityRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityRecord(
      id: fields[0] as String,
      employeeId: fields[1] as String,
      employeeName: fields[2] as String,
      jobTypeId: fields[3] as String,
      jobTypeName: fields[4] as String,
      units: fields[5] as double,
      ratePerUnit: fields[6] as double,
      estimatedWage: fields[7] as double,
      date: fields[8] as DateTime,
      notes: fields[9] as String?,
      createdAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityRecord obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.employeeId)
      ..writeByte(2)
      ..write(obj.employeeName)
      ..writeByte(3)
      ..write(obj.jobTypeId)
      ..writeByte(4)
      ..write(obj.jobTypeName)
      ..writeByte(5)
      ..write(obj.units)
      ..writeByte(6)
      ..write(obj.ratePerUnit)
      ..writeByte(7)
      ..write(obj.estimatedWage)
      ..writeByte(8)
      ..write(obj.date)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
