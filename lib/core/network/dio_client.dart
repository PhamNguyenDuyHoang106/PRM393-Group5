import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class DioClient {
  DioClient._privateConstructor() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://smart-task-api.railway.app/api/v1', // Mock or deployed URL
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
