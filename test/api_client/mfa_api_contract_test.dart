import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/network/onepanel_auth_headers.dart';

import '../core/test_config_manager.dart';

void main() {
  setUpAll(TestEnvironment.initialize);

  test('v2.5.1 的 API Key 可读取面板配置，账号 MFA 需要面板会话', () async {
    final reason =
        TestEnvironment.skipLiveApi() ?? TestEnvironment.skipNoApiKey();
    if (reason != null) {
      markTestSkipped(reason);
      return;
    }
    final client = Dio(BaseOptions(baseUrl: TestEnvironment.baseUrl));
    addTearDown(() => client.close(force: true));
    Options signedRequest() =>
        Options(headers: OnePanelAuthHeaders.build(TestEnvironment.apiKey));
    final settings = await client.post<Map<String, dynamic>>(
      '/api/v2/core/settings/search',
      options: signedRequest(),
    );
    expect(settings.data?['code'], 200);
    final account = await client.get<Map<String, dynamic>>(
      '/api/v2/core/auth/current',
      options: signedRequest(),
    );
    final mfa = await client.post<Map<String, dynamic>>(
      '/api/v2/core/auth/mfa',
      data: {'title': 'KenPanel', 'interval': 30},
      options: signedRequest(),
    );
    expect(account.data?['code'], 401);
    expect(mfa.data?['code'], 401);
  });
}
