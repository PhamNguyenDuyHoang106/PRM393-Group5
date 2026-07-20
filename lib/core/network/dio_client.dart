import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Base URL for backend API.
/// - Local dev (Android emulator): 10.0.2.2:5000 maps to host machine
/// - Local dev (physical device / web / desktop): localhost:5000
/// - Production: replace with your deployed Railway/Render URL
const String _devBaseUrl = kIsWeb
    ? 'http://localhost:5000/api/v1'
    : 'http://10.0.2.2:5000/api/v1'; // Android emulator → host machine

const String _prodBaseUrl = 'https://smart-task-api.railway.app/api/v1';

// Toggle: true = use local NestJS server, false = production
const bool _useLocalServer = true;

class DioClient {
  DioClient._privateConstructor() {
    final baseUrl = _useLocalServer ? _devBaseUrl : _prodBaseUrl;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString(AppConstants.authTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Map to custom system error types or pass along
          return handler.next(e);
        },
      ),
    );
  }

  static final DioClient instance = DioClient._privateConstructor();
  late final Dio _dio;

  Dio get dio => _dio;
}
