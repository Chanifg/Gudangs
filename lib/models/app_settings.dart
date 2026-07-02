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

  AppSettings({
    this.pinHash,
    this.isBiometricEnabled = true,
    this.appVersion = "1.0.0",
  });
}
