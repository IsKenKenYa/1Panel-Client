import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_read_handlers.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WinUI3 AI 管理深度通道契约（B3）。
///
/// 契约单一事实源：docs/development/modules/b3_ai_channel_contract.md。
/// 覆盖：写 handler 必填缺失快速失败（不触网）、dispatch 路由、
/// 读 handler 缺参空值惯例。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('createAgentAccountNative（写：渠道账号创建）', () {
    test('缺 provider 快速失败（不发网络请求）', () async {
      final result = await NativeChannelWriteHandlers.createAgentAccountNative(
        {'name': 'acc', 'apiKey': 'sk-x', 'baseURL': 'https://a', 'apiType': 'openai'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('缺 name 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentAccountNative(
        {'provider': 'openai', 'apiKey': 'sk-x', 'baseURL': 'https://a', 'apiType': 'openai'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name'));
    });

    test('缺 apiKey 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentAccountNative(
        {'provider': 'openai', 'name': 'acc', 'baseURL': 'https://a', 'apiType': 'openai'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('apiKey'));
    });

    test('缺 baseURL/apiType 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentAccountNative(
        {'provider': 'openai', 'name': 'acc', 'apiKey': 'sk-x'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });
  });

  group('updateAgentAccountNative / deleteAgentAccountNative（写：账号改/删）', () {
    test('update 缺 id 快速失败', () async {
      final result = await NativeChannelWriteHandlers.updateAgentAccountNative(
        {'name': 'acc', 'baseURL': 'https://a', 'apiType': 'openai'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });

    test('update 缺 name/baseURL/apiType 快速失败', () async {
      final result = await NativeChannelWriteHandlers.updateAgentAccountNative(
        {'id': 1},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });

    test('delete 缺 id 快速失败', () async {
      final result = await NativeChannelWriteHandlers.deleteAgentAccountNative(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });
  });

  group('discoverAgentModels（写：模型发现）', () {
    test('缺 provider/baseURL/apiKey/apiType 快速失败', () async {
      final result = await NativeChannelWriteHandlers.discoverAgentModels(
        {'provider': 'openai'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], isNotNull);
    });
  });

  group('createMcpServerNative（写：MCP 创建）', () {
    test('缺 name 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createMcpServerNative(
        {'command': 'npx -y server'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name'));
    });

    test('缺 command 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createMcpServerNative(
        {'name': 'mcp1'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('command'));
    });

    test('缺 type/url/outputTransport/containerName/port 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createMcpServerNative(
        {'name': 'mcp1', 'command': 'npx -y server'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('port'));
    });
  });

  group('MCP 删/操作/测试/同步（写）', () {
    test('deleteMcpServerNative 缺 id 快速失败', () async {
      final result = await NativeChannelWriteHandlers.deleteMcpServerNative(
        {'id': 'x'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });

    test('operateMcpServerNative 非法 operate 快速失败', () async {
      final result = await NativeChannelWriteHandlers.operateMcpServerNative(
        {'id': 1, 'operate': 'pause'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('Unsupported operation'));
    });

    test('testMcpConnection 缺 id 快速失败', () async {
      final result = await NativeChannelWriteHandlers.testMcpConnection(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });

    test('syncMcpStatus 缺 ids 快速失败', () async {
      final result = await NativeChannelWriteHandlers.syncMcpStatus(
        {'ids': <int>[]},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('ids is required'));
    });
  });

  group('createAgentNative / deleteAgentNative（写：智能体实例建/删）', () {
    test('缺 agentType 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentNative(
        {'name': 'agent1', 'appVersion': '1.0', 'webUIPort': 3000},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('agentType'));
    });

    test('缺 appVersion 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentNative(
        {'agentType': 'openclaw', 'name': 'agent1', 'webUIPort': 3000},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('appVersion'));
    });

    test('缺 webUIPort 快速失败', () async {
      final result = await NativeChannelWriteHandlers.createAgentNative(
        {'agentType': 'openclaw', 'name': 'agent1', 'appVersion': '1.0'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('webUIPort'));
    });

    test('deleteAgentNative 缺 id 快速失败', () async {
      final result = await NativeChannelWriteHandlers.deleteAgentNative(
        {'id': null},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('id is required'));
    });
  });

  group('Ollama 模型加载/关闭/同步（写）', () {
    test('loadOllamaModelNative 缺 name 快速失败', () async {
      final result = await NativeChannelWriteHandlers.loadOllamaModelNative(
        {'name': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name is required'));
    });

    test('closeOllamaModelNative 缺 name 快速失败', () async {
      final result = await NativeChannelWriteHandlers.closeOllamaModelNative(
        {'name': ''},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('name is required'));
    });
  });

  group('dispatch 路由（B3 method → handler）', () {
    test('dispatch 路由 createAgentNative 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createAgentNative',
        {'name': 'agent1'},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 deleteMcpServerNative 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'deleteMcpServerNative',
        {'id': null},
      );

      expect(result['success'], isFalse);
    });

    test('dispatch 路由 loadOllamaModelNative 到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'loadOllamaModelNative',
        {'name': ''},
      );

      expect(result['success'], isFalse);
    });
  });

  group('读 handler 缺参空值惯例（B3）', () {
    test('getAgentAccountModels 缺 accountId 返回空列表', () async {
      final result = await NativeChannelReadHandlers.getAgentAccountModels(
        {'accountId': null},
      );

      expect(result, isEmpty);
    });

    test('getAIBindDomain 缺 appInstallID 返回空映射', () async {
      final result = await NativeChannelReadHandlers.getAIBindDomain(
        <String, dynamic>{},
      );

      expect(result, isEmpty);
    });

    test('getMcpServerDetail 缺 id 返回空映射', () async {
      final result = await NativeChannelReadHandlers.getMcpServerDetail(
        {'id': null},
      );

      expect(result, isEmpty);
    });
  });
}
