import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

class InactivityWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const InactivityWatcher({super.key, required this.child});

  @override
  ConsumerState<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends ConsumerState<InactivityWatcher> {
  Timer? _inactivityTimer;

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    
    // Bypass auto-lock if PIN setup was skipped
    final settings = DatabaseService.settingsBox.get('settings');
    if (settings?.isPinSkipped == true) return;

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      _inactivityTimer = Timer(const Duration(minutes: 2), () {
        ref.read(authProvider.notifier).logout();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in authentication state to start/stop the timer
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        _resetTimer();
      } else {
        _inactivityTimer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
