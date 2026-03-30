import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryApiKeyStore implements ApiKeyStore {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }
}

void main() {
  late _InMemoryApiKeyStore keyStore;

  setUp(() {
    keyStore = _InMemoryApiKeyStore();
    ApiConfigManager.setApiKeyStoreForTest(keyStore);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    ApiConfigManager.resetApiKeyStoreForTest();
  });

  test('migrates legacy apiKey from SharedPreferences to secure key store',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'api_configs': jsonEncode(<Map<String, Object>>[
        <String, Object>{
          'id': 's1',
          'name': 'Server 1',
          'url': 'https://example.com',
          'apiKey': 'legacy-key',
          'tokenValidity': 0,
          'allowInsecureTls': false,
          'isDefault': true,
          'lastUsed': DateTime(2026, 3, 31).toIso8601String(),
        }
      ]),
      'current_api_config_id': 's1',
    });

    final firstRead = await ApiConfigManager.getConfigs();
    expect(firstRead, hasLength(1));
    expect(firstRead.first.apiKey, 'legacy-key');

    final prefs = await SharedPreferences.getInstance();
    final persistedRaw = prefs.getString('api_configs');
    expect(persistedRaw, isNotNull);
    final persistedList = jsonDecode(persistedRaw!) as List<dynamic>;
    final persistedMap = Map<String, dynamic>.from(persistedList.first as Map);
    expect(persistedMap.containsKey('apiKey'), isFalse);

    final secondRead = await ApiConfigManager.getConfigs();
    expect(secondRead, hasLength(1));
    expect(secondRead.first.apiKey, 'legacy-key');
  });

  test('saveConfig stores apiKey in key store and strips it from prefs',
      () async {
    final config = ApiConfig(
      id: 's2',
      name: 'Server 2',
      url: 'https://example2.com',
      apiKey: 'secure-key',
      isDefault: true,
    );

    await ApiConfigManager.saveConfig(config);

    final configs = await ApiConfigManager.getConfigs();
    expect(configs, hasLength(1));
    expect(configs.first.apiKey, 'secure-key');

    final prefs = await SharedPreferences.getInstance();
    final persistedRaw = prefs.getString('api_configs');
    expect(persistedRaw, isNotNull);
    final persistedList = jsonDecode(persistedRaw!) as List<dynamic>;
    final persistedMap = Map<String, dynamic>.from(persistedList.first as Map);
    expect(persistedMap.containsKey('apiKey'), isFalse);
  });

  test('deleteConfig removes apiKey from key store', () async {
    final config = ApiConfig(
      id: 's3',
      name: 'Server 3',
      url: 'https://example3.com',
      apiKey: 'delete-me',
      isDefault: true,
    );

    await ApiConfigManager.saveConfig(config);
    await ApiConfigManager.deleteConfig(config.id);

    final configs = await ApiConfigManager.getConfigs();
    expect(configs, isEmpty);
  });
}
