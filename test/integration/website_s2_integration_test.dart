import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';

import '../core/test_config_manager.dart';

void main() {
  group('S2 Website integration', () {
    test(
        'website update flow executes against configured server when destructive mode is enabled',
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

    test(
        'website domain/config flow reads state and replays reversible domain writes when destructive mode is enabled',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.runIntegrationTests) {
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

      final websiteId = websites.items.first.id!;
      final domains = await api.getWebsiteDomains(websiteId);
      expect(domains, isA<List>());

      final scope = await api.loadWebsiteNginxConfig({
        'scope': NginxKey.indexKey.value,
        'websiteId': websiteId,
      });
      expect(scope, isA<Map<String, dynamic>>());

      if (!TestEnvironment.runDestructiveTests) {
        return;
      }

      final tempDomain =
          's2-${DateTime.now().millisecondsSinceEpoch}.example.com';
      int? createdDomainId;
      try {
        await api.addWebsiteDomains(
          websiteId: websiteId,
          domains: <Map<String, dynamic>>[
            <String, dynamic>{
              'domain': tempDomain,
              'port': 80,
              'ssl': false,
            },
          ],
        );

        final updatedDomains = await api.getWebsiteDomains(websiteId);
        for (final domain in updatedDomains) {
          if (domain.domain == tempDomain && domain.id != null) {
            createdDomainId = domain.id;
            break;
          }
        }
        expect(createdDomainId, isNotNull);
      } finally {
        if (createdDomainId != null) {
          await api.deleteWebsiteDomain(id: createdDomainId);
        }
      }
    });
  });
}
