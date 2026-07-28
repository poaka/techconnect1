import 'package:dio/dio.dart';
import '../error/failures.dart';
import 'api_exception.dart';

abstract class ErrorMapper {
  static Failure mapDioErrorToFailure(DioException dioError) {
    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.receiveTimeout ||
        dioError.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }

    if (dioError.response != null && dioError.response?.data != null) {
      final data = dioError.response?.data;
      if (data is Map<String, dynamic> && data.containsKey('error')) {
        final errObj = data['error'];
        if (errObj is Map<String, dynamic>) {
          final code = errObj['code']?.toString() ?? 'UNKNOWN_ERROR';
          final message = errObj['message']?.toString() ?? 'Une erreur s\'est produite.';
          final details = errObj['details'];

          if (code == 'UNAUTHORIZED' || code == 'FORBIDDEN') {
            return AuthFailure(message, code: code, details: details);
          } else if (code == 'BAD_REQUEST' || code == 'CONFLICT') {
            return ValidationFailure(message, code: code, details: details);
          }
          return ServerFailure.named(message, code: code, details: details);
        }
      }
    }

    return ServerFailure.named(
      dioError.message ?? 'Erreur de communication avec le serveur.',
      code: 'HTTP_${dioError.response?.statusCode ?? 500}',
    );
  }

  static Failure mapExceptionToFailure(Object exception) {
    if (exception is ApiException) {
      if (exception.code == 'UNAUTHORIZED' || exception.code == 'FORBIDDEN') {
        return AuthFailure(exception.message, code: exception.code, details: exception.details);
      }
      if (exception.code == 'BAD_REQUEST' || exception.code == 'CONFLICT') {
        return ValidationFailure(exception.message, code: exception.code, details: exception.details);
      }
      return ServerFailure.named(exception.message, code: exception.code, details: exception.details);
    }
    if (exception is DioException) {
      return mapDioErrorToFailure(exception);
    }
    return ServerFailure(exception.toString());
  }
}
