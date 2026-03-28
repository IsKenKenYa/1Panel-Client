import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/providers/website_config_center_provider.dart';
import 'package:onepanel_client/features/websites/services/website_config_service.dart';
import 'package:onepanel_client/features/websites/services/website_service.dart';

class _FakeWebsiteConfigService extends WebsiteConfigService {
  @override
  Future<FileInfo> getConfigFile({
    required int websiteId,
    String type = 'nginx',
  }) async {
    return const FileInfo(
      name: 'example.conf',
      path: '/etc/nginx/conf.d/example.conf',
      type: 'file',
      size: 0,
    );
  }

  @override
  Future<WebsiteNginxScopeResponse> loadScope({
    required int websiteId,
    required NginxKey scope,
  }) async {
    return const WebsiteNginxScopeResponse();
  }

  @override
  Future<Map<String, dynamic>> getResource(int websiteId) async {
    return const {'cpu': '1'};
  }

  @override
  Future<Map<String, dynamic>> getHttpsConfig(int websiteId) async {
    return const {'enable': true};
  }
}

class _FakeWebsiteService extends WebsiteService {
  @override
  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    return const WebsiteInfo(
      id: 1,
      primaryDomain: 'example.com',
      sitePath: '/opt/www/example',
    );
  }
}

void main() {
  test('WebsiteConfigCenterProvider loads summary data', () async {
    final provider = WebsiteConfigCenterProvider(
      websiteId: 1,
      service: _FakeWebsiteConfigService(),
      websiteService: _FakeWebsiteService(),
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.website?.primaryDomain, 'example.com');
    expect(provider.configFile?.path, '/etc/nginx/conf.d/example.conf');
    expect(provider.httpsSummary?['enable'], isTrue);
  });
}
