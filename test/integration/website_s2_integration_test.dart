import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';

import '../core/test_config_manager.dart';

void main() {
  group('S2 Website integration', () {
    test('website update flow executes against configured server when destructive mode is enabled',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.runIntegrationTests ||
          !TestEnvironment.runDestructiveTests) {
        return;
      }

      final api = WebsiteV2Api(
        DioClient(
          baseUrl: TestEnvironment.baseUrl,
          apiKey: TestEnvironment.apiKey,
        ),
      );

      final websites = await api.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty || websites.items.first.id == null) {
        return;
      }

      final detail = await api.getWebsiteDetail(websites.items.first.id!);
      final originalRemark = detail.remark ?? '';

      final updateRequest = {
        'id': detail.id,
        'primaryDomain': detail.primaryDomain,
        'remark': '$originalRemark s2',
        'webSiteGroupId': detail.webSiteGroupId ?? 0,
        'IPV6': detail.ipv6 ?? false,
        'favorite': detail.favorite ?? false,
      };
      await api.updateWebsite(updateRequest);

      await api.updateWebsite({
        ...updateRequest,
        'remark': originalRemark,
      });
    });
  });
}
