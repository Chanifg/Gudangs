import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
        (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () {
        ref.read(themeProvider.notifier).setThemeMode(
          isDark ? ThemeMode.light : ThemeMode.dark,
        );
      },
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      color: colorScheme.primary,
      tooltip: isDark ? 'Aktifkan Mode Terang' : 'Aktifkan Mode Gelap',
    );
  }
}
