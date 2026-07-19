import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isEditing = false;
  String? _avatarBase64;
  
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authViewModelProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final extension = pickedFile.name.split('.').last;
        setState(() {
          _avatarBase64 = 'data:image/$extension;base64,$base64String';
        });
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _handleSaveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final name = _nameController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final oldPassword = _oldPasswordController.text.trim();

    final user = ref.read(authViewModelProvider).user;
    final isNameChanged = name != (user?.name ?? '');
    final isAvatarChanged = _avatarBase64 != null;
    final isPasswordProvided = newPassword.isNotEmpty;

    if (!isNameChanged && !isAvatarChanged && !isPasswordProvided) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    final success = await ref.read(authViewModelProvider.notifier).updateProfile(
      name: isNameChanged ? name : null,
      avatarUrl: isAvatarChanged ? _avatarBase64 : null,
      newPassword: isPasswordProvided ? newPassword : null,
      oldPassword: isPasswordProvided ? oldPassword : null,
    );

    if (success && mounted) {
      _oldPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _isEditing = false;
      });
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAvatarImage(String? avatarUrl, String? localBase64, bool isDark) {
    final source = localBase64 ?? avatarUrl;
    if (source == null || source.trim().isEmpty) {
      return Icon(
        Icons.person,
        size: 64,
        color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
      );
    }
    
    if (source.startsWith('data:image/') || !source.startsWith('http')) {
      try {
        final cleanBase64 = source.contains(';base64,') ? source.split(';base64,').last : source;
        final bytes = base64Decode(cleanBase64.trim());
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.person,
              size: 64,
              color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
            ),
          ),
        );
      } catch (_) {
        return Icon(
          Icons.person,
          size: 64,
          color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
        );
      }
    }

    return ClipOval(
      child: Image.network(
        source,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.person,
          size: 64,
          color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar with pick options on edit mode
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
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
                              child: _buildAvatarImage(currentUser?.avatarUrl, _avatarBase64, isDark),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                                radius: 18,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLg),

                  // Display Name and Email Card
                  Card(
                    color: isDark ? AppConstants.surfaceDark : AppConstants.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLg),
                      child: Column(
                        children: [
                          Text(
                            currentUser?.name ?? 'Anonymous User',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppConstants.textDark : AppConstants.textLight,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingXs),
                          Text(
                            currentUser?.email ?? 'No email associated',
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
                                  ? Colors.indigo.withAlpha(38)
                                  : Colors.teal.withAlpha(38),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
                              border: Border.all(
                                color: (currentUser?.isManager ?? true)
                                    ? AppConstants.primaryLight.withAlpha(76)
                                    : AppConstants.secondaryLight.withAlpha(76),
                              ),
                            ),
                            child: Text(
                              (currentUser?.role ?? 'member').toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
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

                  // Section Header
                  Text(
                    _isEditing ? 'Edit Profile' : 'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.textDark : AppConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSm),

                  // Error Display Banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMd),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                        border: Border.all(color: Colors.red.withAlpha(76)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: AppConstants.paddingSm),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 16),
                            onPressed: () => ref
                                .read(authViewModelProvider.notifier)
                                .clearError(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                  ],

                  // Form Input Card (Editable or Read-only preview)
                  Card(
                    color: isDark ? AppConstants.surfaceDark : AppConstants.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                    ),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingLg),
                      child: _isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CustomTextField(
                                  controller: _nameController,
                                  labelText: 'Full Name',
                                  hintText: 'Enter your name',
                                  prefixIcon: Icons.badge_outlined,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppConstants.paddingMd),
                                
                                const Divider(height: 32),
                                Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppConstants.textDark : AppConstants.textLight,
                                  ),
                                ),
                                const SizedBox(height: AppConstants.paddingSm),
                                
                                CustomTextField(
                                  controller: _oldPasswordController,
                                  labelText: 'Current Password',
                                  hintText: 'Required to confirm changes',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: !_isOldPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isOldPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() {
                                      _isOldPasswordVisible = !_isOldPasswordVisible;
                                    }),
                                  ),
                                  validator: (val) {
                                    if (_newPasswordController.text.isNotEmpty &&
                                        (val == null || val.isEmpty)) {
                                      return 'Current password is required to change password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppConstants.paddingMd),

                                CustomTextField(
                                  controller: _newPasswordController,
                                  labelText: 'New Password',
                                  hintText: 'Enter new password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: !_isNewPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(() {
                                      _isNewPasswordVisible = !_isNewPasswordVisible;
                                    }),
                                  ),
                                  validator: (val) {
                                    if (val != null && val.isNotEmpty && val.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _ProfileDetailItem(
                                  icon: Icons.badge_outlined,
                                  label: 'Name',
                                  value: currentUser?.name ?? 'Not set',
                                  isDark: isDark,
                                ),
                                const Divider(height: 24),
                                _ProfileDetailItem(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: currentUser?.email ?? 'Not set',
                                  isDark: isDark,
                                ),
                                const Divider(height: 24),
                                _ProfileDetailItem(
                                  icon: Icons.security_rounded,
                                  label: 'Role',
                                  value: (currentUser?.role ?? 'member').toUpperCase(),
                                  isDark: isDark,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLg),

                  // Actions Stack: Edit and Logout are full-width and stacked vertically
                  if (_isEditing) ...[
                    CustomButton(
                      text: 'Save Changes',
                      isLoading: authState.isLoading,
                      onPressed: _handleSaveChanges,
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditing = false;
                          _oldPasswordController.clear();
                          _newPasswordController.clear();
                          _avatarBase64 = null;
                        });
                      },
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    // Edit Profile Button (Now stacked above Logout, full-width)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                        ),
                        elevation: 1,
                      ),
                      onPressed: () {
                        setState(() {
                          _nameController.text = currentUser?.name ?? '';
                          _avatarBase64 = null;
                          _isEditing = true;
                        });
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                    // Logout Button (Below Edit Profile)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
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
                        elevation: 1,
                      ),
                      onPressed: () async {
                        await ref.read(authViewModelProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ProfileDetailItem Widget ────────────────────────────────────────────────
class _ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? AppConstants.primaryDark : AppConstants.primaryLight,
          size: 20,
        ),
        const SizedBox(width: AppConstants.paddingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppConstants.textDark : AppConstants.textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
