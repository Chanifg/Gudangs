import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  String? _error;

  void _onNumberPressed(String number) {
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.length < 6) {
          _pin.add(number);
          if (_pin.length == 6) {
            // Move to confirmation stage after a brief pause
            Future.delayed(const Duration(milliseconds: 250), () {
              setState(() {
                _isConfirming = true;
              });
            });
          }
        }
      } else {
        if (_confirmPin.length < 6) {
          _confirmPin.add(number);
          if (_confirmPin.length == 6) {
            _verifyAndSave();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _error = null;
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin.removeLast();
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin.removeLast();
        } else {
          // Allow going back to initial pin input
          _isConfirming = false;
          _pin.removeLast();
        }
      }
    });
  }

  Future<void> _verifyAndSave() async {
    final pinStr = _pin.join();
    final confirmStr = _confirmPin.join();

    if (pinStr == confirmStr) {
      final success = await ref.read(authProvider.notifier).setupPin(pinStr);
      if (success) {
        if (mounted) {
          context.go('/dashboard');
        }
      } else {
        setState(() {
          _error = 'Gagal menyimpan PIN. Coba lagi.';
          _reset();
        });
      }
    } else {
      setState(() {
        _error = 'PIN konfirmasi tidak cocok';
        _reset();
      });
    }
  }

  void _reset() {
    _pin.clear();
    _confirmPin.clear();
    _isConfirming = false;
  }

  @override
  Widget build(BuildContext context) {
    final currentLength = _isConfirming ? _confirmPin.length : _pin.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Title & Info
            Icon(
              Icons.security_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              _isConfirming ? 'Konfirmasi PIN Anda' : 'Buat PIN Keamanan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _isConfirming
                    ? 'Masukkan kembali 6 digit kode PIN yang baru saja Anda buat.'
                    : 'PIN ini akan digunakan sebagai pelindung data gudang lokal Anda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 32),

            // PIN Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final active = index < currentLength;
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
            
            // Error Message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
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
                      // Reset Button
                      IconButton(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh),
                        color: colorScheme.onSurfaceVariant,
                        iconSize: 28,
                      ),
                      _buildKeyboardButton('0'),
                      // Backspace Button
                      IconButton(
                        onPressed: _onDeletePressed,
                        icon: const Icon(Icons.backspace_outlined),
                        color: colorScheme.onSurfaceVariant,
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
    return InkWell(
      onTap: () => _onNumberPressed(num),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
