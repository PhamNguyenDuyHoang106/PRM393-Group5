import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

enum ForgotPasswordStatus {
  idle,
  sendingOtp,
  otpSent,
  verifyingOtp,
  otpVerified,
  updatingPassword,
  success,
  failure,
}

class ForgotPasswordState {
  final ForgotPasswordStatus status;
  final String email;
  final String otp;
  final String? errorMessage;
  final int countdown;
  final bool isNewPasswordVisible;
  final bool isConfirmPasswordVisible;

  ForgotPasswordState({
    required this.status,
    required this.email,
    required this.otp,
    this.errorMessage,
    required this.countdown,
    this.isNewPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStatus? status,
    String? email,
    String? otp,
    String? errorMessage,
    int? countdown,
    bool? isNewPasswordVisible,
    bool? isConfirmPasswordVisible,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      status: status ?? this.status,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      countdown: countdown ?? this.countdown,
      isNewPasswordVisible: isNewPasswordVisible ?? this.isNewPasswordVisible,
      isConfirmPasswordVisible: isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
    );
  }
}

class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  final AuthRepository _authRepository;
  Timer? _timer;

  ForgotPasswordViewModel(this._authRepository)
      : super(ForgotPasswordState(
          status: ForgotPasswordStatus.idle,
          email: '',
          otp: '',
          countdown: 60,
        ));

  void startCountdown() {
    _timer?.cancel();
    state = state.copyWith(countdown: 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdown > 0) {
        state = state.copyWith(countdown: state.countdown - 1);
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> sendOtp(String email) async {
    state = state.copyWith(
      status: ForgotPasswordStatus.sendingOtp,
      email: email,
      clearError: true,
    );
    try {
      await _authRepository.sendOtp(email);
      state = state.copyWith(status: ForgotPasswordStatus.otpSent);
      startCountdown();
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> resendOtp() async {
    if (state.countdown > 0) return;
    await sendOtp(state.email);
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(
      status: ForgotPasswordStatus.verifyingOtp,
      otp: otp,
      clearError: true,
    );
    try {
      final success = await _authRepository.verifyOtp(state.email, otp);
      if (success) {
        state = state.copyWith(status: ForgotPasswordStatus.otpVerified);
        _timer?.cancel();
      } else {
        state = state.copyWith(
          status: ForgotPasswordStatus.otpSent,
          errorMessage: 'Incorrect OTP. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.otpSent,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> resetPassword(String newPassword) async {
    state = state.copyWith(
      status: ForgotPasswordStatus.updatingPassword,
      clearError: true,
    );
    try {
      await _authRepository.resetPassword(state.email, state.otp, newPassword);
      state = state.copyWith(status: ForgotPasswordStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.otpVerified,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> resetPasswordDirect({
    required String email,
    required String newPassword,
  }) async {
    state = state.copyWith(
      status: ForgotPasswordStatus.updatingPassword,
      email: email,
      clearError: true,
    );
    try {
      await _authRepository.resetPassword(email, '', newPassword);
      state = state.copyWith(status: ForgotPasswordStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void toggleNewPasswordVisibility() {
    state = state.copyWith(isNewPasswordVisible: !state.isNewPasswordVisible);
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(isConfirmPasswordVisible: !state.isConfirmPasswordVisible);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
