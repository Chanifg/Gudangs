// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 6;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      pinHash: fields[0] as String?,
      isBiometricEnabled: fields[1] as bool,
      appVersion: fields[2] as String,
      profileName: fields[3] as String?,
      profilePhone: fields[4] as String?,
      profileCompanyName: fields[5] as String?,
      profileImagePath: fields[6] as String?,
      themeMode: fields[7] as String?,
      isPinSkipped: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.pinHash)
      ..writeByte(1)
      ..write(obj.isBiometricEnabled)
      ..writeByte(2)
      ..write(obj.appVersion)
      ..writeByte(3)
      ..write(obj.profileName)
      ..writeByte(4)
      ..write(obj.profilePhone)
      ..writeByte(5)
      ..write(obj.profileCompanyName)
      ..writeByte(6)
      ..write(obj.profileImagePath)
      ..writeByte(7)
      ..write(obj.themeMode)
      ..writeByte(8)
      ..write(obj.isPinSkipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
