import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/firewall_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/firewall_models.dart';

import '../core/test_config_manager.dart';

void main() {
  group('S2 Firewall integration', () {
    test('firewall operate flow is explicitly gated behind destructive mode',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.runIntegrationTests ||
          !TestEnvironment.runDestructiveTests) {
        return;
      }

      final api = FirewallV2Api(
        DioClient(
          baseUrl: TestEnvironment.baseUrl,
          apiKey: TestEnvironment.apiKey,
        ),
      );

      final response = await api.operateFirewall(
        const FirewallOperation(operation: 'restart'),
      );

      expect(response.statusCode, isNotNull);
    });
  });
}
