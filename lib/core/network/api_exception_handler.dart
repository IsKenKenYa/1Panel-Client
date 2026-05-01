import 'package:dio/dio.dart';
import 'network_exceptions.dart';
import '../services/logger/logger_service.dart';

class ApiExceptionHandler {
  const ApiExceptionHandler._();

  static Future<T> safeApiCall<T>(
    Future<T> Function() apiCall, {
    required T fallback,
    String? logContext,
  }) async {
    try {
      return await apiCall();
    } catch (e, stack) {
      if (e is StateError && e.message == 'No API config available') {
        appLogger.iWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'No API config available, returning fallback',
        );
      } else if (e is NetworkException) {
        appLogger.wWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'Network error: ${e.message}',
        );
      } else if (e is DioException) {
        appLogger.wWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'DioException: ${e.message}',
        );
      } else {
        appLogger.eWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'Unexpected API error',
          error: e,
          stackTrace: stack,
        );
      }
      return fallback;
    }
  }

  static Future<T> safeApiCallOrThrow<T>(
    Future<T> Function() apiCall, {
    String? logContext,
  }) async {
    try {
      return await apiCall();
    } catch (e, stack) {
      if (e is StateError && e.message == 'No API config available') {
        appLogger.iWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'No API config available, throwing gentle exception',
        );
        throw const NetworkConnectionException('未配置服务器连接');
      } else if (e is NetworkException) {
        appLogger.wWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'Network error: ${e.message}',
        );
        rethrow;
      } else {
        appLogger.eWithPackage(
          logContext ?? 'core.network.api_exception_handler',
          'Unexpected API error',
          error: e,
          stackTrace: stack,
        );
        rethrow;
      }
    }
  }
}
