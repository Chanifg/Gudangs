import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 6)
class AppSettings extends HiveObject {
  @HiveField(0)
  String? pinHash;

  @HiveField(1)
  bool isBiometricEnabled;

  @HiveField(2)
  String appVersion;

  @HiveField(3)
  String? profileName;

  @HiveField(4)
  String? profilePhone;

  @HiveField(5)
  String? profileCompanyName;

  @HiveField(6)
  String? profileImagePath;

  @HiveField(7)
  String? themeMode;

  @HiveField(8)
  bool? isPinSkipped;

  AppSettings({
    this.pinHash,
    this.isBiometricEnabled = true,
    this.appVersion = "1.0.0",
    this.profileName = "Admin Gudang Utama",
    this.profilePhone = "",
    this.profileCompanyName = "Gudang Utama",
    this.profileImagePath,
    this.themeMode = "system",
    this.isPinSkipped = false,
  });
}
