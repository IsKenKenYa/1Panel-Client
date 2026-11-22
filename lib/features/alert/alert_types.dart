import 'package:onepanel_client/core/i18n/l10n_x.dart';
import 'package:onepanel_client/data/models/alert_models.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

/// 上游告警任务类型取值（`xpack.alert` 类型集）。
class AlertRuleTypes {
  const AlertRuleTypes._();

  static const String panelPwdEndTime = 'panelPwdEndTime';
  static const String panelLogin = 'panelLogin';
  static const String licenseException = 'licenseException';
  static const String nodeException = 'nodeException';
  static const String panelUpdate = 'panelUpdate';
  static const String sshLogin = 'sshLogin';
  static const String ssl = 'ssl';
  static const String siteEndTime = 'siteEndTime';
  static const String cpu = 'cpu';
  static const String memory = 'memory';
  static const String disk = 'disk';
  static const String load = 'load';
  static const String clams = 'clams';
  static const String cronJob = 'cronJob';

  static const List<String> values = <String>[
    panelPwdEndTime,
    panelLogin,
    sshLogin,
    ssl,
    siteEndTime,
    cpu,
    memory,
    disk,
    load,
    clams,
    cronJob,
    panelUpdate,
    licenseException,
    nodeException,
  ];

  /// 需要选择证书的类型。
  static bool needsCertificate(String type) => type == ssl;

  /// 需要选择网站的类型。
  static bool needsWebsite(String type) => type == siteEndTime;

  /// 需要选择磁盘的类型。
  static bool needsDisk(String type) => type == disk;

  /// 需要选择病毒扫描任务的类型。
  static bool needsClam(String type) => type == clams;

  /// 需要选择计划任务与触发模式的类型。
  static bool needsCronJob(String type) => type == cronJob;

  /// 以剩余天数作为阈值的类型。
  static bool needsCycleDays(String type) => const <String>[
        panelPwdEndTime,
        licenseException,
        ssl,
        siteEndTime,
      ].contains(type);

  /// 以占用百分比或容量作为阈值的类型。
  static bool needsThreshold(String type) =>
      const <String>[cpu, memory, disk, load].contains(type);

  /// 平均值型告警支持 1/5/15 分钟窗口。
  static bool needsInterval(String type) =>
      const <String>[cpu, memory, load].contains(type);
}

/// 告警任务类型的中文标签。
class AlertTypeLabels {
  const AlertTypeLabels._();

  static String label(AppLocalizations l10n, String type) {
    switch (type) {
      case AlertRuleTypes.panelPwdEndTime:
        return l10n.alertRuleTypePasswordExpiry;
      case AlertRuleTypes.panelLogin:
        return l10n.alertRuleTypePanelLogin;
      case AlertRuleTypes.licenseException:
        return l10n.alertRuleTypeLicenseException;
      case AlertRuleTypes.nodeException:
        return l10n.alertRuleTypeNodeException;
      case AlertRuleTypes.panelUpdate:
        return l10n.alertRuleTypePanelUpdate;
      case AlertRuleTypes.sshLogin:
        return l10n.alertRuleTypeSshLogin;
      case AlertRuleTypes.ssl:
        return l10n.alertRuleTypeSsl;
      case AlertRuleTypes.siteEndTime:
        return l10n.alertRuleTypeSiteExpiry;
      case AlertRuleTypes.cpu:
        return l10n.alertRuleTypeCpu;
      case AlertRuleTypes.memory:
        return l10n.alertRuleTypeMemory;
      case AlertRuleTypes.disk:
        return l10n.alertRuleTypeDisk;
      case AlertRuleTypes.load:
        return l10n.alertRuleTypeLoad;
      case AlertRuleTypes.clams:
        return l10n.alertRuleTypeClams;
      case AlertRuleTypes.cronJob:
        return l10n.alertRuleTypeCronJob;
      default:
        return type;
    }
  }
}

/// 把告警任务规则结构化为可读文案。
class AlertRuleFormatter {
  const AlertRuleFormatter._();

