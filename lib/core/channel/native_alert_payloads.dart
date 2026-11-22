import 'dart:convert';

import '../../data/models/alert_models.dart';
import '../../features/alert/alert_types.dart';

/// 告警中心通道返回结构。
///
/// 告警状态语义、渠道能力、规则字段依赖、配置 JSON 组装与测试请求组装
/// 都在 Dart 侧完成，原生界面只消费归一化字段。

Map<String, Object?> alertRulePayload(AlertInfo rule) {
  final enabled = rule.status != 'Disable';
  return <String, Object?>{
    'id': rule.id,
    'type': rule.type,
    'title': rule.title,
    'taskName': rule.taskName,
    'project': rule.project,
    'status': rule.status,
    'statusTone': enabled ? 'positive' : 'neutral',
    'enabled': enabled,
    'cycle': rule.cycle,
    'count': rule.count,
    'interval': rule.interval,
    'sendCount': rule.sendCount,
    'sendMethod': rule.sendMethod,
    'method': rule.method,
    'advancedParams': rule.advancedParams,
    'alertTriggerMode': rule.alertTriggerMode,
    'createdAt': rule.createdAt,
    'updatedAt': rule.updatedAt,
  };
}

Map<String, Object?> alertLogPayload(AlertLog log) {
  final title = log.alertDetail.title.isNotEmpty
      ? log.alertDetail.title
      : log.alertRule.title;
  final type = log.alertDetail.type.isNotEmpty
      ? log.alertDetail.type
      : log.alertRule.type;
  final normalized = log.status.toLowerCase();
  final tone = normalized == 'success'
      ? 'positive'
      : (normalized == 'error' || normalized == 'failed' ? 'negative' : 'neutral');
  return <String, Object?>{
    'id': log.id,
    'alertId': log.alertId,
    'title': title,
    'type': type,
    'message': log.message,
    'status': log.status,
    'statusTone': tone,
    'method': log.method,
    'count': log.count,
    'createdAt': log.createdAt,
  };
}

Map<String, Object?> alertChannelPayload(AlertConfigInfo channel) {
  final enabled = channel.status != 'Disable';
  final config = channel.config;
  return <String, Object?>{
    'id': channel.id,
    'type': channel.type,
    'title': channel.title,
    'config': config,
    'configSummary': config.length <= 160 ? config : '${config.substring(0, 160)}…',
    'status': channel.status,
    'enabled': enabled,
    'statusTone': enabled ? 'positive' : 'neutral',
    'isEmail': AlertChannelTypes.isEmail(channel.type),
    'isWebhook': AlertChannelTypes.isWebhook(channel.type),
    'supportsTest': AlertChannelTypes.supportsTest(channel.type),
    'createdAt': channel.createdAt,
  };
}

/// 规则表单的类型选项与字段依赖。
Map<String, Object?> alertRuleTypePayload(String type) {
  return <String, Object?>{
    'type': type,
    'needsCycleDays': AlertRuleTypes.needsCycleDays(type),
    'needsThreshold': AlertRuleTypes.needsThreshold(type),
    'needsInterval': AlertRuleTypes.needsInterval(type),
    'needsDisk': AlertRuleTypes.needsDisk(type),
    'needsClam': AlertRuleTypes.needsClam(type),
    'needsCronJob': AlertRuleTypes.needsCronJob(type),
    'needsCertificate': AlertRuleTypes.needsCertificate(type),
    'needsWebsite': AlertRuleTypes.needsWebsite(type),
  };
}

Map<String, Object?> alertChannelTypePayload(String type) {
  return <String, Object?>{
    'type': type,
    'isEmail': AlertChannelTypes.isEmail(type),
    'isWebhook': AlertChannelTypes.isWebhook(type),
    'supportsTest': AlertChannelTypes.supportsTest(type),
    'isCustom': type == AlertChannelTypes.custom,
  };
}

