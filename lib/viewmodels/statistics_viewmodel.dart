import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/statistics_repository.dart';

class StatisticsState {
  final DashboardStats? stats;
  final bool isLoading;
  final String? errorMessage;

  StatisticsState({
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  StatisticsState copyWith({
    DashboardStats? stats,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class StatisticsViewModel extends StateNotifier<StatisticsState> {
  final StatisticsRepository _repository;

  StatisticsViewModel(this._repository) : super(StatisticsState());

  Future<void> loadDashboardStats() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = await _repository.getDashboard();
      state = state.copyWith(stats: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
