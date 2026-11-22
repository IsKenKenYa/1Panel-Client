import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/channel/native_alert_payloads.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/channel/native_channel_write_handlers.dart';
import 'package:onepanel_client/data/models/alert_models.dart';

void main() {
  group('alertRulePayload', () {
    test('启停状态给出可读语义', () {
      final enabled = alertRulePayload(const AlertInfo(
        id: 3,
        type: 'cpu',
        title: 'CPU',
        status: 'Enable',
        method: 'mail',
      ));
      final disabled = alertRulePayload(const AlertInfo(
        id: 4,
        type: 'disk',
        title: 'Disk',
        status: 'Disable',
      ));

      expect(enabled['enabled'], isTrue);
      expect(enabled['statusTone'], 'positive');
      expect(disabled['enabled'], isFalse);
      expect(disabled['statusTone'], 'neutral');
    });
  });

  group('alertLogPayload', () {
    test('标题回落与状态分组', () {
      final log = AlertLog.fromJson(<String, dynamic>{
        'id': 9,
        'status': 'Error',
        'message': 'cpu high',
        'alertDetail': <String, dynamic>{
          'title': 'CPU alert',
          'type': 'cpu',
        },
      });
      final fallback = AlertLog.fromJson(<String, dynamic>{
        'id': 10,
        'status': 'Success',
        'alertRule': <String, dynamic>{
          'title': 'Rule title',
          'type': 'memory',
        },
      });

      final payload = alertLogPayload(log);
      final fallbackPayload = alertLogPayload(fallback);

      expect(payload['title'], 'CPU alert');
      expect(payload['statusTone'], 'negative');
      expect(fallbackPayload['title'], 'Rule title');
      expect(fallbackPayload['type'], 'memory');
      expect(fallbackPayload['statusTone'], 'positive');
    });
  });

  group('alertChannelPayload', () {
    test('渠道能力标记与配置摘要', () {
      final email = alertChannelPayload(const AlertConfigInfo(
        id: 1,
        type: 'email',
        title: 'Mail',
        config: '{}',
      ));
      final custom = alertChannelPayload(const AlertConfigInfo(
        id: 2,
        type: 'custom',
        title: 'Hook',
        config: '{"url":"https://example.test"}',
      ));

      expect(email['isEmail'], isTrue);
      expect(email['isWebhook'], isFalse);
      expect(email['supportsTest'], isTrue);
      expect(custom['isWebhook'], isTrue);
      expect(custom['supportsTest'], isTrue);
      expect(email['enabled'], isTrue);
    });
  });

  group('alertRuleTypePayload', () {
    test('字段依赖由 Dart 侧判定', () {
      final cpu = alertRuleTypePayload('cpu');
      final cronJob = alertRuleTypePayload('cronJob');
      final ssl = alertRuleTypePayload('ssl');

      expect(cpu['needsThreshold'], isTrue);
      expect(cpu['needsInterval'], isTrue);
      expect(cpu['needsCycleDays'], isFalse);
      expect(cronJob['needsCronJob'], isTrue);
      expect(ssl['needsCycleDays'], isTrue);
      expect(ssl['needsCertificate'], isTrue);
    });
  });

  group('alertChannelConfig', () {
    test('邮箱新建包含密码，编辑替换时带 passwordAction', () {
      final created = alertChannelConfig(<String, dynamic>{
        'type': 'email',
        'title': 'Mail',
        'sender': 'a@example.test',
        'userName': 'a',
        'password': 'secret',
        'host': 'smtp.example.test',
        'port': '465',
        'encryption': 'SSL',
        'recipient': 'b@example.test',
      });
      final replaced = alertChannelConfig(<String, dynamic>{
        'type': 'email',
        'title': 'Mail',
        'id': 1,
        'password': 'new-secret',
        'passwordAction': 'replace',
      });
      final kept = alertChannelConfig(<String, dynamic>{
        'type': 'email',
        'title': 'Mail',
        'id': 1,
        'passwordAction': 'keep',
      });

      expect(created['password'], 'secret');
      expect(created['port'], 465);
      expect(created['encryption'], 'SSL');
      expect(replaced['passwordAction'], 'replace');
      expect(replaced['password'], 'new-secret');
      expect(kept['passwordAction'], 'keep');
      expect(kept.containsKey('password'), isFalse);
    });

    test('自定义 Webhook 组装 Body 与 Header 并过滤空键', () {
      final config = alertChannelConfig(<String, dynamic>{
        'type': 'custom',
        'title': 'Hook',
        'webhookUrl': 'https://example.test/hook',
        'preset': 'slack',
        'bodyType': 'form',
        'formPairs': <Map<String, String>>[
          <String, String>{'key': 'title', 'value': '{{title}}'},
          <String, String>{'key': '', 'value': 'ignored'},
        ],
        'headers': <Map<String, String>>[
          <String, String>{'key': 'Authorization', 'value': 'token'},
        ],
      });

      final body = config['body'] as Map<String, dynamic>;
      expect(config['preset'], 'slack');
      expect(config['url'], 'https://example.test/hook');
      expect(body['type'], 'form');
      expect(body['pairs'], hasLength(1));
      expect(config['headers'], hasLength(1));
    });

    test('普通 Webhook 仅提交地址', () {
      final config = alertChannelConfig(<String, dynamic>{
        'type': 'dingTalk',
        'title': 'Ding',
        'webhookUrl': 'https://example.test/ding',
      });

      expect(config, <String, dynamic>{'url': 'https://example.test/ding'});
    });
  });

  group('alertChannelTestRequest', () {
    test('自定义 Webhook 的配置以 JSON 字符串提交', () {
      final request = alertChannelTestRequest(<String, dynamic>{
        'type': 'custom',
        'title': 'Hook',
        'id': 5,
        'webhookUrl': 'https://example.test/hook',
        'preset': 'genericJson',
        'bodyType': 'json',
        'template': '{"text":"{{title}}"}',
      });

      expect(request.type, 'custom');
      expect(request.id, 5);
      expect(request.config, contains('"url":"https://example.test/hook"'));
      expect(request.config, contains('"type":"json"'));
    });

    test('邮箱测试使用独立 SMTP 字段', () {
      final request = alertChannelTestRequest(<String, dynamic>{
        'type': 'email',
        'title': 'Mail',
        'sender': 'a@example.test',
        'userName': 'a',
        'password': 'secret',
        'host': 'smtp.example.test',
        'port': '587',
        'encryption': 'TLS',
        'recipient': 'b@example.test',
      });

      expect(request.host, 'smtp.example.test');
      expect(request.port, 587);
      expect(request.encryption, 'TLS');
      expect(request.password, 'secret');
    });
  });

  group('告警通道入口', () {
    test('创建任务缺少标题或渠道时返回失败结构', () async {
      final noTitle = await NativeChannelWriteHandlers.createAlertRule(
        <String, dynamic>{'type': 'cpu', 'title': ' ', 'methods': <String>['mail']},
      );
      final noMethod = await NativeChannelWriteHandlers.createAlertRule(
        <String, dynamic>{'type': 'cpu', 'title': 'CPU', 'methods': <String>[]},
      );

      expect(noTitle['success'], isFalse);
      expect(noMethod['success'], isFalse);
    });

    test('告警任务 dispatch 路由到写 handler', () async {
      final result = await NativeChannelManager.instance.handleMethodCall(
        'createAlertRule',
        <String, dynamic>{'type': 'cpu', 'title': '', 'methods': <String>[]},
      );

      expect(result['success'], isFalse);
    });

    test('保存渠道缺少类型时返回失败结构', () async {
      final result = await NativeChannelWriteHandlers.saveAlertChannel(
        <String, dynamic>{'type': '', 'title': 'Mail'},
      );

      expect(result['success'], isFalse);
      expect(result['error'], contains('type'));
    });

    test('测试渠道缺少类型时不发起请求', () async {
      final result = await NativeChannelWriteHandlers.testAlertChannel(
        <String, dynamic>{'type': '', 'title': 'Mail'},
      );

      expect(result['success'], isFalse);
    });
  });
}