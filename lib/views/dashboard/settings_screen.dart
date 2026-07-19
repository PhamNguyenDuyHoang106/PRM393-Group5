import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../providers/providers.dart';
import '../../viewmodels/settings_viewmodel.dart';


class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    final authUser = ref.watch(authViewModelProvider).user;
    final isDark = settingsState.isDarkMode;

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
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        children: [
          _buildUserProfileHeader(settingsState, isDark),
          const SizedBox(height: 24),
          
          _buildSectionHeader('PREFERENCES'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: Text(
                  'Dark Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text('Adjust application color theme'),
                secondary: Icon(
                  Icons.dark_mode_rounded,
                  color: isDark ? Colors.cyanAccent : Colors.indigo,
                ),
                value: settingsState.isDarkMode,
                onChanged: (val) {
                  settingsNotifier.toggleDarkMode();
                  ref.read(themeModeProvider.notifier).state =
                      val ? ThemeMode.dark : ThemeMode.light;
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('NOTIFICATIONS'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              SwitchListTile(
                title: Text(
                  'Push Notifications',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text('Receive warnings for task deadlines'),
                secondary: const Icon(Icons.notifications_active_rounded, color: Colors.blueAccent),
                value: settingsState.isPushNotificationEnabled,
                onChanged: (val) => settingsNotifier.togglePushNotifications(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              SwitchListTile(
                title: Text(
                  'Notification Sounds',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text('Play sound on new alerts'),
                secondary: const Icon(Icons.volume_up_rounded, color: Colors.green),
                value: settingsState.isNotificationSoundEnabled,
                onChanged: (val) => settingsNotifier.toggleNotificationSound(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSectionHeader('SYSTEM & DATA'),
          _buildSettingsGroup(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
                title: Text(
                  'Clear Local Cache',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text('Wipe offline SQLite database data'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showClearCacheDialog(context, settingsNotifier, isDark),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.info_rounded, color: Colors.teal),
                title: Text(
                  'About Application',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text('Smart Task Management v1.0.0 (PRM393 MVP)'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                shadowColor: Colors.redAccent.withAlpha(76),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Log Out Account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              onPressed: () => _showLogoutDialog(context, ref, isDark),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(SettingsState settingsState, bool isDark) {
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
                settingsState.avatarInitial,
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
                  settingsState.userName,
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settingsState.userEmail,
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
                    settingsState.userRole.toUpperCase(),
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

  void _showClearCacheDialog(BuildContext context, settingsNotifier, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Wipe Local Cache?',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        content: Text(
          'This action will delete all offline cached database tables (notifications, pending sync queues). Server data remains untouched.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await settingsNotifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('SQLite cache has been cleared successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Clear Cache', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log Out Account?',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
        ),
        content: Text(
          'You will need to input your email and password to log in next time.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
