import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'viewmodels/settings_viewmodel.dart';

// We will declare a simple theme state provider for the settings toggle
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Synchronize settingsViewModelProvider isDarkMode state to themeModeProvider
    ref.listen<SettingsState>(settingsViewModelProvider, (previous, next) {
      if (previous?.isDarkMode != next.isDarkMode) {
        ref.read(themeModeProvider.notifier).state =
            next.isDarkMode ? ThemeMode.dark : ThemeMode.light;
      }
    });

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Smart Task Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