  /// 生成规则说明，例如「剩余 30 天」「占用超过 80%」「失败时」。
  static String describe(AppLocalizations l10n, AlertInfo rule) {
    if (AlertRuleTypes.needsCycleDays(rule.type)) {
      return '${l10n.alertRuleCycleDaysLabel} ${rule.cycle}';
    }
    if (AlertRuleTypes.needsCronJob(rule.type)) {
      final mode = rule.alertTriggerMode ?? '';
      final modeLabel = triggerModeLabel(l10n, mode);
      return modeLabel.isEmpty
          ? rule.taskName ?? l10n.alertRuleTypeCronJob
          : '${rule.taskName ?? l10n.alertRuleTypeCronJob} · $modeLabel';
    }
    if (AlertRuleTypes.needsThreshold(rule.type)) {
      final window = rule.interval > 0
          ? intervalLabel(l10n, rule.interval)
          : null;
      final threshold = rule.count > 0 ? '${rule.count}' : null;
      final parts = <String>[if (window != null) window, if (threshold != null) threshold];
      return parts.join(' · ');
    }
    return rule.advancedParams.isEmpty ? rule.project : rule.advancedParams;
  }

  static String triggerModeLabel(AppLocalizations l10n, String mode) {
    switch (mode) {
      case 'failed':
        return l10n.alertRuleCronjobTriggerFailed;
      case 'success':
        return l10n.alertRuleCronjobTriggerSuccess;
      case 'both':
        return l10n.alertRuleCronjobTriggerBoth;
      default:
        return '';
    }
  }

  static String intervalLabel(AppLocalizations l10n, int minutes) {
    switch (minutes) {
      case 1:
        return l10n.alertRuleIntervalMinute1;
      case 5:
        return l10n.alertRuleIntervalMinute5;
      case 15:
        return l10n.alertRuleIntervalMinute15;
      default:
        return '$minutes';
    }
  }
}

/// 通知渠道类型与能力标记。
///
/// 原生表单与通道共用这里的判定，界面不再重复判断渠道类型字符串。
class AlertChannelTypes {
  const AlertChannelTypes._();

  static const String email = 'email';
  static const String bark = 'bark';
  static const String weCom = 'weCom';
  static const String dingTalk = 'dingTalk';
  static const String feiShu = 'feiShu';
  static const String custom = 'custom';

  static const List<String> values = <String>[
    email,
    bark,
    weCom,
    dingTalk,
    feiShu,
    custom,
  ];

  /// 邮箱渠道需要 SMTP 字段。
  static bool isEmail(String type) => type == email;

  /// Webhook 类渠道（自定义与各 IM 平台）共用地址字段。
  static bool isWebhook(String type) =>
      const <String>[custom, weCom, dingTalk, feiShu, bark].contains(type);

  /// 只有邮箱与自定义 Webhook 支持服务端测试端点。
  static bool supportsTest(String type) =>
      const <String>[email, custom].contains(type);
}

/// 自定义 Webhook 预设模板。
class AlertWebhookPresets {
  const AlertWebhookPresets._();

  static const List<String> values = <String>[
    'genericJson',
    'slack',
    'discord',
    'teams',
    'custom',
  ];

  static String? template(String preset) {
    switch (preset) {
      case 'genericJson':
        return '{\n  "title": "{{title}}",\n  "message": "{{message}}",\n'
            '  "type": "{{type}}",\n  "node": "{{nodeName}}",\n'
            '  "timestamp": "{{timestamp}}"\n}';
      case 'slack':
        return '{\n  "text": "{{title}}\\n{{message}}"\n}';
      case 'discord':
        return '{\n  "content": "{{title}}\\n{{message}}"\n}';
      case 'teams':
        return '{\n  "type": "message",\n  "attachments": [\n    {\n'
            '      "contentType": "application/vnd.microsoft.card.adaptive",\n'
            '      "content": {\n        "type": "AdaptiveCard",\n'
            '        "body": [\n          { "type": "TextBlock", '
            '"text": "{{title}}" },\n          { "type": "TextBlock", '
            '"text": "{{message}}" }\n        ]\n      }\n    }\n  ]\n}';
      default:
        return null;
    }
  }
}
