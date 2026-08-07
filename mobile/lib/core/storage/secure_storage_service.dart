import 'storage_service.dart';

/// Legacy alias wrapping StorageService (GetStorage) for persistent auth compatibility.
class SecureStorageService {
  final StorageService _storageService;

  SecureStorageService([StorageService? storageService])
      : _storageService = storageService ?? StorageService();

  Future<void> saveToken(String token) async {
    await _storageService.saveAuthData(token: token);
  }

  Future<String?> getToken() async {
    return _storageService.getToken();
  }

  Future<void> deleteToken() async {
    await _storageService.clearAuthData();
  }

  bool isLoggedIn() {
    return _storageService.isLoggedIn();
  }
}
