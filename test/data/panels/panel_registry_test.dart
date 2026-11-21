import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/panels/one_panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_adapter.dart';
import 'package:onepanel_client/data/panels/panel_registry.dart';

void main() {
  ApiConfig config(String id, {String key = '', String? type}) => ApiConfig(
        id: id,
        name: id,
        url: 'https://localhost',
        apiKey: key,
        panelType: type ?? ApiConfig.onePanelType,
      );

  late PanelRegistry registry;
  setUp(() => registry = PanelRegistry([const OnePanelAdapter()]));
  tearDown(() => registry.clear());

  test('1Panel 会话声明连接测试和指标读取权限', () async {
    final access = await registry.sessionFor(config('a')).loadCapabilities();
    expect(
        access, {'connection': PanelAccess.read, 'metrics': PanelAccess.read});
  });

  test('已打开的连接可直接用目录版本获取，更新名称后沿用同一会话', () async {
    final saved = ApiConfig.fromJson(
      {...config('a').toJson(), 'revision': '1'},
      apiKey: 'key',
    );
    final session = registry.sessionFor(saved);
    expect(await registry.savedSessionFor(ApiConfig.fromJson(saved.toJson())),
        same(session));
    final renamed = ApiConfig.fromJson(
      {...saved.toJson(), 'revision': '2', 'name': 'Renamed'},
      apiKey: saved.apiKey,
    );
    expect(registry.sessionFor(renamed), same(session));
    expect(await registry.savedSessionFor(ApiConfig.fromJson(renamed.toJson())),
        same(session));
  });

  test('相同连接复用会话，服务器和凭据变化各自隔离', () {
    final original = registry.sessionFor(config('a'));
    final other = registry.sessionFor(config('b'));
    expect(registry.sessionFor(config('a')), same(original));
    expect(other, isNot(same(original)));
    final updated = registry.sessionFor(config('a', key: 'changed'));
    expect(updated, isNot(same(original)));
    registry.release('a');
    expect(
      registry.sessionFor(config('a', key: 'changed')),
      isNot(same(updated)),
    );
    expect(registry.sessionFor(config('b')), same(other));
  });

  test('重复注册和未知面板类型被拒绝', () {
    expect(() => registry.register(const OnePanelAdapter()), throwsStateError);
    expect(registry.supports('unknown'), isFalse);
    expect(() => registry.sessionFor(config('a', type: 'unknown')),
        throwsUnsupportedError);
  });

  test('测试表单连接时独立创建客户端并保留正式连接', () {
    final manager = ApiClientManager.instance;
    final adapter = OnePanelAdapter(clientManager: manager);
    final saved = adapter.open(config('a'));
    final draft = adapter.open(config('a', key: 'changed'), temporary: true);
    addTearDown(saved.close);
    expect(draft.client, isNot(same(saved.client)));
    draft.close();
    expect(manager.getClientForConfig(config('a')), same(saved.client));
    expect(() => manager.getClientForConfig(config('a', type: 'other')),
        throwsUnsupportedError);
  });
}
