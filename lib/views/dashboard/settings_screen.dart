import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_strings.dart';
import '../../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    final authUser = ref.watch(authViewModelProvider).user;
    final isDark = settingsState.isDarkMode;
    final strings = AppStrings(settingsState.isVietnamese);

    // Automatically sync user profile info from Auth VM
    if (settingsState.userEmail.isEmpty && authUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        settingsNotifier.saveUserInfo(
          name: authUser.name,
          email: authUser.email,
          role: authUser.role,
        );
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          strings.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          _buildUserProfileHeader(authUser, isDark),
          const SizedBox(height: 24),

          _buildSectionHeader(strings.sectionPreferences),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: Text(
                  strings.darkMode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.darkModeSubtitle),
                secondary: Icon(
                  Icons.dark_mode_rounded,
                  color: isDark ? Colors.cyanAccent : Colors.indigo,
                ),
                value: settingsState.isDarkMode,
                onChanged: (val) {
                  settingsNotifier.toggleDarkMode();
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Icon(
                  Icons.language_rounded,
                  color: isDark ? Colors.cyanAccent : Colors.indigo,
                ),
                title: Text(
                  strings.language,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.languageSubtitle),
                trailing: _buildLanguageSwitch(settingsState.isVietnamese, settingsNotifier, isDark),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(strings.sectionNotifications),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: Text(
                  strings.pushNotifications,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.pushNotificationsSubtitle),
                secondary: const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent),
                value: settingsState.isPushNotificationEnabled,
                onChanged: (val) => settingsNotifier.togglePushNotifications(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: Text(
                  strings.notificationSounds,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.notificationSoundsSubtitle),
                secondary: const Icon(Icons.volume_up_rounded, color: Colors.green),
                value: settingsState.isNotificationSoundEnabled,
                onChanged: (val) => settingsNotifier.toggleNotificationSound(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader(strings.sectionSystemData),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
                title: Text(
                  strings.clearLocalCache,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.clearLocalCacheSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showClearCacheDialog(context, settingsNotifier, isDark, strings),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.description_rounded, color: Colors.indigoAccent),
                title: Text(
                  strings.termsAndPrivacy,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.termsAndPrivacySubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showTermsDialog(context, isDark, strings),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.info_rounded, color: Colors.teal),
                title: Text(
                  strings.aboutApp,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(strings.aboutAppSubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showAboutDialog(context, isDark, strings),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageSwitch(bool isVietnamese, dynamic settingsNotifier, bool isDark) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(value: false, label: Text('EN')),
        ButtonSegment<bool>(value: true, label: Text('VI')),
      ],
      selected: {isVietnamese},
      showSelectedIcon: false,
      onSelectionChanged: (selection) {
        settingsNotifier.setLanguage(selection.first ? 'vi' : 'en');
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildUserProfileHeader(dynamic authUser, bool isDark) {
    final name = authUser?.name ?? 'User';
    final email = authUser?.email ?? '';
    final role = authUser?.role ?? 'member';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.indigo.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 24,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFF4F46E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(51),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children, required bool isDark}) {
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, dynamic settingsNotifier, bool isDark, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.wipeCacheTitle,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        content: Text(
          strings.wipeCacheContent,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await settingsNotifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.cacheClearedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(strings.clearCache, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, bool isDark, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.termsTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                strings.termsSection1Title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyanAccent : Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.termsSection1Body,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                strings.termsSection2Title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyanAccent : Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.termsSection2Body,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                strings.termsSection3Title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.cyanAccent : Colors.blue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.termsSection3Body,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.agreeAndClose, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark, AppStrings strings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.aboutTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_rounded, size: 48, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  strings.aboutAppName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  strings.aboutVersion,
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const Divider(height: 24),
              Text(
                strings.aboutDescription,
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(strings.close, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
