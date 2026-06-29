import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'Smart Task';

  // Persisted Storage Keys
  static const String themeModeKey = 'theme_mode';
  static const String authTokenKey = 'auth_token';
  static const String rememberMeKey = 'remember_me';

  // Standard Theme Colors
  static const Color primaryLight = Color(0xFF6366F1); // Modern Indigo
  static const Color primaryDark = Color(0xFF818CF8);

  static const Color secondaryLight = Color(0xFF10B981); // Emerald
  static const Color secondaryDark = Color(0xFF34D399);

  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF0B0F19); // Rich dark blue-gray

  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF151B2C);

  static const Color textLight = Color(0xFF111827);
  static const Color textDark = Color(0xFFF3F4F6);

  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  // Status Colors
  static const Color todoColor = Color(0xFF3B82F6); // Blue
  static const Color inProgressColor = Color(0xFFF59E0B); // Amber
  static const Color doneColor = Color(0xFF10B981); // Emerald

  // Priority Colors
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityHigh = Color(0xFFEF4444);

  // Layout Spacers
  static const double paddingXs = 4.0;
  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;
  static const double paddingXl = 32.0;

  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
}
