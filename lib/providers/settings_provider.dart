import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/job_type.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'audit_log_provider.dart';
import 'auth_provider.dart';

class SettingsState {
  final List<JobType> jobTypes;
  final bool isBiometricEnabled;
  final String appVersion;
  final String profileName;
  final String profilePhone;
  final String profileCompanyName;
  final String? profileImagePath;
  final String? errorMessage;
  final bool isSuccess;

  SettingsState({
    required this.jobTypes,
    required this.isBiometricEnabled,
    required this.appVersion,
    required this.profileName,
    required this.profilePhone,
    required this.profileCompanyName,
    this.profileImagePath,
    this.errorMessage,
    this.isSuccess = false,
  });

  SettingsState copyWith({
    List<JobType>? jobTypes,
    bool? isBiometricEnabled,
    String? appVersion,
    String? profileName,
    String? profilePhone,
    String? profileCompanyName,
    String? profileImagePath,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SettingsState(
      jobTypes: jobTypes ?? this.jobTypes,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      appVersion: appVersion ?? this.appVersion,
      profileName: profileName ?? this.profileName,
      profilePhone: profilePhone ?? this.profilePhone,
      profileCompanyName: profileCompanyName ?? this.profileCompanyName,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref ref;

  SettingsNotifier(this.ref)
      : super(SettingsState(
          jobTypes: [],
          isBiometricEnabled: true,
          appVersion: '1.3.0',
          profileName: 'Admin Gudang Utama',
          profilePhone: '',
          profileCompanyName: 'Gudang Utama',
          profileImagePath: null,
        )) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _loadSettings();
      }
    });
    _loadSettings();
  }

  void _loadSettings() {
    if (!DatabaseService.settingsBox.isOpen) return;
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    if (settings.appVersion != '1.3.0') {
      settings.appVersion = '1.3.0';
      DatabaseService.settingsBox.put('settings', settings);
    }
    
    List<JobType> list = [];
    if (DatabaseService.isOperationalOpen) {
      list = DatabaseService.jobTypesBox.values
          .where((jt) => jt.isDeleted != true)
          .toList();
      // Sort job types alphabetically
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    state = SettingsState(
      jobTypes: list,
      isBiometricEnabled: settings.isBiometricEnabled,
      appVersion: settings.appVersion,
      profileName: settings.profileName ?? 'Admin Gudang Utama',
      profilePhone: settings.profilePhone ?? '',
      profileCompanyName: settings.profileCompanyName ?? 'Gudang Utama',
      profileImagePath: settings.profileImagePath,
    );
  }

  // Update profile details in settings
  Future<bool> updateProfile({
    required String name,
    required String companyName,
    required String phone,
    String? profileImagePath,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Nama pengguna wajib diisi');
      return false;
    }

    try {
      final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
      final oldName = settings.profileName;
      settings.profileName = name.trim();
      settings.profileCompanyName = companyName.trim();
      settings.profilePhone = phone.trim();
      if (profileImagePath != null) {
        settings.profileImagePath = profileImagePath;
      }
      
      await DatabaseService.settingsBox.put('settings', settings);
      
      // Log audit
      ref.read(auditLogProvider.notifier).logActivity(
        action: 'EDIT_PROFIL',
        description: 'Mengubah nama profil admin: $oldName -> ${settings.profileName}',
      );

      _loadSettings();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal memperbarui profil: $e');
      return false;
    }
  }

  // Update profile image only
  Future<bool> updateProfileImage(String path) async {
    try {
      final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
      settings.profileImagePath = path;
      await DatabaseService.settingsBox.put('settings', settings);
      
      // Log audit
      ref.read(auditLogProvider.notifier).logActivity(
        action: 'EDIT_FOTO_PROFIL',
        description: 'Mengubah foto profil admin',
      );

      _loadSettings();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal memperbarui foto profil: $e');
      return false;
    }
  }

  // Add JobType
  Future<bool> addJobType(String name, double ratePerUnit) async {
    if (name.trim().isEmpty || ratePerUnit < 0) {
      state = state.copyWith(errorMessage: 'Nama wajib diisi dan tarif minimal 0');
      return false;
    }

    final id = const Uuid().v4();
    final now = DateTime.now();
    final jobType = JobType(
      id: id,
      name: name.trim(),
      ratePerUnit: ratePerUnit,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.jobTypesBox.put(id, jobType);
    
    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'TAMBAH_TIPE_PEKERJAAN',
      description: 'Menambahkan jenis pekerjaan baru: ${jobType.name} (Tarif: $ratePerUnit)',
    );

    _loadSettings();
    return true;
  }

  // Update JobType
  Future<bool> updateJobType(String id, String name, double ratePerUnit) async {
    final jobType = DatabaseService.jobTypesBox.get(id);
    if (jobType == null) {
      state = state.copyWith(errorMessage: 'Jenis pekerjaan tidak ditemukan');
      return false;
    }

    if (name.trim().isEmpty || ratePerUnit < 0) {
      state = state.copyWith(errorMessage: 'Nama wajib diisi dan tarif minimal 0');
      return false;
    }

    final oldName = jobType.name;
    jobType.name = name.trim();
    jobType.ratePerUnit = ratePerUnit;
    jobType.updatedAt = DateTime.now();

    await jobType.save();
    
    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_TIPE_PEKERJAAN',
      description: 'Mengubah jenis pekerjaan: $oldName -> ${jobType.name} (Tarif: $ratePerUnit)',
    );

    _loadSettings();
    return true;
  }

  // Delete JobType
  Future<bool> deleteJobType(String id) async {
    final jobType = DatabaseService.jobTypesBox.get(id);
    if (jobType != null) {
      jobType.isDeleted = true;
      jobType.updatedAt = DateTime.now();
      await jobType.save();

      // Log audit
      ref.read(auditLogProvider.notifier).logActivity(
        action: 'HAPUS_TIPE_PEKERJAAN',
        description: 'Menghapus jenis pekerjaan (soft delete): ${jobType.name}',
      );

      _loadSettings();
      return true;
    }
    return false;
  }

  // Toggle biometric settings
  Future<void> toggleBiometric(bool enabled) async {
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    settings.isBiometricEnabled = enabled;
    await DatabaseService.settingsBox.put('settings', settings);
    
    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'EDIT_BIOMETRIK',
      description: 'Mengubah status biometrik menjadi: ${enabled ? "Aktif" : "Nonaktif"}',
    );

    state = state.copyWith(isBiometricEnabled: enabled);
  }

  // Change PIN from Settings screen
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!AuthService.verifyPin(oldPin)) {
      state = state.copyWith(errorMessage: 'PIN lama salah');
      return false;
    }

    if (newPin.length != 6 || int.tryParse(newPin) == null) {
      state = state.copyWith(errorMessage: 'PIN baru harus berupa 6 angka');
      return false;
    }

    await AuthService.registerPin(newPin);

    // If it was skipped, it is no longer skipped
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    if (settings.isPinSkipped == true) {
      settings.isPinSkipped = false;
      await DatabaseService.settingsBox.put('settings', settings);
    }
    
    // Log audit
    ref.read(auditLogProvider.notifier).logActivity(
      action: 'UBAH_PIN',
      description: 'Mengubah PIN login aplikasi',
    );

    state = state.copyWith(isSuccess: true);
    return true;
  }

  void refreshJobTypes() {
    _loadSettings();
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});
