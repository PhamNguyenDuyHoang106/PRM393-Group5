import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/database/db_helper.dart';
import '../models/user.dart';

class AuthRepository {
  final DbHelper _dbHelper = DbHelper.instance;

  Future<User?> login(String email, String password) async {
    try {
      // In actual deployment, this calls:
      // final response = await _dioClient.dio.post('/auth/login', data: {'email': email, 'password': password});
      // final token = response.data['token'];
      // final user = User.fromJson(response.data['user']);
      
      // Mock Success Response for MVP
      await Future.delayed(const Duration(seconds: 1));
      final user = User(
        id: 'usr_7719',
        name: 'Hoang Team Lead',
        email: email,
        role: 'Manager',
        createdAt: DateTime.now(),
      );

      // Save token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, 'mock_jwt_token_here');
      await prefs.setString('logged_user_id', user.id);

      // Cache User details locally
      await _dbHelper.cacheUser(user);

      return user;
    } catch (e) {
      // Fallback: If offline, check if matching user exists in local database
      final cachedUser = await _dbHelper.getCachedUser('usr_7719');
      if (cachedUser != null && cachedUser.email == email) {
        return cachedUser;
      }
      rethrow;
    }
  }

  Future<void> logout() async {
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
