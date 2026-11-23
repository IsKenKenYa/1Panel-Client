import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const legacyListKey = 'api_configs';
  const legacySelectedKey = 'current_api_config_id';
  const serversKey = 'panel_server_directory';
  const brandServersKey = 'kenpanel_servers';

  Map<String, Object?> legacyEntry(String id, String name) => {
        'id': id,
        'name': name,
        'url': 'https://panel.example.com',
        'tokenValidity': 0,
        'allowInsecureTls': false,
        'isDefault': false,
        'lastUsed': '2026-01-01T00:00:00.000',
      };

  group('旧版本服务器列表迁移', () {
    test('旧数组格式被读入并写入新键，随后移除旧键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyListKey: jsonEncode([
          legacyEntry('a', 'Alpha'),
          legacyEntry('b', 'Beta'),
        ]),
        legacySelectedKey: 'b',
      });

      final directory = await ApiConfigManager.getServerDirectory();

      expect(directory.servers.map((s) => s.id), ['a', 'b']);
      expect(directory.servers.map((s) => s.name), ['Alpha', 'Beta']);
      expect(directory.selectedId, 'b');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(serversKey), isNotNull);
      expect(prefs.getString(legacyListKey), isNull);
      expect(prefs.getString(legacySelectedKey), isNull);
    });

    test('旧条目缺少面板类型字段时视为 1Panel 连接', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyListKey: jsonEncode([legacyEntry('a', 'Alpha')]),
      });

      final directory = await ApiConfigManager.getServerDirectory();

      expect(directory.servers.single.panelType, ApiConfig.onePanelType);
      expect(directory.servers.single.revision, isEmpty);
      expect(directory.servers.single.credentialId, isEmpty);
      expect(directory.servers.single.requireOnePanel, returnsNormally);
    });

    test('第二次读取走新键，不再重复迁移', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyListKey: jsonEncode([legacyEntry('a', 'Alpha')]),
      });

      await ApiConfigManager.getServerDirectory();
      final second = await ApiConfigManager.getServerDirectory();

      expect(second.servers.single.id, 'a');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(legacyListKey), isNull);
    });

    test('没有旧数据时返回空目录且不写入新键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final directory = await ApiConfigManager.getServerDirectory();

      expect(directory.servers, isEmpty);
      expect(directory.selectedId, isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(serversKey), isNull);
    });

    test('新格式存在时优先使用新键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        legacyListKey: jsonEncode([legacyEntry('old', 'Legacy')]),
        serversKey: jsonEncode({
          'servers': [
            {...legacyEntry('new', 'Current'), 'panelType': '1panel'},
          ],
          'selectedId': 'new',
        }),
      });

      final directory = await ApiConfigManager.getServerDirectory();

      expect(directory.servers.single.id, 'new');
      expect(directory.selectedId, 'new');
    });

    test('品牌命名键被读入并迁移到新键，随后移除旧键', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        brandServersKey: jsonEncode({
          'servers': [legacyEntry('brand', 'Brand Era')],
          'selectedId': 'brand',
        }),
      });

      final directory = await ApiConfigManager.getServerDirectory();

      expect(directory.servers.single.id, 'brand');
      expect(directory.selectedId, 'brand');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(serversKey), isNotNull);
      expect(prefs.getString(brandServersKey), isNull);
    });
  });

  group('凭据字段默认值', () {
    test('完整字段可往返序列化', () {
      final config = ApiConfig(
        id: 'a',
        name: 'Alpha',
        url: 'https://panel.example.com',
        apiKey: 'secret',
        credentialId: 'cred-1',
        revision: 'rev-1',
      );

      final restored = ApiConfig.fromJson(config.toJson(), apiKey: 'secret');

      expect(restored.panelType, ApiConfig.onePanelType);
      expect(restored.credentialId, 'cred-1');
      expect(restored.revision, 'rev-1');
      expect(restored.apiKey, 'secret');
    });

    test('toJson 不包含凭据原文', () {
      final config = ApiConfig(
        id: 'a',
        name: 'Alpha',
        url: 'https://panel.example.com',
        apiKey: 'secret',
      );

      expect(config.toJson().containsKey('apiKey'), isFalse);
      expect(config.toJson().containsKey('additionalCredentials'), isFalse);
    });
  });

  group('存储凭据解析', () {
    test('正常保存的条目带 apiKey 与 fields', () {
      final secrets = decodeStoredCredential(
        jsonEncode({'apiKey': 'k', 'fields': {'appId': 'x'}}),
      );

      expect(secrets?.apiKey, 'k');
      expect(secrets?.fields['appId'], 'x');
    });

    test('早期迁移只写入 apiKey 时仍可读，fields 为空', () {
      final secrets = decodeStoredCredential(jsonEncode({'apiKey': 'k'}));

      expect(secrets?.apiKey, 'k');
      expect(secrets?.fields, isEmpty);
    });

    test('同一份只含 apiKey 的条目连续解析结果一致', () {
      final raw = jsonEncode({'apiKey': 'k'});

      expect(decodeStoredCredential(raw)?.apiKey, 'k');
      expect(decodeStoredCredential(raw)?.apiKey, 'k');
      expect(decodeStoredCredential(raw)?.fields, isEmpty);
    });

    test('内容不是 JSON 时返回 null', () {
      expect(decodeStoredCredential('not-json'), isNull);
      expect(decodeStoredCredential(''), isNull);
      expect(decodeStoredCredential('12345'), isNull);
    });

    test('缺少 apiKey 时返回 null', () {
      expect(decodeStoredCredential(jsonEncode({'fields': {}})), isNull);
      expect(decodeStoredCredential(jsonEncode({'apiKey': 1})), isNull);
    });

    test('fields 不是对象时回落为空映射', () {
      final secrets = decodeStoredCredential(
        jsonEncode({'apiKey': 'k', 'fields': 'unexpected'}),
      );

      expect(secrets?.apiKey, 'k');
      expect(secrets?.fields, isEmpty);
    });
  });
}
