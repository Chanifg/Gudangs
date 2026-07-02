import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final List<String> _pin = [];

  @override
  void initState() {
    super.initState();
    // Attempt biometric authentication after the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAuto();
    });
  }

  Future<void> _checkBiometricAuto() async {
    final authState = ref.read(authProvider);
    if (authState.isBiometricAvailable && !authState.isLocked) {
      final success = await ref.read(authProvider.notifier).loginWithBiometric();
      if (success && mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _onNumberPressed(String number) {
    final authState = ref.read(authProvider);
    if (authState.isLocked) return;

    setState(() {
      ref.read(authProvider.notifier).clearError();
      if (_pin.length < 6) {
        _pin.add(number);
        if (_pin.length == 6) {
          _submitPin();
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      ref.read(authProvider.notifier).clearError();
      if (_pin.isNotEmpty) _pin.removeLast();
    });
  }

  Future<void> _submitPin() async {
    final pinStr = _pin.join();
    final success = await ref.read(authProvider.notifier).loginWithPin(pinStr);
    
    if (success) {
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      setState(() {
        _pin.clear(); // Clear input on failure
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // Check if the user is locked out, show remaining time
    final isLocked = authState.isLocked;
    final lockoutSeconds = authState.lockoutSecondsRemaining;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Brand Logo
            Icon(
              Icons.warehouse,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Gudangs',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan PIN Keamanan untuk Masuk',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 40),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final active = index < _pin.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? colorScheme.primary : Colors.grey[300],
                    border: Border.all(
                      color: active ? colorScheme.primary : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Feedback/Error/Lockout Text
            if (isLocked) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Terlalu banyak salah. Coba lagi dalam $lockoutSeconds detik.',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (authState.errorMessage != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  authState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Custom Number Keyboard Layout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildKeyboardRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildKeyboardRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Biometric Login Button
                      IconButton(
                        onPressed: isLocked ? null : _checkBiometricAuto,
                        icon: Icon(
                          authState.isBiometricAvailable ? Icons.fingerprint : Icons.lock_outline,
                        ),
                        color: isLocked ? Colors.grey : colorScheme.primary,
                        iconSize: 36,
                      ),
                      _buildKeyboardButton('0'),
                      // Backspace Button
                      IconButton(
                        onPressed: isLocked ? null : _onDeletePressed,
                        icon: const Icon(Icons.backspace_outlined),
                        color: isLocked ? Colors.grey : colorScheme.onSurfaceVariant,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map(_buildKeyboardButton).toList(),
    );
  }

  Widget _buildKeyboardButton(String num) {
    final authState = ref.read(authProvider);
    final isLocked = authState.isLocked;

    return InkWell(
      onTap: isLocked ? null : () => _onNumberPressed(num),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLocked ? Colors.grey[100] : Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          num,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isLocked ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
