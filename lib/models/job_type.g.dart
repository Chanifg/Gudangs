// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JobTypeAdapter extends TypeAdapter<JobType> {
  @override
  final int typeId = 5;

  @override
  JobType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JobType(
      id: fields[0] as String,
      name: fields[1] as String,
      ratePerUnit: fields[2] as double,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      isDeleted: fields[5] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, JobType obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ratePerUnit)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
