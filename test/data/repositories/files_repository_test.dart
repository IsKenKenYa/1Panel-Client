import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/repositories/files_repository.dart';

void main() {
  ApiConfig buildConfig({
    required String id,
    required String url,
    required String apiKey,
  }) {
    return ApiConfig(
      id: id,
      name: id,
      url: url,
      apiKey: apiKey,
    );
  }

  void mockConfigs({
    required List<ApiConfig> configs,
    String? currentConfigId,
  }) {
    final values = <String, Object>{
      'api_configs': jsonEncode(configs.map((e) => e.toJson()).toList()),
    };
    if (currentConfigId != null) {
      values['current_api_config_id'] = currentConfigId;
    }
    SharedPreferences.setMockInitialValues(values);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    ApiClientManager.instance.clearAllClients();
  });

  tearDown(() {
    ApiClientManager.instance.clearAllClients();
  });

  group('FilesRepository', () {
    test('clearCache invalidates cached api instance', () async {
      final server = buildConfig(
        id: 'server-1',
        url: 'https://server-1.test',
        apiKey: 'key-1',
      );
      mockConfigs(configs: <ApiConfig>[server], currentConfigId: server.id);

      final repository = FilesRepository();
      final firstApi = await repository.getApi();
      final cachedApi = await repository.getApi();

      expect(identical(firstApi, cachedApi), isTrue);

      repository.clearCache();

      final refreshedApi = await repository.getApi();
      final refreshedCachedApi = await repository.getApi();

      expect(identical(firstApi, refreshedApi), isFalse);
      expect(identical(refreshedApi, refreshedCachedApi), isTrue);
    });

    test('server switch rebuilds api cache for new config', () async {
      final server1 = buildConfig(
        id: 'server-1',
        url: 'https://server-1.test',
        apiKey: 'key-1',
      );
      final server2 = buildConfig(
        id: 'server-2',
        url: 'https://server-2.test',
        apiKey: 'key-2',
      );

      mockConfigs(
        configs: <ApiConfig>[server1, server2],
        currentConfigId: server1.id,
      );

      final repository = FilesRepository();
      final server1Api = await repository.getApi();
      final server1ApiCached = await repository.getApi();

      expect(identical(server1Api, server1ApiCached), isTrue);

      await ApiConfigManager.setCurrentConfig(server2.id);

      final server2Api = await repository.getApi();
      final server2ApiCached = await repository.getApi();

      expect(identical(server1Api, server2Api), isFalse);
      expect(identical(server2Api, server2ApiCached), isTrue);
    });

    test('throws StateError when no server config exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final repository = FilesRepository();

      await expectLater(
        repository.getApi(),
        throwsA(isA<StateError>()),
      );
    });
  });
}
