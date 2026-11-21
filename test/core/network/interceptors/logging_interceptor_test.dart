import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/interceptors/logging_interceptor.dart';
import 'package:onepanel_client/core/network/interceptors/retry_interceptor.dart';

void main() {
  test('HTTP 诊断省略外部 URL、请求内容和认证字段', () {
    final request = RequestOptions(
      method: 'POST',
      path:
          'https://user:password@host.example/api/v2/test?token=secret#fragment',
      queryParameters: {'filter': 'private'},
      headers: {'Cookie': 'session', 'Authorization': 'credential'},
      data: {'key': 'secret'},
      extra: {RetryInterceptor.retriedKey: true},
    );
    expect(
        LoggingInterceptor.describe(request,
            status: 200,
            businessCode: 401,
            error: DioExceptionType.badResponse),
        'POST HTTP 200 code=401 badResponse retry=1');
  });

  test('面板日志保留模块名称，省略终端会话、数据库名和服务器配置路径参数', () {
    for (final entry in {
      '/api/v2/terminal/sessions/private-session/resize': '/api/v2/terminal',
      '/api/v2/databases/db/private-name': '/api/v2/databases',
      '/api/v2/core/settings/custom-key?token=secret': '/api/v2/core/settings',
    }.entries) {
      expect(
        LoggingInterceptor.describe(RequestOptions(path: entry.key)),
        'GET ${entry.value}',
      );
    }
  });
}