/// 表单选项：目标列表、规则类型、渠道类型、加密方式与 Webhook 预设。
Map<String, Object?> alertOptionsPayload({
  required List<AlertDisk> disks,
  required List<AlertClam> clams,
  required List<AlertCronJob> cronJobs,
}) {
  return <String, Object?>{
    'disks': disks
        .map((disk) => <String, Object?>{
              'path': disk.path,
              'type': disk.type,
              'device': disk.device,
              'usedPercent': disk.usedPercent,
            })
        .toList(growable: false),
    'clams': clams
        .map((clam) => <String, Object?>{
              'name': clam.name,
              'status': clam.status,
              'path': clam.path,
            })
        .toList(growable: false),
    'cronJobs': cronJobs
        .map((task) => <String, Object?>{
              'name': task.name,
              'type': task.type,
              'status': task.status,
            })
        .toList(growable: false),
    'ruleTypes': AlertRuleTypes.values
        .map(alertRuleTypePayload)
        .toList(growable: false),
    'channelTypes': AlertChannelTypes.values
        .map(alertChannelTypePayload)
        .toList(growable: false),
    'encryptions': const <String>['NONE', 'SSL', 'TLS'],
    'webhookPresets': AlertWebhookPresets.values
        .map((preset) => <String, Object?>{
              'key': preset,
              'template': AlertWebhookPresets.template(preset),
            })
        .toList(growable: false),
  };
}

/// 把原生表单字段组装为渠道配置 JSON 所需的结构。
Map<String, dynamic> alertChannelConfig(Map arguments) {
  final type = (arguments['type'] as String? ?? AlertChannelTypes.email).trim();
  final title = (arguments['title'] as String? ?? '').trim();
  if (AlertChannelTypes.isEmail(type)) {
    final config = <String, dynamic>{
      'displayName': title,
      'sender': (arguments['sender'] as String? ?? '').trim(),
      'userName': (arguments['userName'] as String? ?? '').trim(),
      'host': (arguments['host'] as String? ?? '').trim(),
      'port': int.tryParse('${arguments['port'] ?? 465}') ?? 465,
      'encryption': (arguments['encryption'] as String? ?? 'NONE').trim(),
      'recipient': (arguments['recipient'] as String? ?? '').trim(),
    };
    final passwordAction =
        (arguments['passwordAction'] as String? ?? '').trim();
    if (passwordAction.isNotEmpty) {
      config['passwordAction'] = passwordAction;
      if (passwordAction == 'replace') {
        config['password'] = arguments['password'] as String? ?? '';
      }
    } else {
      config['password'] = arguments['password'] as String? ?? '';
    }
    return config;
  }
  if (type == AlertChannelTypes.custom) {
    final bodyType = (arguments['bodyType'] as String? ?? 'json').trim();
    return <String, dynamic>{
      'preset': (arguments['preset'] as String? ?? 'genericJson').trim(),
      'url': (arguments['webhookUrl'] as String? ?? '').trim(),
      'body': <String, dynamic>{
        'type': bodyType,
        if (bodyType == 'json' || bodyType == 'text')
          'template': arguments['template'] as String? ?? '',
        if (bodyType == 'form') 'pairs': _pairs(arguments['formPairs']),
      },
      'headers': _pairs(arguments['headers']),
    };
  }
  return <String, dynamic>{
    'url': (arguments['webhookUrl'] as String? ?? '').trim(),
  };
}

/// 把原生表单字段组装为渠道测试请求。
AlertConfigTest alertChannelTestRequest(Map arguments) {
  final type = (arguments['type'] as String? ?? AlertChannelTypes.email).trim();
  final title = (arguments['title'] as String? ?? '').trim();
  final id = int.tryParse('${arguments['id'] ?? ''}');
  if (AlertChannelTypes.isEmail(type)) {
    final password = (arguments['password'] as String? ?? '').trim();
    return AlertConfigTest(
      type: type,
      displayName: title,
      sender: (arguments['sender'] as String? ?? '').trim(),
      userName: (arguments['userName'] as String? ?? '').trim(),
      password: password.isEmpty ? null : password,
      host: (arguments['host'] as String? ?? '').trim(),
      port: int.tryParse('${arguments['port'] ?? ''}'),
      encryption: (arguments['encryption'] as String? ?? 'NONE').trim(),
      recipient: (arguments['recipient'] as String? ?? '').trim(),
    );
  }
  return AlertConfigTest(
    type: type,
    config: jsonEncode(alertChannelConfig(arguments)),
    id: id,
    displayName: title,
  );
}

Map<String, Object?> alertConfigTestResultPayload(AlertConfigTestResult result) {
  return <String, Object?>{
    'success': result.success,
    'statusCode': result.statusCode,
    'duration': result.duration,
    'message': result.message,
    'response': result.response,
  };
}

List<Map<String, String>> _pairs(Object? value) {
  if (value is! List) return const <Map<String, String>>[];
  return value
      .whereType<Map>()
      .map((pair) => <String, String>{
            'key': '${pair['key'] ?? ''}'.trim(),
            'value': '${pair['value'] ?? ''}',
          })
      .where((pair) => pair['key']!.isNotEmpty)
      .toList(growable: false);
}