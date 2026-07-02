import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/job_type.dart';
import '../models/app_settings.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class SettingsState {
  final List<JobType> jobTypes;
  final bool isBiometricEnabled;
  final String appVersion;
  final String? errorMessage;
  final bool isSuccess;

  SettingsState({
    required this.jobTypes,
    required this.isBiometricEnabled,
    required this.appVersion,
    this.errorMessage,
    this.isSuccess = false,
  });

  SettingsState copyWith({
    List<JobType>? jobTypes,
    bool? isBiometricEnabled,
    String? appVersion,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SettingsState(
      jobTypes: jobTypes ?? this.jobTypes,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      appVersion: appVersion ?? this.appVersion,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? false,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          jobTypes: [],
          isBiometricEnabled: true,
          appVersion: '1.0.0',
        )) {
    _loadSettings();
  }

  void _loadSettings() {
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    final list = DatabaseService.jobTypesBox.values.toList();
    
    // Sort job types alphabetically
    list.sort((a, b) => a.name.compareTo(b.name));

    state = SettingsState(
      jobTypes: list,
      isBiometricEnabled: settings.isBiometricEnabled,
      appVersion: settings.appVersion,
    );
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
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.jobTypesBox.put(id, jobType);
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

    jobType.name = name.trim();
    jobType.ratePerUnit = ratePerUnit;
    jobType.updatedAt = DateTime.now();

    await jobType.save();
    _loadSettings();
    return true;
  }

  // Delete JobType
  Future<bool> deleteJobType(String id) async {
    // Check if job type is being used in any activity records
    final isUsed = DatabaseService.activityBox.values.any((act) => act.jobTypeId == id);
    if (isUsed) {
      state = state.copyWith(
        errorMessage: 'Tidak dapat menghapus jenis pekerjaan ini karena masih digunakan dalam riwayat aktivitas karyawan.',
      );
      return false;
    }

    await DatabaseService.jobTypesBox.delete(id);
    _loadSettings();
    return true;
  }

  // Toggle biometric settings
  Future<void> toggleBiometric(bool enabled) async {
    final settings = DatabaseService.settingsBox.get('settings') ?? AppSettings();
    settings.isBiometricEnabled = enabled;
    await DatabaseService.settingsBox.put('settings', settings);
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
    state = state.copyWith(isSuccess: true);
    return true;
  }

  void clearMessage() {
    state = state.copyWith(errorMessage: null, isSuccess: false);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
