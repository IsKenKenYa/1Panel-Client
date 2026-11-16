import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/network_exceptions.dart';
import 'package:onepanel_client/core/utils/error_message_utils.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('ErrorMessageUtils', () {
    test('normalize strips Exception prefix', () {
      expect(
        ErrorMessageUtils.normalize(Exception('请求失败')),
        '请求失败',
      );
    });

    test('normalize uses NetworkException message', () {
      const error = HttpException('服务内部错误', statusCode: 500);
      expect(ErrorMessageUtils.normalize(error), '服务内部错误');
    });

    test('truncateForToast shortens long messages', () {
      final long = 'a' * 150;
      final truncated = ErrorMessageUtils.truncateForToast(long, maxLength: 120);
      expect(truncated.length, 120);
      expect(truncated.endsWith('…'), isTrue);
    });

    test('truncateForToast keeps short messages unchanged', () {
      expect(ErrorMessageUtils.truncateForToast('short'), 'short');
    });

    test('userFacingMessage combines normalize and truncate', () {
      final message = ErrorMessageUtils.userFacingMessage(
        NetworkConnectionException('连接超时'),
        maxLength: 50,
      );
      expect(message, '连接超时');
    });

    group('DioException handling', () {
      RequestOptions requestOptions() => RequestOptions(path: '/test');

      test('connectionTimeout returns timeout message', () {
        final error = DioException(
          type: DioExceptionType.connectionTimeout,
          requestOptions: requestOptions(),
        );
        expect(ErrorMessageUtils.normalize(error), 'Connection timed out');
      });

      test('connectionError returns connection failed message', () {
        final error = DioException(
          type: DioExceptionType.connectionError,
          requestOptions: requestOptions(),
        );
        expect(ErrorMessageUtils.normalize(error), 'Network connection failed');
      });

      test('badResponse 401 returns Unauthorized', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: requestOptions(),
          response: Response(
            requestOptions: requestOptions(),
            statusCode: 401,
          ),
        );
        expect(ErrorMessageUtils.normalize(error), 'Unauthorized');
      });

      test('badResponse 500 returns Server error', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: requestOptions(),
          response: Response(
            requestOptions: requestOptions(),
            statusCode: 500,
          ),
        );
        expect(ErrorMessageUtils.normalize(error), 'Server error (500)');
      });

      test('badResponse with server message uses it', () {
        final error = DioException(
          type: DioExceptionType.badResponse,
          requestOptions: requestOptions(),
          response: Response(
            requestOptions: requestOptions(),
            statusCode: 400,
            data: {'message': 'Invalid parameter'},
          ),
        );
        expect(ErrorMessageUtils.normalize(error), 'Invalid parameter');
      });

      test('cancel returns cancelled message', () {
        final error = DioException(
          type: DioExceptionType.cancel,
          requestOptions: requestOptions(),
        );
        expect(ErrorMessageUtils.normalize(error), 'Request cancelled');
      });
    });

    group('localizeMessage', () {
      final zh = lookupAppLocalizations(const Locale('zh'));

      test('剥离异常类型前缀并翻译资源不存在', () {
        // 回归：Provider 保存 e.toString() 后展示层未剥离异常类型，
        // 详情页错误文案曾显示 "NetworkException: 请求失败: 服务错误: ..."。
        expect(
          ErrorMessageUtils.localizeMessage(
            'NetworkException: 请求失败: 服务错误: 无法找到请求的资源 <no value>',
            zh,
          ),
          zh.commonErrorNotFound,
        );
      });

      test('剥离异常类型前缀后保留上游原始描述', () {
        expect(
          ErrorMessageUtils.localizeMessage(
            'NetworkException: 当前面板版本不支持该功能',
            zh,
          ),
          '当前面板版本不支持该功能',
        );
      });

      test('剥离异常类型前缀后命中网络错误文案', () {
        expect(
          ErrorMessageUtils.localizeMessage('Exception: 网络连接失败', zh),
          zh.commonErrorNetwork,
        );
      });

      test('数据库容器未运行映射为启动指引', () {
        expect(
          ErrorMessageUtils.localizeMessage(
            '服务错误: Error response from daemon: container 8cbceb1ad568 is not running',
            zh,
          ),
          zh.databaseContainerNotRunning,
        );
      });
    });
  });
}
