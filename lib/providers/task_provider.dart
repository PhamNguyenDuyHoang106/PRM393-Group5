import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/task_repository.dart';
import '../viewmodels/task_viewmodel.dart';
import 'service_providers.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final taskViewModelProvider = StateNotifierProvider<TaskViewModel, TaskState>((
  ref,
) {
  ref.watch(syncServiceProvider);
  final repository = ref.watch(taskRepositoryProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return TaskViewModel(repository, connectivity, ref);
});
