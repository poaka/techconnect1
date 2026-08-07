import 'package:get_storage/get_storage.dart';

class StorageService {
  static const String tokenKey = 'jwt_auth_token';
  static const String isLoggedInKey = 'is_logged_in';

  final GetStorage _box;

  StorageService([GetStorage? box]) : _box = box ?? GetStorage();

  /// Saves the authentication token and login state flag to GetStorage upon successful authentication.
  Future<void> saveAuthData({required String token}) async {
    await _box.write(tokenKey, token);
    await _box.write(isLoggedInKey, true);
  }

  /// Retrieves the saved JWT authentication token from GetStorage.
  String? getToken() {
    return _box.read<String>(tokenKey);
  }

  /// Returns true if a valid login flag and token exist in GetStorage.
  bool isLoggedIn() {
    final bool? loggedIn = _box.read<bool>(isLoggedInKey);
    final String? token = getToken();
    return (loggedIn == true) && (token != null && token.isNotEmpty);
  }

  /// Removes the authentication token and login state flag from GetStorage upon logout.
  Future<void> clearAuthData() async {
    await _box.remove(tokenKey);
    await _box.remove(isLoggedInKey);
  }
}
