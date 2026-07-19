import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/statistics.dart';
import '../repositories/statistics_repository.dart';

/// State cho màn Dashboard — chứa dữ liệu thống kê tổng quan.
class DashboardState {
  final Statistics? statistics;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastSyncTime;
  final String greetingName;

  DashboardState({
    this.statistics,
    this.isLoading = false,
    this.errorMessage,
    this.lastSyncTime,
    this.greetingName = 'Member',
  });

  DashboardState copyWith({
    Statistics? statistics,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastSyncTime,
    String? greetingName,
    bool clearError = false,
    bool clearStatistics = false,
  }) {
    return DashboardState(
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      greetingName: greetingName ?? this.greetingName,
    );
  }

  /// Lời chào dựa theo giờ trong ngày
  String get timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
    if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  /// Tỉ lệ hoàn thành dạng %
  String get completionRateLabel {
    if (statistics == null) return '0%';
    return '${(statistics!.completionRate * 100).toStringAsFixed(0)}%';
  }

  /// Có dữ liệu hợp lệ để hiển thị không
  bool get hasData => statistics != null && !isLoading;
}

/// ViewModel cho màn Dashboard.
/// Quản lý việc tải, refresh dữ liệu thống kê và tên người dùng.
class DashboardViewModel extends StateNotifier<DashboardState> {
  final StatisticsRepository _statisticsRepository;

  DashboardViewModel(this._statisticsRepository) : super(DashboardState());

  /// Tải dữ liệu thống kê lần đầu hoặc khi navigate vào màn.
  Future<void> loadStatistics({String? dateRange, String? userId, String? role}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatistics: true,
    );
    try {
      final stats = await _statisticsRepository.getStatistics(
        dateRange: dateRange,
        userId: userId,
        role: role,
      );
      state = state.copyWith(
        statistics: stats,
        isLoading: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Force refresh — bỏ qua cache, tải lại từ API.
  Future<void> refreshData({String? userId, String? role}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearStatistics: true,
    );
    try {
      _statisticsRepository.invalidateCache();
      final stats = await _statisticsRepository.getStatistics(
        forceRefresh: true,
        userId: userId,
        role: role,
      );
      state = state.copyWith(
        statistics: stats,
        isLoading: false,
        lastSyncTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Cập nhật tên hiển thị người dùng (gọi sau khi auth thành công).
  void setGreetingName(String name) {
    state = state.copyWith(greetingName: name);
  }

  /// Xoá thông báo lỗi.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reset complete dashboard state.
  void resetStatistics() {
    state = DashboardState();
  }
}
