import 'package:bcrypt/bcrypt.dart';
import 'package:local_auth/local_auth.dart';
import 'database_service.dart';
import '../models/app_settings.dart';

class AuthService {
  static final _localAuth = LocalAuthentication();

  // Check if biometric authentication is available on the device
  static Future<bool> isBiometricsAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  // Perform biometric authentication
  static Future<bool> authenticateBiometric() async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) return false;

      final isEnabled = DatabaseService.settingsBox.get('settings')?.isBiometricEnabled ?? true;
      if (!isEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Pindai sidik jari atau wajah untuk masuk ke Gudangs',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // Register a new PIN
  static Future<void> registerPin(String pin) async {
    final salt = BCrypt.gensalt(logRounds: 10);
    final hash = BCrypt.hashpw(pin, salt);
    
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    settings.pinHash = hash;
    await DatabaseService.settingsBox.put('settings', settings);
  }

  // Verify PIN
  static bool verifyPin(String pin) {
    final settings = DatabaseService.settingsBox.get('settings');
    final hash = settings?.pinHash;
    if (hash == null) return false;
    
    try {
      return BCrypt.checkpw(pin, hash);
    } catch (_) {
      return false;
    }
  }

  // Check if PIN has been setup
  static bool hasPinSetup() {
    final settings = DatabaseService.settingsBox.get('settings');
    return settings?.pinHash != null;
  }
}
