class AgentFeishuConfigReq {
  final int agentId;

  const AgentFeishuConfigReq({required this.agentId});

  factory AgentFeishuConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentFeishuConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentFeishuConfig {
  final bool enabled;
  final String dmPolicy;
  final String botName;
  final String appId;
  final String appSecret;

  const AgentFeishuConfig({
    this.enabled = false,
    this.dmPolicy = '',
    this.botName = '',
    this.appId = '',
    this.appSecret = '',
  });

  factory AgentFeishuConfig.fromJson(Map<String, dynamic> json) {
    return AgentFeishuConfig(
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botName: json['botName'] as String? ?? '',
      appId: json['appId'] as String? ?? '',
      appSecret: json['appSecret'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botName': botName,
      'appId': appId,
      'appSecret': appSecret,
    };
  }
}

class AgentFeishuConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String dmPolicy;
  final String botName;
  final String appId;
  final String appSecret;

  const AgentFeishuConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.dmPolicy,
    required this.botName,
    required this.appId,
    required this.appSecret,
  });

  factory AgentFeishuConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentFeishuConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botName: json['botName'] as String? ?? '',
      appId: json['appId'] as String? ?? '',
      appSecret: json['appSecret'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botName': botName,
      'appId': appId,
      'appSecret': appSecret,
    };
  }
}

class AgentFeishuPairingApproveReq {
  final int agentId;
  final String pairingCode;

  const AgentFeishuPairingApproveReq({
    required this.agentId,
    required this.pairingCode,
  });

  factory AgentFeishuPairingApproveReq.fromJson(Map<String, dynamic> json) {
    return AgentFeishuPairingApproveReq(
      agentId: json['agentId'] as int? ?? 0,
      pairingCode: json['pairingCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'pairingCode': pairingCode,
    };
  }
}

class AgentTelegramConfigReq {
  final int agentId;

  const AgentTelegramConfigReq({required this.agentId});

  factory AgentTelegramConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentTelegramConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentTelegramConfig {
  final bool enabled;
  final String dmPolicy;
  final String botToken;
  final String proxy;

  const AgentTelegramConfig({
    this.enabled = false,
    this.dmPolicy = '',
    this.botToken = '',
    this.proxy = '',
  });

  factory AgentTelegramConfig.fromJson(Map<String, dynamic> json) {
    return AgentTelegramConfig(
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botToken: json['botToken'] as String? ?? '',
      proxy: json['proxy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botToken': botToken,
      'proxy': proxy,
    };
  }
}

class AgentTelegramConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String dmPolicy;
  final String botToken;
  final String proxy;

  const AgentTelegramConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.dmPolicy,
    required this.botToken,
    required this.proxy,
  });

  factory AgentTelegramConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentTelegramConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      botToken: json['botToken'] as String? ?? '',
      proxy: json['proxy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'botToken': botToken,
      'proxy': proxy,
    };
  }
}

class AgentDiscordConfigReq {
  final int agentId;

  const AgentDiscordConfigReq({required this.agentId});

  factory AgentDiscordConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentDiscordConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentDiscordConfig {
  final bool enabled;
  final String dmPolicy;
  final String groupPolicy;
  final String token;
  final String proxy;

  const AgentDiscordConfig({
    this.enabled = false,
    this.dmPolicy = '',
    this.groupPolicy = '',
    this.token = '',
    this.proxy = '',
  });

  factory AgentDiscordConfig.fromJson(Map<String, dynamic> json) {
    return AgentDiscordConfig(
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      groupPolicy: json['groupPolicy'] as String? ?? '',
      token: json['token'] as String? ?? '',
      proxy: json['proxy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'groupPolicy': groupPolicy,
      'token': token,
      'proxy': proxy,
    };
  }
}

class AgentDiscordConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final String dmPolicy;
  final String groupPolicy;
  final String token;
  final String proxy;

  const AgentDiscordConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.dmPolicy,
    required this.groupPolicy,
    required this.token,
    required this.proxy,
  });

  factory AgentDiscordConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentDiscordConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      dmPolicy: json['dmPolicy'] as String? ?? '',
      groupPolicy: json['groupPolicy'] as String? ?? '',
      token: json['token'] as String? ?? '',
      proxy: json['proxy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'dmPolicy': dmPolicy,
      'groupPolicy': groupPolicy,
      'token': token,
      'proxy': proxy,
    };
  }
}
