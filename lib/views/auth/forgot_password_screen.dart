import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordViewModelProvider.notifier).resetPasswordDirect(
          email: _emailController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reactively show dialog on success
    ref.listen<ForgotPasswordState>(forgotPasswordViewModelProvider, (prev, next) {
      if (next.status == ForgotPasswordStatus.success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Reset Success'),
              ],
            ),
            content: const Text(
              'Your password has been updated successfully. You can now log in with your new password.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.pop(); // Go back to login
                },
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppConstants.textDark : AppConstants.textLight,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLg),
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 80, color: Color(0xFF4F46E5)),
                  const SizedBox(height: AppConstants.paddingLg),

                  Text(
                    'Recover Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.textDark : AppConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXs),
                  Text(
                    'Enter your registered email address and set your new password directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppConstants.textSecondaryDark : AppConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLg),

                  // Error Display Banner
                  if (state.errorMessage != null) ...[
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
                              state.errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red, size: 16),
                            onPressed: () => ref
                                .read(forgotPasswordViewModelProvider.notifier)
                                .clearError(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                  ],

                  // Email input
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'Enter your email address',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMd),

                  // New Password
                  CustomTextField(
                    controller: _newPasswordController,
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !state.isNewPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        state.isNewPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => ref
                          .read(forgotPasswordViewModelProvider.notifier)
                          .toggleNewPasswordVisibility(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'New password is required';
                      if (val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMd),

                  // Confirm Password
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: 'Confirm new password',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !state.isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        state.isConfirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => ref
                          .read(forgotPasswordViewModelProvider.notifier)
                          .toggleConfirmPasswordVisibility(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Confirm password is required';
                      if (val != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingLg),

                  CustomButton(
                    text: 'Reset Password',
                    isLoading: state.status == ForgotPasswordStatus.updatingPassword,
                    onPressed: _handleResetPassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
