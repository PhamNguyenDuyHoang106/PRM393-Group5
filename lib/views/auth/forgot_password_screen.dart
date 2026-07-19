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
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordViewModelProvider.notifier).sendOtp(
          _emailController.text.trim(),
        );
  }

  void _handleVerifyOtp() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordViewModelProvider.notifier).verifyOtp(
          _otpController.text.trim(),
        );
  }

  void _handleResetPassword() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(forgotPasswordViewModelProvider.notifier).resetPassword(
          _newPasswordController.text.trim(),
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

    // Map status to current UI step
    final int step;
    if (state.status == ForgotPasswordStatus.idle ||
        state.status == ForgotPasswordStatus.sendingOtp) {
      step = 1;
    } else if (state.status == ForgotPasswordStatus.otpSent ||
        state.status == ForgotPasswordStatus.verifyingOtp) {
      step = 2;
    } else if (state.status == ForgotPasswordStatus.otpVerified ||
        state.status == ForgotPasswordStatus.updatingPassword) {
      step = 3;
    } else if (state.status == ForgotPasswordStatus.success) {
      step = 3;
    } else {
      // Failure status mapping
      if (state.email.isEmpty) {
        step = 1;
      } else if (state.otp.isEmpty) {
        step = 2;
      } else {
        step = 3;
      }
    }

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
                  // Step Indicator header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepCircle(stepNumber: 1, currentStep: step, isDark: isDark),
                      _StepLine(isActive: step > 1),
                      _StepCircle(stepNumber: 2, currentStep: step, isDark: isDark),
                      _StepLine(isActive: step > 2),
                      _StepCircle(stepNumber: 3, currentStep: step, isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLg),

                  // Dynamic Title & Description
                  Text(
                    step == 1
                        ? 'Recover Password'
                        : step == 2
                            ? 'Verify OTP Code'
                            : 'New Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppConstants.textDark : AppConstants.textLight,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingXs),
                  Text(
                    step == 1
                        ? 'Enter your email address to receive a 6-digit verification code.'
                        : step == 2
                            ? 'We sent a verification code to ${state.email}. Enter it below.'
                            : 'Please set a secure new password for your account.',
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
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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

                  // Dynamic inputs based on step
                  if (step == 1) ...[
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
                    const SizedBox(height: AppConstants.paddingLg),
                    CustomButton(
                      text: 'Send Verification OTP',
                      isLoading: state.status == ForgotPasswordStatus.sendingOtp,
                      onPressed: _handleSendOtp,
                    ),
                  ] else if (step == 2) ...[
                    // Read-only email card
                    Card(
                      elevation: 0,
                      color: isDark ? Colors.grey[900] : Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMd),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingMd),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined,
                                color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: AppConstants.paddingSm),
                            Expanded(
                              child: Text(
                                state.email,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMd),
                    CustomTextField(
                      controller: _otpController,
                      labelText: '6-Digit OTP Code',
                      hintText: 'Enter 6-digit OTP code',
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'OTP is required';
                        if (val.trim().length != 6 || int.tryParse(val.trim()) == null) {
                          return 'Enter a valid 6-digit numeric OTP';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Countdown timer view
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              state.countdown > 0
                                  ? 'Resend in ${state.countdown}s'
                                  : 'Code expired',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                        // Resend action
                        TextButton.icon(
                          onPressed: state.countdown > 0
                              ? null
                              : () {
                                  _otpController.clear();
                                  ref
                                      .read(forgotPasswordViewModelProvider.notifier)
                                      .resendOtp();
                                },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Resend Code'),
                          style: TextButton.styleFrom(
                            foregroundColor: state.countdown > 0 ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingLg),
                    CustomButton(
                      text: 'Verify OTP',
                      isLoading: state.status == ForgotPasswordStatus.verifyingOtp,
                      onPressed: _handleVerifyOtp,
                    ),
                  ] else ...[
                    // Step 3: New Passwords
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.stepNumber,
    required this.currentStep,
    required this.isDark,
  });

  final int stepNumber;
  final int currentStep;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isCompleted = currentStep > stepNumber;
    final isActive = currentStep == stepNumber;

    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.grey;
    Color textColor = Colors.grey;

    if (isCompleted) {
      backgroundColor = Colors.green;
      borderColor = Colors.green;
      textColor = Colors.white;
    } else if (isActive) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      borderColor = Theme.of(context).colorScheme.primary;
      textColor = Colors.white;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : Text(
              stepNumber.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? Colors.green : Colors.grey[400],
    );
  }
}
