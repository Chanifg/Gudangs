import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool hasPin;
  final bool isBiometricAvailable;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.hasPin = false,
    this.isBiometricAvailable = false,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.errorMessage,
    this.isLoading = false,
  });

  bool get isLocked => lockoutUntil != null && DateTime.now().isBefore(lockoutUntil!);

  int get lockoutSecondsRemaining {
    if (lockoutUntil == null) return 0;
    final diff = lockoutUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  AuthState copyWith({
    bool? isAuthenticated,
    bool? hasPin,
    bool? isBiometricAvailable,
    int? failedAttempts,
    DateTime? lockoutUntil,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasPin: hasPin ?? this.hasPin,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  Timer? _lockoutTimer;

  AuthNotifier() : super(AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final hasPin = AuthService.hasPinSetup();
    final biometric = await AuthService.isBiometricsAvailable();
    state = state.copyWith(hasPin: hasPin, isBiometricAvailable: biometric);
  }

  Future<bool> setupPin(String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await AuthService.registerPin(pin);
      state = state.copyWith(isAuthenticated: true, hasPin: true, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal membuat PIN', isLoading: false);
      return false;
    }
  }

  Future<bool> loginWithPin(String pin) async {
    if (state.isLocked) {
      state = state.copyWith(errorMessage: 'Aplikasi terkunci. Silakan coba lagi nanti.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    
    // Simulate slight delay for professional security feel
    await Future.delayed(const Duration(milliseconds: 300));

    final success = AuthService.verifyPin(pin);
    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        failedAttempts: 0,
        lockoutUntil: null,
        isLoading: false,
      );
      _lockoutTimer?.cancel();
      return true;
    } else {
      final attempts = state.failedAttempts + 1;
      DateTime? lockoutUntil;
      String? errorMsg = 'PIN salah (Percobaan $attempts/5)';

      if (attempts >= 5) {
        lockoutUntil = DateTime.now().add(const Duration(minutes: 5));
        errorMsg = 'Terlalu banyak percobaan salah. Aplikasi terkunci selama 5 menit.';
        _startLockoutCountdown();
      }

      state = state.copyWith(
        failedAttempts: attempts,
        lockoutUntil: lockoutUntil,
        errorMessage: errorMsg,
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> loginWithBiometric() async {
    if (state.isLocked) {
      state = state.copyWith(errorMessage: 'Aplikasi terkunci. Silakan coba lagi nanti.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    final success = await AuthService.authenticateBiometric();
    
    if (success) {
      state = state.copyWith(
        isAuthenticated: true,
        failedAttempts: 0,
        lockoutUntil: null,
        isLoading: false,
      );
      return true;
    } else {
      state = state.copyWith(
        errorMessage: 'Autentikasi biometrik gagal atau dibatalkan.',
        isLoading: false,
      );
      return false;
    }
  }

  void logout() {
    state = state.copyWith(isAuthenticated: false, errorMessage: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isLocked) {
        // Trigger state refresh to update UI timers
        state = state.copyWith();
      } else {
        state = state.copyWith(failedAttempts: 0, lockoutUntil: null);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
