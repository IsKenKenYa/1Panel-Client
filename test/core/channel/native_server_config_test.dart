import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_server_config.dart';
import 'package:onepanel_client/core/config/api_config.dart';

void main() {
  const fields = {
    'panelType': 'community',
    'name': 'Local',
    'url': 'https://localhost',
    'apiKey': 'key',
    'additionalCredentials': {'username': 'account', 'password': 'secret'},
  };

  final config = ApiConfig(
    id: 'local',
    revision: 'opened',
    panelType: 'community',
    name: 'Local',
    url: 'https://localhost',
    apiKey: 'key',
    additionalCredentials: const {'username': 'account', 'password': 'secret'},
  );

  test('原生列表包含编辑版本并隐藏所有凭据', () {
    expect(describeNativeServer(config, isCurrent: true), {
      'id': 'local',
      'revision': 'opened',
      'panelType': 'community',
      'name': 'Local',
      'url': 'https://localhost',
      'isCurrent': true,
    });
  });

  test('编辑名称保留所属面板、密钥和附加凭据', () {
    final renamed = readNativeServerConfig(
      {'revision': config.revision, 'name': 'Renamed', 'url': config.url, 'apiKey': ''},
      id: config.id,
      existing: config,
    );
    expect(renamed.name, 'Renamed');
    expect(renamed.sameConnectionAs(config), isTrue);
    expect(
      () => readNativeServerConfig(
        {...fields, 'revision': config.revision, 'panelType': 'different'},
        id: config.id,
        existing: config,
      ),
      throwsArgumentError,
    );
  });

  test('原生表单缺少版本或提交过期版本会报告编辑冲突', () {
    for (final revision in [null, '', 'outdated']) {
      expect(
        () => readNativeServerConfig(
          {...fields, 'revision': revision},
          id: config.id,
          existing: config,
        ),
        throwsStateError,
      );
    }
  });

  test('更换地址要求提供新地址的凭据', () {
    final changed = {
      'revision': config.revision,
      'name': config.name,
      'url': 'https://example.org',
    };
    expect(
      () => readNativeServerConfig(changed, id: config.id, existing: config),
      throwsArgumentError,
    );
    expect(
      () => readNativeServerConfig({...changed, 'apiKey': 'new'},
          id: config.id, existing: config),
      throwsArgumentError,
    );
    final updated = readNativeServerConfig(
      {...changed, 'apiKey': 'new', 'additionalCredentials': {'token': 'new'}},
      id: config.id,
      existing: config,
    );
    expect(updated.apiKey, 'new');
    expect(updated.additionalCredentials, {'token': 'new'});
  });
}
