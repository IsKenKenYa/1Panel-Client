import 'package:dio/dio.dart';

/// 网络请求异常基类
abstract class NetworkException implements Exception {
  final String message;
  final RequestOptions? requestOptions;
  final int? statusCode;

  const NetworkException(
    this.message, {
    this.requestOptions,
    this.statusCode,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// 网络连接异常
class NetworkConnectionException extends NetworkException {
  const NetworkConnectionException(
    super.message, {
    super.requestOptions,
  });
}

/// HTTP错误异常
class HttpException extends NetworkException {
  const HttpException(
    super.message, {
    super.requestOptions,
    super.statusCode,
  });
}

/// 认证异常
class AuthException extends NetworkException {
  const AuthException(
    super.message, {
    super.requestOptions,
    super.statusCode,
  });
}

/// 服务器异常
class ServerException extends NetworkException {
  const ServerException(
    super.message, {
    super.requestOptions,
    super.statusCode,
  });
}
