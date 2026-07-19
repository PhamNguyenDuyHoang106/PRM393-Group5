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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final success = await ref.read(authViewModelProvider.notifier).sendPasswordResetLink(email);
    
    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusLg),
          ),
          title: const Row(
            children: [
              Icon(Icons.mark_email_read_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Email Sent'),
            ],
          ),
          content: Text(
            'We have sent a password reset link to $email. Please check your inbox and follow the instructions to set a new password.',
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
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppConstants.backgroundDark : AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('Forgot Password'),
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
                  const Icon(Icons.mail_lock_rounded, size: 80, color: Color(0xFF4F46E5)),
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
                    'Enter your email address below and we will send you a secure link to reset your password.',
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
                                .read(authViewModelProvider.notifier)
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
                    hintText: 'Enter your registered email',
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
                    text: 'Send Reset Link',
                    isLoading: state.isLoading,
                    onPressed: _handleSendResetLink,
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
