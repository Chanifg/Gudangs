import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';

class LifecycleWatcher extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleWatcher({super.key, required this.child});

  @override
  ConsumerState<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends ConsumerState<LifecycleWatcher> with WidgetsBindingObserver {
  DateTime? _pausedTimestamp;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bypass auto-lock if PIN setup was skipped
    final settings = DatabaseService.settingsBox.get('settings');
    if (settings?.isPinSkipped == true) return;

    final authState = ref.read(authProvider);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App entered background, record the timestamp if user is authenticated
      if (authState.isAuthenticated && _pausedTimestamp == null) {
        _pausedTimestamp = DateTime.now();
      }
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      if (authState.isAuthenticated && _pausedTimestamp != null) {
        final secondsInBackground = DateTime.now().difference(_pausedTimestamp!).inSeconds;
        
        // Auto-lock if the app was in the background for more than 5 seconds
        if (secondsInBackground >= 5) {
          ref.read(authProvider.notifier).logout();
        }
      }
      
      // Reset timestamp
      _pausedTimestamp = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
