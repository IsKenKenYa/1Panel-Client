class AgentChannelPairingApproveReq {
  final int agentId;
  final String type;
  final String pairingCode;

  const AgentChannelPairingApproveReq({
    required this.agentId,
    required this.type,
    required this.pairingCode,
  });

  factory AgentChannelPairingApproveReq.fromJson(Map<String, dynamic> json) {
    return AgentChannelPairingApproveReq(
      agentId: json['agentId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      pairingCode: json['pairingCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'type': type,
      'pairingCode': pairingCode,
    };
  }
}

class AgentWecomConfigReq {
  final int agentId;

  const AgentWecomConfigReq({required this.agentId});

  factory AgentWecomConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentWecomConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentWecomConfig {
  final bool enabled;
  final String dmPolicy;
  final String botId;
  final String secret;
  final bool installed;

  const AgentWecomConfig({
    this.enabled = false,
    this.dmPolicy = '',
    this.botId = '',
    this.secret = '',
    this.installed = false,
  });

  factory AgentWecomConfig.fromJson(Map<String, dynamic> json) {
    return AgentWecomConfig(
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botId: json['botId'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      installed: json['installed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botId': botId,
      'secret': secret,
      'installed': installed,
    };
  }
}

class AgentWecomConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String dmPolicy;
  final String botId;
  final String secret;

  const AgentWecomConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.dmPolicy,
    required this.botId,
    required this.secret,
  });

  factory AgentWecomConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentWecomConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botId: json['botId'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botId': botId,
      'secret': secret,
    };
  }
}

class AgentDingTalkConfigReq {
  final int agentId;

  const AgentDingTalkConfigReq({required this.agentId});

  factory AgentDingTalkConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentDingTalkConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentDingTalkConfig {
  final bool enabled;
  final String clientId;
  final String clientSecret;
  final String dmPolicy;
  final List<String> allowFrom;
  final String groupPolicy;
  final List<String> groupAllowFrom;
  final bool installed;

  const AgentDingTalkConfig({
    this.enabled = false,
    this.clientId = '',
    this.clientSecret = '',
    this.dmPolicy = '',
    this.allowFrom = const <String>[],
    this.groupPolicy = '',
    this.groupAllowFrom = const <String>[],
    this.installed = false,
  });

  factory AgentDingTalkConfig.fromJson(Map<String, dynamic> json) {
    return AgentDingTalkConfig(
      enabled: json['enabled'] as bool? ?? false,
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      dmPolicy: json['dmPolicy'] as String? ?? '',
      allowFrom: (json['allowFrom'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
      groupPolicy: json['groupPolicy'] as String? ?? '',
      groupAllowFrom: (json['groupAllowFrom'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
      installed: json['installed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'dmPolicy': dmPolicy,
      'allowFrom': allowFrom,
      'groupPolicy': groupPolicy,
      'groupAllowFrom': groupAllowFrom,
      'installed': installed,
    };
  }
}

class AgentDingTalkConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String clientId;
  final String clientSecret;
  final String dmPolicy;
  final List<String> allowFrom;
  final String groupPolicy;
  final List<String> groupAllowFrom;

  const AgentDingTalkConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.clientId,
    required this.clientSecret,
    required this.dmPolicy,
    required this.allowFrom,
    required this.groupPolicy,
    required this.groupAllowFrom,
  });

  factory AgentDingTalkConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentDingTalkConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      clientId: json['clientId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      dmPolicy: json['dmPolicy'] as String? ?? '',
      allowFrom: (json['allowFrom'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
      groupPolicy: json['groupPolicy'] as String? ?? '',
      groupAllowFrom: (json['groupAllowFrom'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'clientId': clientId,
      'clientSecret': clientSecret,
      'dmPolicy': dmPolicy,
      'allowFrom': allowFrom,
      'groupPolicy': groupPolicy,
      'groupAllowFrom': groupAllowFrom,
    };
  }
}

class AgentWeixinLoginReq {
  final int agentId;
  final String taskID;

  const AgentWeixinLoginReq({
    required this.agentId,
    required this.taskID,
  });

  factory AgentWeixinLoginReq.fromJson(Map<String, dynamic> json) {
    return AgentWeixinLoginReq(
      agentId: json['agentId'] as int? ?? 0,
      taskID: json['taskID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'taskID': taskID,
    };
  }
}

class AgentQQBotConfigReq {
  final int agentId;

  const AgentQQBotConfigReq({required this.agentId});

  factory AgentQQBotConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentQQBotConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentQQBotConfig {
  final bool enabled;
  final String appId;
  final String clientSecret;
  final bool installed;

  const AgentQQBotConfig({
    this.enabled = false,
    this.appId = '',
    this.clientSecret = '',
    this.installed = false,
  });

  factory AgentQQBotConfig.fromJson(Map<String, dynamic> json) {
    return AgentQQBotConfig(
      enabled: json['enabled'] as bool? ?? false,
      appId: json['appId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
      installed: json['installed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'appId': appId,
      'clientSecret': clientSecret,
      'installed': installed,
    };
  }
}

class AgentQQBotConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String appId;
  final String clientSecret;

  const AgentQQBotConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.appId,
    required this.clientSecret,
  });

  factory AgentQQBotConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentQQBotConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      appId: json['appId'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'appId': appId,
      'clientSecret': clientSecret,
    };
  }
}
