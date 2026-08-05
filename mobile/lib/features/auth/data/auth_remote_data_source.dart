import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';

class AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSource(this._client);

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    final response = await _client.post(
      '/auth/register',
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.toSnakeCase(),
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<AppUser> getMe() async {
    final response = await _client.get('/auth/me');
    final userData = response.data['data'] as Map<String, dynamic>;
    return AppUser.fromJson(userData);
  }

  Future<AppUser> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    final response = await _client.put(
      '/auth/me',
      data: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
      },
    );
    final userData = response.data['data'] as Map<String, dynamic>;
    return AppUser.fromJson(userData);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/change-password',
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });

    final response = await _client.post(
      '/auth/me/avatar',
      data: formData,
    );
    return response.data['data']['avatarUrl'] as String;
  }
}
