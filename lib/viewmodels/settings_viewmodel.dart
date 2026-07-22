import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/db_helper.dart';
import '../core/constants/app_constants.dart';

/// State cho màn Settings — lưu toàn bộ cài đặt của người dùng.
class SettingsState {
  final bool isDarkMode;
  final bool isPushNotificationEnabled;
  final bool isNotificationSoundEnabled;
  final String language;
  final String userName;
  final String userEmail;
  final String userRole;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  SettingsState({
    this.isDarkMode = false,
    this.isPushNotificationEnabled = true,
    this.isNotificationSoundEnabled = true,
    this.language = 'en',
    this.userName = 'Member',
    this.userEmail = '',
    this.userRole = 'Member',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? isPushNotificationEnabled,
    bool? isNotificationSoundEnabled,
    String? language,
    String? userName,
    String? userEmail,
    String? userRole,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isPushNotificationEnabled:
          isPushNotificationEnabled ?? this.isPushNotificationEnabled,
      isNotificationSoundEnabled:
          isNotificationSoundEnabled ?? this.isNotificationSoundEnabled,
      language: language ?? this.language,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userRole: userRole ?? this.userRole,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  /// ThemeMode dùng cho MaterialApp
  ThemeMode get themeMode =>
      isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Avatartext từ chữ đầu của tên
  String get avatarInitial {
    if (userName.isEmpty) return 'M';
    return userName[0].toUpperCase();
  }

  /// True nếu ngôn ngữ hiện tại là Tiếng Việt.
  bool get isVietnamese => language == 'vi';
}

/// ViewModel cho màn Settings.
/// Tích hợp SharedPreferences để lưu cài đặt persistent.
class SettingsViewModel extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  final DbHelper _dbHelper = DbHelper.instance;

  SettingsViewModel(this._prefs) : super(SettingsState()) {
    _loadSettings();
  }

  /// Tải toàn bộ settings đã lưu từ SharedPreferences.
  void _loadSettings() {
    final isDark = _prefs.getBool(AppConstants.themeModeKey) ?? false;
    final isPush = _prefs.getBool('push_notifications_enabled') ?? true;
    final isSound = _prefs.getBool('notification_sound_enabled') ?? true;
    final lang = _prefs.getString('app_language') ?? 'en';
    final name = _prefs.getString('cached_user_name') ?? 'Member';
    final email = _prefs.getString('cached_user_email') ?? '';
    final role = _prefs.getString('cached_user_role') ?? 'Member';

    state = state.copyWith(
      isDarkMode: isDark,
      isPushNotificationEnabled: isPush,
      isNotificationSoundEnabled: isSound,
      language: lang,
      userName: name,
      userEmail: email,
      userRole: role,
    );
  }

  /// Bật/tắt Dark Mode và lưu vào SharedPreferences.
  Future<void> toggleDarkMode() async {
    final newValue = !state.isDarkMode;
    state = state.copyWith(isDarkMode: newValue);
    await _prefs.setBool(AppConstants.themeModeKey, newValue);
  }

  /// Bật/tắt thông báo đẩy.
  Future<void> togglePushNotifications() async {
    final newValue = !state.isPushNotificationEnabled;
    state = state.copyWith(isPushNotificationEnabled: newValue);
    await _prefs.setBool('push_notifications_enabled', newValue);
  }

  /// Bật/tắt âm thanh thông báo.
  Future<void> toggleNotificationSound() async {
    final newValue = !state.isNotificationSoundEnabled;
    state = state.copyWith(isNotificationSoundEnabled: newValue);
    await _prefs.setBool('notification_sound_enabled', newValue);
  }

  /// Chuyển đổi ngôn ngữ ứng dụng giữa Tiếng Anh ('en') và Tiếng Việt ('vi').
  Future<void> toggleLanguage() async {
    final newValue = state.isVietnamese ? 'en' : 'vi';
    state = state.copyWith(language: newValue);
    await _prefs.setString('app_language', newValue);
  }

  /// Đặt ngôn ngữ ứng dụng theo mã cụ thể ('en' hoặc 'vi').
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'vi') return;
    state = state.copyWith(language: languageCode);
    await _prefs.setString('app_language', languageCode);
  }

  /// Xoá toàn bộ dữ liệu cache SQLite.
  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true);
    try {
      // Xoá dữ liệu cache từ SQLite
      final db = await _dbHelper.database;
      await db.delete('notifications');
      await db.delete('pending_actions');

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Đã xoá cache thành công.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Xoá cache thất bại: ${e.toString()}',
      );
    }
  }

  /// Lưu thông tin người dùng sau khi đăng nhập.
  Future<void> saveUserInfo({
    required String name,
    required String email,
    required String role,
  }) async {
    await _prefs.setString('cached_user_name', name);
    await _prefs.setString('cached_user_email', email);
    await _prefs.setString('cached_user_role', role);
    state = state.copyWith(userName: name, userEmail: email, userRole: role);
  }

  /// Xoá thông báo lỗi/thành công.
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
