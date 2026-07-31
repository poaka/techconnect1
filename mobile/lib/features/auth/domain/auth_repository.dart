import 'app_user.dart';
import 'user_role.dart';

abstract class AuthRepository {
  Future<AppUser> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  });

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<AppUser> getMe();
  Future<AppUser> updateProfile({
    String? fullName,
    String? phone,
  });

  Future<void> logout();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
