import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/statistics_repository.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../viewmodels/statistics_viewmodel.dart';

export 'project_provider.dart';
export 'service_providers.dart';
export 'task_provider.dart';
export 'dashboard_provider.dart';
export '../viewmodels/forgot_password_viewmodel.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository();
});

// ViewModels Providers
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});

final forgotPasswordViewModelProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordViewModel, ForgotPasswordState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return ForgotPasswordViewModel(repository);
});

final statisticsViewModelProvider =
    StateNotifierProvider<StatisticsViewModel, StatisticsState>((ref) {
  final repository = ref.watch(statisticsRepositoryProvider);
  return StatisticsViewModel(repository);
});
