import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/auth_remote_data_source.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user_role.dart';
import 'auth_state.dart';

final Provider<SecureStorageService> secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final Provider<DioClient> dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(
    storageService: storage,
    onUnauthorized: () {
      ref.read(authNotifierProvider.notifier).handleUnauthorized();
    },
  );
});

final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepositoryImpl(
    AuthRemoteDataSource(client),
    storage,
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final SecureStorageService _storageService;

  AuthNotifier(this._repository, this._storageService) : super(const AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storageService.deleteToken();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.login(email: email, password: password);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Échec de la connexion');
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        role: role,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Échec de l\'inscription');
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final user = await _repository.updateProfile(
        fullName: fullName,
        phone: phone,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Échec de la mise à jour');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      debugPrint('[AuthNotifier.changePassword] Requesting password change');
      await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      debugPrint('[AuthNotifier.changePassword] Success');
    } on Failure catch (failure) {
      debugPrint('[AuthNotifier.changePassword] Failure: ${failure.message}');
      throw failure.message;
    } catch (e) {
      debugPrint('[AuthNotifier.changePassword] Exception: $e');
      throw 'Échec du changement de mot de passe';
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      await _repository.uploadAvatar(filePath);
      // Refresh user to get the new avatar URL
      final user = await _repository.getMe();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on Failure catch (failure) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: failure.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Échec de l\'upload de l\'avatar');
    }
  }

  void handleUnauthorized() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthNotifier(repo, storage);
});
