class AgentSecurityConfigReq {
  final int agentId;

  const AgentSecurityConfigReq({required this.agentId});

  factory AgentSecurityConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentSecurityConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentSecurityConfig {
  final List<String> allowedOrigins;

  const AgentSecurityConfig({this.allowedOrigins = const <String>[]});

  factory AgentSecurityConfig.fromJson(Map<String, dynamic> json) {
    return AgentSecurityConfig(
      allowedOrigins: (json['allowedOrigins'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {'allowedOrigins': allowedOrigins};
  }
}

class AgentSecurityConfigUpdateReq {
  final int agentId;
  final List<String> allowedOrigins;

  const AgentSecurityConfigUpdateReq({
    required this.agentId,
    required this.allowedOrigins,
  });

  factory AgentSecurityConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentSecurityConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      allowedOrigins: (json['allowedOrigins'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'allowedOrigins': allowedOrigins,
    };
  }
}

class AgentBrowserConfigReq {
  final int agentId;

  const AgentBrowserConfigReq({required this.agentId});

  factory AgentBrowserConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentBrowserConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentBrowserConfig {
  final bool enabled;
  final bool headless;
  final bool noSandbox;
  final String defaultProfile;
  final String executablePath;

  const AgentBrowserConfig({
    this.enabled = false,
    this.headless = false,
    this.noSandbox = false,
    this.defaultProfile = '',
    this.executablePath = '',
  });

  factory AgentBrowserConfig.fromJson(Map<String, dynamic> json) {
    return AgentBrowserConfig(
      enabled: json['enabled'] as bool? ?? false,
      headless: json['headless'] as bool? ?? false,
      noSandbox: json['noSandbox'] as bool? ?? false,
      defaultProfile: json['defaultProfile'] as String? ?? '',
      executablePath: json['executablePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'headless': headless,
      'noSandbox': noSandbox,
      'defaultProfile': defaultProfile,
      'executablePath': executablePath,
    };
  }
}

class AgentBrowserConfigUpdateReq {
  final int agentId;
  final bool enabled;
  final bool headless;
  final bool noSandbox;
  final String defaultProfile;

  const AgentBrowserConfigUpdateReq({
    required this.agentId,
    required this.enabled,
    required this.headless,
    required this.noSandbox,
    required this.defaultProfile,
  });

  factory AgentBrowserConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentBrowserConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? false,
      headless: json['headless'] as bool? ?? false,
      noSandbox: json['noSandbox'] as bool? ?? false,
      defaultProfile: json['defaultProfile'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'enabled': enabled,
      'headless': headless,
      'noSandbox': noSandbox,
      'defaultProfile': defaultProfile,
    };
  }
}

class AgentOtherConfigReq {
  final int agentId;

  const AgentOtherConfigReq({required this.agentId});

  factory AgentOtherConfigReq.fromJson(Map<String, dynamic> json) {
    return AgentOtherConfigReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentOtherConfig {
  final String userTimezone;
  final bool browserEnabled;
  final String npmRegistry;

  const AgentOtherConfig({
    this.userTimezone = '',
    this.browserEnabled = false,
    this.npmRegistry = '',
  });

  factory AgentOtherConfig.fromJson(Map<String, dynamic> json) {
    return AgentOtherConfig(
      userTimezone: json['userTimezone'] as String? ?? '',
      browserEnabled: json['browserEnabled'] as bool? ?? false,
      npmRegistry: json['npmRegistry'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userTimezone': userTimezone,
      'browserEnabled': browserEnabled,
      'npmRegistry': npmRegistry,
    };
  }
}

class AgentOtherConfigUpdateReq {
  final int agentId;
  final String userTimezone;
  final bool browserEnabled;
  final String npmRegistry;

  const AgentOtherConfigUpdateReq({
    required this.agentId,
    required this.userTimezone,
    required this.browserEnabled,
    required this.npmRegistry,
  });

  factory AgentOtherConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentOtherConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      userTimezone: json['userTimezone'] as String? ?? '',
      browserEnabled: json['browserEnabled'] as bool? ?? false,
      npmRegistry: json['npmRegistry'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'userTimezone': userTimezone,
      'browserEnabled': browserEnabled,
      'npmRegistry': npmRegistry,
    };
  }
}

class AgentConfigFileReq {
  final int agentId;

  const AgentConfigFileReq({required this.agentId});

  factory AgentConfigFileReq.fromJson(Map<String, dynamic> json) {
    return AgentConfigFileReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentConfigFile {
  final String content;

  const AgentConfigFile({this.content = ''});

  factory AgentConfigFile.fromJson(Map<String, dynamic> json) {
    return AgentConfigFile(content: json['content'] as String? ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'content': content};
  }
}

class AgentConfigFileUpdateReq {
  final int agentId;
  final String content;

  const AgentConfigFileUpdateReq({
    required this.agentId,
    required this.content,
  });

  factory AgentConfigFileUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentConfigFileUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'content': content,
    };
  }
}
