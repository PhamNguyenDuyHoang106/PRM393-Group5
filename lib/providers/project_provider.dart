import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/project_repository.dart';
import '../viewmodels/project_viewmodel.dart';
import 'service_providers.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectViewModelProvider =
    StateNotifierProvider<ProjectViewModel, ProjectState>((ref) {
      // Start automatic queue synchronization when the project module is used.
      ref.watch(syncServiceProvider);
      final repository = ref.watch(projectRepositoryProvider);
      final connectivity = ref.watch(connectivityServiceProvider);
      return ProjectViewModel(repository, connectivity);
    });
