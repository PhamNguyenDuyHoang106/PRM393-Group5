import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../viewmodels/auth_viewmodel.dart';

export 'project_provider.dart';
export 'service_providers.dart';
export 'task_provider.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

// ViewModels Providers
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthViewModel(repository);
});
