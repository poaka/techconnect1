import '../../../core/network/error_mapper.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';
import 'auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _storageService;

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
      final user = AppUser.fromJson(res['user']);
      final token = res['token'] as String;
      await _storageService.saveToken(token);
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
      final user = AppUser.fromJson(res['user']);
      final token = res['token'] as String;
      await _storageService.saveToken(token);
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
    await _storageService.deleteToken();
  }
}
