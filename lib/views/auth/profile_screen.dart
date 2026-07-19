import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';

final pushNotificationsProvider = StateProvider<bool>((ref) => true);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: isDark ? AppConstants.surfaceDark : AppConstants.surfaceLight,
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLg),

              // User Info details
              Card(
                color: isDark ? AppConstants.surfaceDark : AppConstants.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLg),
                  child: Column(
                    children: [
                      Text(
                        currentUser?.name ?? 'Hoang Team Lead',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppConstants.textDark : AppConstants.textLight,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingXs),
                      Text(
                        currentUser?.email ?? 'manager@example.com',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMd),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: (currentUser?.isManager ?? true)
                              ? Colors.indigo.withValues(alpha: 0.15)
                              : Colors.teal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
                          border: Border.all(
                            color: (currentUser?.isManager ?? true)
                                ? AppConstants.primaryLight.withValues(alpha: 0.3)
                                : AppConstants.secondaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          currentUser?.role ?? 'Manager',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (currentUser?.isManager ?? true)
                                ? (isDark ? AppConstants.primaryDark : AppConstants.primaryLight)
                                : (isDark ? AppConstants.secondaryDark : AppConstants.secondaryLight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingLg),

              // Settings Header
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppConstants.textDark : AppConstants.textLight,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSm),

              // Integrated Settings Card
              Card(
                color: isDark ? AppConstants.surfaceDark : AppConstants.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                ),
                elevation: 2,
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        Icons.dark_mode_outlined,
                        color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                      ),
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(
                          color: isDark ? AppConstants.textDark : AppConstants.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Toggle light or dark interface theme',
                        style: TextStyle(
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      value: isDark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                      ),
                      title: Text(
                        'Push Notifications',
                        style: TextStyle(
                          color: isDark ? AppConstants.textDark : AppConstants.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Receive push alerts for deadline limits',
                        style: TextStyle(
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      value: ref.watch(pushNotificationsProvider),
                      onChanged: (val) {
                        ref.read(pushNotificationsProvider.notifier).state = val;
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.info_outline,
                        color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                      ),
                      title: Text(
                        'About App',
                        style: TextStyle(
                          color: isDark ? AppConstants.textDark : AppConstants.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Smart Task Management v1.0.0 (PRM393 MVP)',
                        style: TextStyle(
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: Icon(
                        Icons.settings_outlined,
                        color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                      ),
                      title: Text(
                        'Advanced Settings',
                        style: TextStyle(
                          color: isDark ? AppConstants.textDark : AppConstants.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Offline cache, sound and database configurations',
                        style: TextStyle(
                          color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.paddingLg),

              // Sign Out Button
              ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                  ),
                  elevation: 2,
                ),
                onPressed: () async {
                  await ref.read(authViewModelProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
