import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';

void main() {
  test('服务器元数据往返保存并保持凭据分离', () {
    final config = ApiConfig(
      id: 'server-a',
      name: 'Panel',
      url: 'https://panel.example.com',
      apiKey: 'test-key',
      revision: 'revision-a',
      credentialId: 'credential-a',
    );
    final json = config.toJson();
    final restored = ApiConfig.fromJson(json, apiKey: config.apiKey);

    expect(restored.sameConnectionAs(config), isTrue);
    expect(restored.revision, 'revision-a');
    expect(restored.credentialId, 'credential-a');
    expect(json.containsKey('apiKey'), isFalse);
    expect(json.containsKey('additionalCredentials'), isFalse);
  });

  test('其他面板类型保持独立', () {
    final config = ApiConfig(
      id: 'server-a',
      name: 'Panel',
      url: 'https://panel.example.com',
      panelType: 'other-panel',
      apiKey: 'test-key',
    );

    expect(ApiConfig.fromJson(config.toJson()).panelType, 'other-panel');
    expect(config.requireOnePanel, throwsUnsupportedError);
  });
}
