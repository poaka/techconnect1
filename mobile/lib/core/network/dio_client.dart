import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage_service.dart';
import 'jwt_interceptor.dart';

const bool useLocalBackend = true; // Set to true to test locally, false to test Render

String get defaultApiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) return envUrl;

  if (kDebugMode && useLocalBackend) {
    // Uses 127.0.0.1 along with ADB reverse port forwarding.
    // This securely bypasses Windows Firewall and IP changes.
    return 'http://127.0.0.1:5000/api';
  }

  // Release mode / Production URL on Render
  return 'https://fixerpro2371-api.onrender.com/api';
}

class DioClient {
  late final Dio _dio;

  DioClient({
    String? baseUrl,
    required SecureStorageService storageService,
    Function()? onUnauthorized,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? defaultApiBaseUrl,
        connectTimeout: const Duration(seconds: 15), // Increased timeout for slow networks
        receiveTimeout: const Duration(seconds: 45), // Increased to allow image uploads to complete
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add JWT Interceptor
    _dio.interceptors.add(
      JwtInterceptor(storageService, onUnauthorized: onUnauthorized),
    );

    // Add Network Logging Interceptor
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: false,
      responseBody: true,
      error: true,
      logPrint: (obj) => developer.log('[Dio] $obj', name: 'Network'),
    ));

    // Add Automatic Connection Error Fallback Interceptor (10.0.2.2 <-> 127.0.0.1)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout) {
            
            // Prevent infinite fallback loop
            if (error.requestOptions.extra['isFallback'] == true) {
              return handler.next(error);
            }

            final currentBase = _dio.options.baseUrl;
            String? fallbackBase;

            if (currentBase.contains('10.0.2.2')) {
              fallbackBase = currentBase.replaceAll('10.0.2.2', '127.0.0.1');
            } else if (currentBase.contains('127.0.0.1')) {
              fallbackBase = currentBase.replaceAll('127.0.0.1', '10.0.2.2');
            } else if (currentBase.contains('localhost')) {
              fallbackBase = currentBase.replaceAll('localhost', '10.0.2.2');
            }

            if (fallbackBase != null && fallbackBase != currentBase) {
              try {
                // Update primary baseUrl for all subsequent requests
                _dio.options.baseUrl = fallbackBase;

                final opts = error.requestOptions;
                opts.baseUrl = fallbackBase;
                opts.extra['isFallback'] = true; // Mark as fallback to prevent infinite loop
                
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // Fallback failed, pass original error downstream
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
