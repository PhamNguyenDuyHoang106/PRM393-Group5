import '../core/database/db_helper.dart';
import '../models/statistics.dart';

/// Repository xử lý dữ liệu thống kê từ API GET /api/v1/statistics.
class StatisticsRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Statistics? _cachedStatistics;
  DateTime? _lastFetchTime;

  /// Kiểm tra cache có hợp lệ không (dưới 5 phút)
  bool get _isCacheValid {
    if (_cachedStatistics == null || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!).inMinutes < 5;
  }

  /// Lấy dữ liệu thống kê từ API hoặc cache.
  /// Nếu mạng lỗi, trả về cache gần nhất hoặc tính toán từ local DB.
  Future<Statistics> getStatistics({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cachedStatistics!;
    }

    try {
      // --- Giả lập gọi API (Sử dụng DioClient thực tế khi có backend) ---
      // final response = await _dioClient.dio.get('/statistics');
      // final stats = Statistics.fromJson(response.data as Map<String, dynamic>);
      
      // Ở đây ta gọi thử, nếu không có backend thực tế (hoặc lỗi), ta bắt e và ném sang catch để lấy SQLite
      throw Exception("No REST API backend connected. Falling back to local SQLite.");
    } catch (e) {
      try {
        // Fallback sang tính toán thống kê từ SQLite cục bộ
        final localStats = await _dbHelper.getLocalStatistics();
        _cachedStatistics = localStats;
        _lastFetchTime = DateTime.now();
        return localStats;
      } catch (dbError) {
        // Trả mock data nếu cả SQLite cũng lỗi (bảo hiểm trường hợp DB chưa seed)
        final mockStats = Statistics.mock();
        _cachedStatistics = mockStats;
        _lastFetchTime = DateTime.now();
        return mockStats;
      }
    }
  }

  /// Tính tỉ lệ hoàn thành dựa trên số task done / tổng task.
  double computeCompletionRate(Statistics stats) {
    if (stats.totalTasks == 0) return 0.0;
    return stats.completedTasks / stats.totalTasks;
  }

  /// Tổng số task theo trạng thái status cụ thể.
  int getCountByStatus(Statistics stats, String status) {
    return stats.taskStatusDistribution[status] ?? 0;
  }

  /// Tổng số task theo mức ưu tiên cụ thể.
  int getCountByPriority(Statistics stats, String priority) {
    return stats.taskPriorityDistribution[priority] ?? 0;
  }

  /// Xoá cache, buộc fetch lại data khi gọi tiếp theo.
  void invalidateCache() {
    _cachedStatistics = null;
    _lastFetchTime = null;
  }
}
