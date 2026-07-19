import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';
import '../../viewmodels/settings_viewmodel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsViewModelProvider);
    final settingsNotifier = ref.read(settingsViewModelProvider.notifier);
    final authUser = ref.watch(authViewModelProvider).user;

    // Tự động đồng bộ thông tin user từ Auth sang Settings nếu Settings trống
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
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _buildUserProfileHeader(settingsState),
          const SizedBox(height: 12),
          const Divider(),
          _buildSectionHeader('Giao diện & Tiện ích'),
          SwitchListTile(
            title: const Text('Giao diện tối (Dark Mode)'),
            subtitle: const Text('Chuyển đổi tông màu sáng hoặc tối của ứng dụng'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: settingsState.isDarkMode,
            onChanged: (val) => settingsNotifier.toggleDarkMode(),
          ),
          const Divider(),
          _buildSectionHeader('Thông báo'),
          SwitchListTile(
            title: const Text('Thông báo đẩy (Push Notifications)'),
            subtitle: const Text('Nhận cảnh báo thời hạn công việc'),
            secondary: const Icon(Icons.notifications_active_outlined),
            value: settingsState.isPushNotificationEnabled,
            onChanged: (val) => settingsNotifier.togglePushNotifications(),
          ),
          SwitchListTile(
            title: const Text('Âm thanh thông báo'),
            subtitle: const Text('Phát âm thanh khi có thông báo mới'),
            secondary: const Icon(Icons.volume_up_outlined),
            value: settingsState.isNotificationSoundEnabled,
            onChanged: (val) => settingsNotifier.toggleNotificationSound(),
          ),
          const Divider(),
          _buildSectionHeader('Dữ liệu & Hệ thống'),
          ListTile(
            leading: const Icon(Icons.storage_outlined, color: Colors.amber),
            title: const Text('Xóa bộ nhớ đệm (Clear Cache)'),
            subtitle: const Text('Xóa dữ liệu cached offline trong SQLite'),
            onTap: () => _showClearCacheDialog(context, settingsNotifier),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Về ứng dụng'),
            subtitle: const Text('Smart Task Management v1.0.0 (PRM393 MVP)'),
            onTap: () {},
          ),
          const Divider(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showLogoutDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileHeader(SettingsState settingsState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  settingsState.avatarInitial,
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settingsState.userName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      settingsState.userEmail,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        settingsState.userRole.toUpperCase(),
                        style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, settingsNotifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa bộ nhớ đệm?'),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ dữ liệu cached offline trong SQLite (thông báo, lịch sử hàng chờ sync). Các dữ liệu trên server sẽ không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await settingsNotifier.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã dọn dẹp cache SQLite thành công!')),
                );
              }
            },
            child: const Text('Xóa cache'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bạn muốn đăng xuất?'),
        content: const Text('Bạn sẽ cần nhập lại tài khoản và mật khẩu để đăng nhập lần sau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authViewModelProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
