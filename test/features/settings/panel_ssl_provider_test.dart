import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/config/app_route_entries.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/core/network/interceptors/logging_interceptor.dart';
import 'package:onepanel_client/core/network/interceptors/retry_interceptor.dart';
import 'package:onepanel_client/features/settings/panel_ssl/pages/panel_ssl_page.dart';
import 'package:onepanel_client/shared/security_gateway/utils/security_gateway_utils.dart';

void main() {
  testWidgets('面板 TLS 入口使用专属证书页面', (tester) async {
    await tester.pumpWidget(const SizedBox());
    final entry = buildRouteRegistryEntries()[AppRoutes.panelSsl]!;
    final page = entry.defaultBuilder(
      tester.element(find.byType(SizedBox)),
      const RouteSettings(name: AppRoutes.panelSsl),
    );
    expect(page, isA<PanelSslPage>());
  });

  test('导入 PEM 开启 HTTPS 并保留已有混合访问模式', () {
    for (final mode in ['Enable', 'Disable', 'Mux']) {
      final request = SSLUpdate.importPem(
        currentMode: mode,
        cert: 'cert',
        key: 'key',
      );
      expect(request.toJson(), {
        'ssl': mode == 'Mux' ? 'Mux' : 'Enable',
        'sslType': 'import-paste',
        'cert': 'cert',
        'key': 'key',
      });
    }
    expect(
      () => SSLUpdate.importPem(currentMode: null, cert: '', key: ''),
      throwsFormatException,
    );
  });

  test('不允许将私钥、空响应或网页保存为公开证书', () {
    for (final text in [
      '',
      '<html></html>',
      '-----BEGIN PRIVATE KEY-----',
      '-----BEGIN CERTIFICATE-----\n-----BEGIN PRIVATE KEY-----\n-----END CERTIFICATE-----',
    ]) {
      expect(isPublicCertificatePem(text), isFalse);
    }
  });

  test('认证和证书请求禁止记录正文及自动重试', () {
    final extra = DioClient.sensitiveOptions.extra!;
    expect(extra[LoggingInterceptor.sensitiveBody], isTrue);
    expect(extra[RetryInterceptor.disableRetryKey], isTrue);
  });
}
