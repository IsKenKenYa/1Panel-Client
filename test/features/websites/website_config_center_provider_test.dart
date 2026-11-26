import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/providers/website_config_center_provider.dart';
import 'package:onepanel_client/features/websites/services/website_config_service.dart';
import 'package:onepanel_client/data/repositories/website_repository.dart';

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
  Future<List<WebsiteResource>> getResource(int websiteId) async {
    return const [WebsiteResource(id: 16, type: 'runtime', name: 'PHP')];
  }

  @override
  Future<Map<String, dynamic>> getHttpsConfig(int websiteId) async {
    return const {'enable': true};
  }
}

class _FakeWebsiteRepository extends WebsiteRepository {
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
      websiteRepository: _FakeWebsiteRepository(),
    );

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.website?.primaryDomain, 'example.com');
    expect(provider.configFile?.path, '/etc/nginx/conf.d/example.conf');
    expect(provider.resource.single.name, 'PHP');
    expect(provider.httpsSummary?['enable'], isTrue);
  });
}
