import '../../../core/network/error_mapper.dart';
import '../../../core/storage/storage_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final StorageService _storageService;

  AuthRepositoryImpl(this._remoteDataSource, this._storageService);

  @override
  Future<AppUser> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final res = await _remoteDataSource.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      final user = AppUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      final token = res['token'] as String;
      await _storageService.saveAuthData(token: token);
      return user;
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _remoteDataSource.login(
        email: email,
        password: password,
      );
      final user = AppUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
      final token = res['token'] as String;
      await _storageService.saveAuthData(token: token);
      return user;
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AppUser> getMe() async {
    try {
      return await _remoteDataSource.getMe();
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<AppUser> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      return await _remoteDataSource.updateProfile(
        fullName: fullName,
        phone: phone,
      );
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    await _storageService.clearAuthData();
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }

  @override
  Future<String> uploadAvatar(String filePath) async {
    try {
      return await _remoteDataSource.uploadAvatar(filePath);
    } catch (e) {
      throw ErrorMapper.mapExceptionToFailure(e);
    }
  }
}
