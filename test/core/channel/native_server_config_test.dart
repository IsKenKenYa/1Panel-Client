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
      'tokenValidity': 0,
      'allowInsecureTls': false,
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

  test('表单可写入接口密钥有效期与忽略证书校验', () {
    final created = readNativeServerConfig(
      {
        'panelType': '1panel',
        'name': 'Panel',
        'url': 'https://panel.example.com',
        'apiKey': 'key',
        'tokenValidity': 120,
        'allowInsecureTls': true,
      },
      id: 'panel',
    );
    expect(created.tokenValidity, 120);
    expect(created.allowInsecureTls, isTrue);

    final kept = readNativeServerConfig(
      {
        'revision': config.revision,
        'name': config.name,
        'url': config.url,
        'apiKey': '',
      },
      id: config.id,
      existing: config,
    );
    expect(kept.tokenValidity, config.tokenValidity);
    expect(kept.allowInsecureTls, config.allowInsecureTls);
  });

  test('1Panel 旧凭据缺失时留空密钥不能保存', () {
    final saved = ApiConfig(
      id: 'panel',
      revision: 'opened',
      name: 'Panel',
      url: 'https://panel.example.com',
      apiKey: '',
    );
    expect(
      () => readNativeServerConfig(
        {
          'panelType': '1panel',
          'revision': saved.revision,
          'name': saved.name,
          'url': saved.url,
          'apiKey': '',
        },
        id: saved.id,
        existing: saved,
      ),
      throwsArgumentError,
    );
    final typed = readNativeServerConfig(
      {
        'panelType': '1panel',
        'revision': saved.revision,
        'name': saved.name,
        'url': saved.url,
        'apiKey': 'retyped',
      },
      id: saved.id,
      existing: saved,
    );
    expect(typed.apiKey, 'retyped');
  });

  test('有效期超出范围或类型错误时拒绝保存', () {
    expect(
      () => readNativeServerConfig(
        {
          'panelType': '1panel',
          'name': 'Panel',
          'url': 'https://panel.example.com',
          'apiKey': 'key',
          'tokenValidity': 10000,
        },
        id: 'panel',
      ),
      throwsArgumentError,
    );
    expect(
      () => readNativeServerConfig(
        {
          'panelType': '1panel',
          'name': 'Panel',
          'url': 'https://panel.example.com',
          'apiKey': 'key',
          'allowInsecureTls': 'yes',
        },
        id: 'panel',
      ),
      throwsArgumentError,
    );
  });
}
