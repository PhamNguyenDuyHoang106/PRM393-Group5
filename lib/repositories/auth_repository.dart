import 'package:dio/dio.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/database/db_helper.dart';
import '../core/network/dio_client.dart';
import '../models/user.dart';

class AuthRepository {
  final DbHelper _dbHelper = DbHelper.instance;
  final DioClient _dioClient = DioClient.instance;

  fb.FirebaseAuth? get _firebaseAuth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return fb.FirebaseAuth.instance;
      }
    } catch (_) {}
    return null;
  }

  Future<User> _resolveAndCacheProfile(String uid, String email, String defaultName) async {
    var profile = await _dbHelper.getCachedUser(uid);
    if (profile == null) {
      final profileByEmail = await _dbHelper.getUserByEmail(email);
      if (profileByEmail != null) {
        await _dbHelper.updateUserId(oldId: profileByEmail.id, newId: uid);
        profile = profileByEmail.copyWith(id: uid);
      } else {
        profile = User(
          id: uid,
          name: defaultName,
          email: email,
          role: UserRole.member,
          createdAt: DateTime.now(),
        );
      }
    }
    await _dbHelper.cacheUser(profile);
    return profile;
  }

  Future<User?> login(String email, String password) async {
    try {
      final fbAuth = _firebaseAuth;
      if (fbAuth != null) {
        // 1. Try Firebase Auth client-side login
        final userCredential = await fbAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final token = await fbUser.getIdToken() ?? fbUser.uid;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.authTokenKey, token);

          // Get PostgreSQL database profile (including role) using NestJS /users/me
          User? user;
          try {
            final response = await _dioClient.dio.get(
              '/users/me',
              options: Options(headers: {'Authorization': 'Bearer $token'}),
            );
            final userData = response.data['data'] as Map<String, dynamic>;
            user = User.fromJson(userData);
          } catch (apiError) {
            // Fallback locally using SQLite cached profile
            user = await _resolveAndCacheProfile(
              fbUser.uid,
              email,
              fbUser.displayName ?? email.split('@').first,
            );
          }
          
          await prefs.setString('logged_user_id', user.id);
          await _dbHelper.cacheUser(user);
          return user;
        }
      }

      // 2. Try REST API endpoint (or Mock fallback)
      try {
        final response = await _dioClient.dio.post('/auth/login', data: {
          'email': email,
          'password': password,
        });
        
        final jsonUser = response.data['data'] as Map<String, dynamic>;
        final token = response.data['token'] as String? ?? jsonUser['id'] as String;
        
        final resolvedUser = await _resolveAndCacheProfile(
          jsonUser['id'] as String,
          jsonUser['email'] as String,
          jsonUser['name'] as String,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, token);
        await prefs.setString('logged_user_id', resolvedUser.id);
        return resolvedUser;
      } catch (apiError) {
        // Fallback to Mocking if offline
        if (email.contains('@') && password.length >= 6) {
          final mockId = 'usr_${email.hashCode.abs().toString().substring(0, 4)}';
          final resolvedUser = await _resolveAndCacheProfile(
            mockId,
            email,
            email.split('@').first.toUpperCase(),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.authTokenKey, 'mock_jwt_token_here');
          await prefs.setString('logged_user_id', resolvedUser.id);
          return resolvedUser;
        } else {
          throw Exception('Invalid credentials format');
        }
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('logged_user_id');
      if (userId != null) {
        final cachedUser = await _dbHelper.getCachedUser(userId);
        if (cachedUser != null && cachedUser.email == email) {
          return cachedUser;
        }
      }
      rethrow;
    }
  }

  Future<User?> register(String name, String email, String password) async {
    try {
      // Register through NestJS Auth API first
      try {
        final response = await _dioClient.dio.post('/auth/register', data: {
          'name': name,
          'email': email,
          'password': password,
          'role': UserRole.member,
        });
        
        final jsonUser = response.data['data'] as Map<String, dynamic>;
        
        // Log in to Firebase Auth locally to get authentication state and Token
        final fbAuth = _firebaseAuth;
        String token = jsonUser['id'] as String;
        if (fbAuth != null) {
          try {
            final userCredential = await fbAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            token = await userCredential.user?.getIdToken() ?? token;
          } catch (_) {}
        }

        final user = User.fromJson(jsonUser).copyWith(
          role: UserRole.member,
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, token);
        await prefs.setString('logged_user_id', user.id);
        await _dbHelper.cacheUser(user);
        return user;
      } catch (apiError) {
        // Mock fallback if API fails
        final fbAuth = _firebaseAuth;
        if (fbAuth != null) {
          final userCredential = await fbAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          final fbUser = userCredential.user;
          if (fbUser != null) {
            await fbUser.updateDisplayName(name);
            final user = User(
              id: fbUser.uid,
              name: name,
              email: email,
              role: UserRole.member,
              createdAt: DateTime.now(),
            );
            
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppConstants.authTokenKey, fbUser.uid);
            await prefs.setString('logged_user_id', user.id);
            await _dbHelper.cacheUser(user);
            return user;
          }
        }

        final mockId = 'usr_${email.hashCode.abs().toString().substring(0, 4)}';
        final user = User(
          id: mockId,
          name: name,
          email: email,
          role: UserRole.member,
          createdAt: DateTime.now(),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, 'mock_jwt_token_here');
        await prefs.setString('logged_user_id', user.id);
        await _dbHelper.cacheUser(user);
        return user;
      }
    } catch (e) {
      rethrow;
    }
  }

  String? _currentMockOtp;

  Future<void> sendOtp(String email) async {
    try {
      await _dioClient.dio.post('/auth/send-otp', data: {'email': email});
      await _dbHelper.logOtpRequest(email);
    } catch (apiError) {
      // Mock mode fallback
      final random = Random();
      final otp = (100000 + random.nextInt(900000)).toString();
      _currentMockOtp = otp;
      debugPrint('[AuthRepository] Mock OTP for $email: $otp (Logged for manual testing)');
      await _dbHelper.logOtpRequest(email);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await _dioClient.dio.post('/auth/verify-otp', data: {
        'email': email,
        'otp': otp,
      });
      final isValid = response.data['valid'] as bool? ?? false;
      if (isValid) {
        await _dbHelper.logOtpVerification(email);
      }
      return isValid;
    } catch (apiError) {
      if (_currentMockOtp != null && otp == _currentMockOtp) {
        await _dbHelper.logOtpVerification(email);
        return true;
      }
      return false;
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await _dioClient.dio.post('/auth/reset-password', data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
      await _dbHelper.logPasswordResetCompleted(email);
    } catch (apiError) {
      if (_currentMockOtp == null || otp != _currentMockOtp) {
        throw Exception('Invalid OTP. Reset password failed.');
      }
      
      debugPrint('[AuthRepository] Mock Password Reset completed for $email');
      await _dbHelper.logPasswordResetCompleted(email);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> logout() async {
    final fbAuth = _firebaseAuth;
    if (fbAuth != null) {
      await fbAuth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
    await prefs.remove('logged_user_id');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('logged_user_id');
    if (userId == null) return null;
    return await _dbHelper.getCachedUser(userId);
  }
}
