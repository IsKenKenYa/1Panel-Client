import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';

void main() {
  final metadata = <String, dynamic>{
    'id': 'local',
    'name': 'Local',
    'url': 'https://localhost',
    'panelType': 'community',
    'revision': '66847b32-03f4-4ac1-91ec-d6db1aea6fcd',
    'credentialId': 'eabe2a4f-362f-4466-bb45-7dc3091d02dd',
    'tokenValidity': 0,
    'allowInsecureTls': false,
    'isDefault': false,
    'lastUsed': '2026-11-21T00:00:00.000',
  };

  test('未注册的面板类型保持原值，不能调用 1Panel 接口', () {
    final config = ApiConfig.fromJson(metadata);
    expect(config.toJson()['panelType'], 'community');
    expect(config.toJson()['revision'], metadata['revision']);
    expect(config.toJson()['credentialId'], metadata['credentialId']);
    expect(config.requireOnePanel, throwsUnsupportedError);
  });

  test('附加凭据保持不可变，修改凭据需要新的连接', () {
    final fields = {'token': 'one'};
    final first = ApiConfig.fromJson(metadata, additionalCredentials: fields);
    fields['token'] = 'two';
    final edited = ApiConfig.fromJson(metadata, additionalCredentials: fields);
    expect(first.additionalCredentials['token'], 'one');
    expect(first.sameConnectionAs(edited), isFalse);
    expect(first.toJson().containsValue('one'), isFalse);
    expect(first.toJson().containsKey('additionalCredentials'), isFalse);
    expect(first.sameConnectionAs(ApiConfig.fromJson(
      {...metadata, 'name': 'Renamed'},
      additionalCredentials: first.additionalCredentials,
    )), isTrue);
  });
}
