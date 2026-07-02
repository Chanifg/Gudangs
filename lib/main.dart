import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/database_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'widgets/lifecycle_watcher.dart';
import 'widgets/inactivity_watcher.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Indonesian locale formatting
  await initializeDateFormatting('id_ID', null);
  
  // Initialize local encrypted Hive database
  await DatabaseService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return LifecycleWatcher(
      child: InactivityWatcher(
        child: MaterialApp.router(
          title: 'Gudangs',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
