import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/data/models/file/file_info.dart';
import 'package:onepanel_client/data/models/openresty_models.dart';
import 'package:onepanel_client/data/models/runtime_models.dart';
import 'package:onepanel_client/data/models/website_models.dart';
import 'package:onepanel_client/features/websites/providers/website_config_provider.dart';
import 'package:onepanel_client/features/websites/services/website_config_service.dart';
import 'package:onepanel_client/features/websites/services/website_service.dart';

class _FakeWebsiteService extends WebsiteService {
  _FakeWebsiteService({
    required this.currentRuntimeId,
    required this.runtimes,
  });

  int? currentRuntimeId;
  final List<RuntimeInfo> runtimes;

  @override
  Future<WebsiteInfo> getWebsiteDetail(int id) async {
    RuntimeInfo? runtime;
    for (final item in runtimes) {
      if (item.id == currentRuntimeId) {
        runtime = item;
        break;
      }
    }
    return WebsiteInfo(
      id: id,
      primaryDomain: 'example.com',
      runtimeId: currentRuntimeId,
      runtimeName: runtime?.name,
    );
  }

  @override
  Future<List<RuntimeInfo>> listPhpRuntimes() async {
    return runtimes;
  }

  void switchRuntime(int? runtimeId) {
    currentRuntimeId = runtimeId;
  }
}

class _FakeWebsiteConfigService extends WebsiteConfigService {
  _FakeWebsiteConfigService({
    required this.onUpdatePhpVersion,
  });

  final void Function(int? runtimeId) onUpdatePhpVersion;

  int updatePhpVersionCallCount = 0;
  int? lastRuntimeId;

  @override
  Future<FileInfo> fetchNginxConfigFile(int websiteId) async {
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
  Future<void> updatePhpVersion({
    required int websiteId,
    int? runtimeId,
  }) async {
    updatePhpVersionCallCount += 1;
    lastRuntimeId = runtimeId;
    onUpdatePhpVersion(runtimeId);
  }
}

void main() {
  test('WebsiteConfigProvider loads php runtime context', () async {
    final websiteService = _FakeWebsiteService(
      currentRuntimeId: 11,
      runtimes: const [
        RuntimeInfo(id: 11, name: 'php-8.2'),
        RuntimeInfo(id: 12, name: 'php-8.3'),
      ],
    );
    final configService = _FakeWebsiteConfigService(
      onUpdatePhpVersion: websiteService.switchRuntime,
    );

    final provider = WebsiteConfigProvider(
      websiteId: 1,
      service: configService,
      websiteService: websiteService,
    );

    await provider.loadAll();

    expect(provider.error, isNull);
    expect(provider.website?.runtimeId, 11);
    expect(provider.website?.runtimeName, 'php-8.2');
    expect(provider.phpRuntimes, hasLength(2));
    expect(provider.selectedRuntimeId, 11);
  });

  test('WebsiteConfigProvider updates php version and refreshes context',
      () async {
    final websiteService = _FakeWebsiteService(
      currentRuntimeId: 11,
      runtimes: const [
        RuntimeInfo(id: 11, name: 'php-8.2'),
        RuntimeInfo(id: 12, name: 'php-8.3'),
      ],
    );
    final configService = _FakeWebsiteConfigService(
      onUpdatePhpVersion: websiteService.switchRuntime,
    );

    final provider = WebsiteConfigProvider(
      websiteId: 1,
      service: configService,
      websiteService: websiteService,
    );

    await provider.loadAll();
    provider.setSelectedRuntimeId(12);
    final ok = await provider.updatePhpVersion();

    expect(ok, isTrue);
    expect(configService.updatePhpVersionCallCount, 1);
    expect(configService.lastRuntimeId, 12);
    expect(provider.website?.runtimeId, 12);
    expect(provider.website?.runtimeName, 'php-8.3');
  });
}
