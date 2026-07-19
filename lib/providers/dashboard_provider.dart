import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/statistics_repository.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'providers.dart';

/// Provider cho SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

/// Provider cho StatisticsRepository
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

/// Provider cho DashboardViewModel
final dashboardViewModelProvider =
    StateNotifierProvider<DashboardViewModel, DashboardState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return DashboardViewModel(repository);
});

/// Provider cho NotificationViewModel
final notificationViewModelProvider =
    StateNotifierProvider<NotificationViewModel, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationViewModel(repository);
});

/// Provider cho SettingsViewModel
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsViewModel(prefs);
});
