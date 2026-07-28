import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class JwtInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final Function()? onUnauthorized;

  JwtInterceptor(this._storageService, {this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _storageService.deleteToken();
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
    return handler.next(err);
  }
}
