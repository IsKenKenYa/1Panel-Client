import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/base_component.dart';

void main() {
  test('BaseComponent缓存按TTL过期', () async {
    final component =
        BaseComponent(defaultCacheTtl: const Duration(milliseconds: 1));
    component.setCache<int>('value', 42);
    expect(component.getCache<int>('value'), 42);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(component.getCache<int>('value'), isNull);
  });

  test('BaseComponent权限校验失败抛出异常', () async {
    final component = BaseComponent(
      permissionResolver: (_) async => false,
    );
    await expectLater(
      component.runGuarded(() async => 1, permission: 'apps.read'),
      throwsA(isA<Exception>()),
    );
  });

  test('BaseComponent映射Dio异常信息', () async {
    final component = BaseComponent();
    final error = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );
    await expectLater(
      component.runGuarded(() async {
        throw error;
      }),
      throwsA(
        predicate((e) => e is Exception && e.toString().contains('连接超时')),
      ),
    );
  });
}
