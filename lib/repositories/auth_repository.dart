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

  Future<User?> login(String email, String password) async {
    try {
      final fbAuth = _firebaseAuth;
      if (fbAuth != null) {
        // 1. Try Firebase Auth
        final userCredential = await fbAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final user = User(
            id: fbUser.uid,
            name: fbUser.displayName ?? email.split('@').first,
            email: email,
            role: email.toLowerCase().contains('manager') ? 'Manager' : 'Member',
            createdAt: DateTime.now(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.authTokenKey, fbUser.uid);
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
        
        final token = response.data['token'] as String? ?? 'mock_token';
        final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, token);
        await prefs.setString('logged_user_id', user.id);
        await _dbHelper.cacheUser(user);
        return user;
      } catch (apiError) {
        // If API fails (e.g. offline), let's fallback to Mocking for MVP
        // Mock Success Response for MVP if credentials are valid format
        if (email.contains('@') && password.length >= 6) {
          final mockId = 'usr_${email.hashCode.abs().toString().substring(0, 4)}';
          final user = User(
            id: mockId,
            name: email.split('@').first.toUpperCase(),
            email: email,
            role: email.toLowerCase().contains('manager') ? 'Manager' : 'Member',
            createdAt: DateTime.now(),
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.authTokenKey, 'mock_jwt_token_here');
          await prefs.setString('logged_user_id', user.id);
          await _dbHelper.cacheUser(user);
          return user;
        } else {
          throw Exception('Invalid credentials format');
        }
      }
    } catch (e) {
      // Fallback: If offline and error, check if matching user exists in local database
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
      final fbAuth = _firebaseAuth;
      if (fbAuth != null) {
        // 1. Try Firebase Auth
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
            role: email.toLowerCase().contains('manager') ? 'Manager' : 'Member',
            createdAt: DateTime.now(),
          );
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.authTokenKey, fbUser.uid);
          await prefs.setString('logged_user_id', user.id);
          await _dbHelper.cacheUser(user);
          return user;
        }
      }

      // 2. Try REST API endpoint
      try {
        final response = await _dioClient.dio.post('/auth/register', data: {
          'name': name,
          'email': email,
          'password': password,
          'role': email.toLowerCase().contains('manager') ? 'Manager' : 'Member',
        });
        
        final token = response.data['token'] as String? ?? 'mock_token';
        final user = User.fromJson(response.data['user'] as Map<String, dynamic>);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.authTokenKey, token);
        await prefs.setString('logged_user_id', user.id);
        await _dbHelper.cacheUser(user);
        return user;
      } catch (apiError) {
        // Fallback to offline / mock registration
        final mockId = 'usr_${email.hashCode.abs().toString().substring(0, 4)}';
        final user = User(
          id: mockId,
          name: name,
          email: email,
          role: email.toLowerCase().contains('manager') ? 'Manager' : 'Member',
          createdAt: DateTime.now(),
          // Default role is Member, unless email contains manager
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

  Future<void> resetPassword(String email) async {
    final fbAuth = _firebaseAuth;

    if (fbAuth != null) {
      // Firebase is initialized — send real reset email.
      // Let any FirebaseAuthException bubble up so the UI can show the real error
      // (e.g. "user not found", "invalid email", etc.).
      await fbAuth.sendPasswordResetEmail(email: email);
      return;
    }

    // Firebase not configured — try the REST API instead.
    try {
      await _dioClient.dio.post('/auth/reset-password', data: {'email': email});
      return;
    } catch (apiError) {
      // API also unavailable (offline / not deployed).
      // In a real app you would throw here; for MVP we log and return a mock success
      // so the UX is not blocked during development without a backend.
      debugPrint('[AuthRepository] resetPassword: Firebase not configured and API '
          'unreachable. Running in mock mode — no email was actually sent. Error: $apiError');
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
