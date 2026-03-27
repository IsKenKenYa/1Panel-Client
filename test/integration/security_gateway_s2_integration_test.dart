import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/api/v2/openresty_v2.dart';
import 'package:onepanel_client/api/v2/setting_v2.dart';
import 'package:onepanel_client/api/v2/ssl_v2.dart';
import 'package:onepanel_client/api/v2/website_v2.dart';
import 'package:onepanel_client/core/network/dio_client.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';

import '../core/test_config_manager.dart';

void main() {
  group('S2-3 Security & Gateway integration', () {
    test(
        'reads current security state and replays idempotent updates only when destructive mode is enabled',
        () async {
      await TestEnvironment.initialize();
      if (!TestEnvironment.runIntegrationTests) {
        return;
      }

      final client = DioClient(
        baseUrl: TestEnvironment.baseUrl,
        apiKey: TestEnvironment.apiKey,
      );
      final settingApi = SettingV2Api(client);
      final sslApi = SSLV2Api(client);
      final websiteApi = WebsiteV2Api(client);
      final openrestyApi = OpenRestyV2Api(client);

      final panelInfo = await settingApi.getSSLInfo();
      expect(panelInfo.data, isNotNull);

      final openrestyHttps = await openrestyApi.getOpenRestyHttps();
      expect(openrestyHttps.data, isNotNull);

      final websites = await websiteApi.getWebsites(page: 1, pageSize: 1);
      if (websites.items.isEmpty || websites.items.first.id == null) {
        return;
      }

      final websiteId = websites.items.first.id!;
      final websiteHttps = await websiteApi.getWebsiteHttps(websiteId);
      expect(websiteHttps, isNotNull);
      final websiteSslList = await sslApi.searchWebsiteSSL(
        const WebsiteSSLSearch(page: 1, pageSize: 5),
      );
      expect(websiteSslList.data, isNotNull);

      if (!TestEnvironment.runDestructiveTests) {
        return;
      }

      await openrestyApi.updateOpenRestyHttps(
        OpenrestyDefaultHttpsUpdateRequest(
          operate: openrestyHttps.data?.https == true
              ? OpenrestyDefaultHttpsOperate.enable
              : OpenrestyDefaultHttpsOperate.disable,
          sslRejectHandshake: openrestyHttps.data?.sslRejectHandshake,
        ),
      );

      await websiteApi.updateWebsiteHttps(
        websiteId: websiteId,
        request: WebsiteHttpsUpdateRequest(
          websiteId: websiteId,
          enable: websiteHttps.enable,
          httpConfig: websiteHttps.httpConfig,
          type: 'existed',
          websiteSSLId: websiteHttps.ssl?.id,
          hsts: websiteHttps.hsts,
          hstsIncludeSubDomains: websiteHttps.hstsIncludeSubDomains,
          http3: websiteHttps.http3,
          algorithm: websiteHttps.algorithm,
          sslProtocol: websiteHttps.sslProtocol,
        ),
      );
    });
  });
}
