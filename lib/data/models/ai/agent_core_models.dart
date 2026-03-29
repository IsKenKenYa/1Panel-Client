class AgentCreateReq {
  final String name;
  final String appVersion;
  final int webUIPort;
  final int? bridgePort;
  final List<String>? allowedOrigins;
  final String agentType;
  final String? model;
  final int? accountId;
  final String? token;
  final String taskID;
  final bool advanced;
  final String containerName;
  final bool allowPort;
  final String specifyIP;
  final String restartPolicy;
  final double cpuQuota;
  final double memoryLimit;
  final String memoryUnit;
  final bool pullImage;
  final bool editCompose;
  final String dockerCompose;

  const AgentCreateReq({
    required this.name,
    required this.appVersion,
    required this.webUIPort,
    this.bridgePort,
    this.allowedOrigins,
    required this.agentType,
    this.model,
    this.accountId,
    this.token,
    required this.taskID,
    required this.advanced,
    required this.containerName,
    required this.allowPort,
    required this.specifyIP,
    required this.restartPolicy,
    required this.cpuQuota,
    required this.memoryLimit,
    required this.memoryUnit,
    required this.pullImage,
    required this.editCompose,
    required this.dockerCompose,
  });

  factory AgentCreateReq.fromJson(Map<String, dynamic> json) {
    return AgentCreateReq(
      name: json['name'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      webUIPort: json['webUIPort'] as int? ?? 0,
      bridgePort: json['bridgePort'] as int?,
      allowedOrigins: (json['allowedOrigins'] as List<dynamic>?)
          ?.map((dynamic item) => item.toString())
          .toList(),
      agentType: json['agentType'] as String? ?? 'openclaw',
      model: json['model'] as String?,
      accountId: json['accountId'] as int?,
      token: json['token'] as String?,
      taskID: json['taskID'] as String? ?? '',
      advanced: json['advanced'] as bool? ?? false,
      containerName: json['containerName'] as String? ?? '',
      allowPort: json['allowPort'] as bool? ?? false,
      specifyIP: json['specifyIP'] as String? ?? '',
      restartPolicy: json['restartPolicy'] as String? ?? 'always',
      cpuQuota: (json['cpuQuota'] as num?)?.toDouble() ?? 0,
      memoryLimit: (json['memoryLimit'] as num?)?.toDouble() ?? 0,
      memoryUnit: json['memoryUnit'] as String? ?? 'M',
      pullImage: json['pullImage'] as bool? ?? true,
      editCompose: json['editCompose'] as bool? ?? false,
      dockerCompose: json['dockerCompose'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'appVersion': appVersion,
      'webUIPort': webUIPort,
      if (bridgePort != null) 'bridgePort': bridgePort,
      if (allowedOrigins != null) 'allowedOrigins': allowedOrigins,
      'agentType': agentType,
      if (model != null) 'model': model,
      if (accountId != null) 'accountId': accountId,
      if (token != null) 'token': token,
      'taskID': taskID,
      'advanced': advanced,
      'containerName': containerName,
      'allowPort': allowPort,
      'specifyIP': specifyIP,
      'restartPolicy': restartPolicy,
      'cpuQuota': cpuQuota,
      'memoryLimit': memoryLimit,
      'memoryUnit': memoryUnit,
      'pullImage': pullImage,
      'editCompose': editCompose,
      'dockerCompose': dockerCompose,
    };
  }
}

class AgentItem {
  final int? id;
  final String? name;
  final String? agentType;
  final String? provider;
  final String? providerName;
  final String? model;
  final String? apiType;
  final int? maxTokens;
  final int? contextWindow;
  final String? baseUrl;
  final String? apiKey;
  final String? token;
  final String? status;
  final String? message;
  final int? appInstallId;
  final int? accountId;
  final String? appVersion;
  final String? containerName;
  final int? webUIPort;
  final int? bridgePort;
  final String? path;
  final String? configPath;
  final bool? upgradable;
  final String? createdAt;

  const AgentItem({
    this.id,
    this.name,
    this.agentType,
    this.provider,
    this.providerName,
    this.model,
    this.apiType,
    this.maxTokens,
    this.contextWindow,
    this.baseUrl,
    this.apiKey,
    this.token,
    this.status,
    this.message,
    this.appInstallId,
    this.accountId,
    this.appVersion,
    this.containerName,
    this.webUIPort,
    this.bridgePort,
    this.path,
    this.configPath,
    this.upgradable,
    this.createdAt,
  });

  factory AgentItem.fromJson(Map<String, dynamic> json) {
    return AgentItem(
      id: json['id'] as int?,
      name: json['name'] as String?,
      agentType: json['agentType'] as String?,
      provider: json['provider'] as String?,
      providerName: json['providerName'] as String?,
      model: json['model'] as String?,
      apiType: json['apiType'] as String?,
      maxTokens: json['maxTokens'] as int?,
      contextWindow: json['contextWindow'] as int?,
      baseUrl: json['baseUrl'] as String?,
      apiKey: json['apiKey'] as String?,
      token: json['token'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
      appInstallId: json['appInstallId'] as int?,
      accountId: json['accountId'] as int?,
      appVersion: json['appVersion'] as String?,
      containerName: json['containerName'] as String?,
      webUIPort: json['webUIPort'] as int?,
      bridgePort: json['bridgePort'] as int?,
      path: json['path'] as String?,
      configPath: json['configPath'] as String?,
      upgradable: json['upgradable'] as bool?,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (agentType != null) 'agentType': agentType,
      if (provider != null) 'provider': provider,
      if (providerName != null) 'providerName': providerName,
      if (model != null) 'model': model,
      if (apiType != null) 'apiType': apiType,
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (contextWindow != null) 'contextWindow': contextWindow,
      if (baseUrl != null) 'baseUrl': baseUrl,
      if (apiKey != null) 'apiKey': apiKey,
      if (token != null) 'token': token,
      if (status != null) 'status': status,
      if (message != null) 'message': message,
      if (appInstallId != null) 'appInstallId': appInstallId,
      if (accountId != null) 'accountId': accountId,
      if (appVersion != null) 'appVersion': appVersion,
      if (containerName != null) 'containerName': containerName,
      if (webUIPort != null) 'webUIPort': webUIPort,
      if (bridgePort != null) 'bridgePort': bridgePort,
      if (path != null) 'path': path,
      if (configPath != null) 'configPath': configPath,
      if (upgradable != null) 'upgradable': upgradable,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}

class AgentDeleteReq {
  final int id;
  final String taskID;
  final bool forceDelete;

  const AgentDeleteReq({
    required this.id,
    required this.taskID,
    this.forceDelete = false,
  });

  factory AgentDeleteReq.fromJson(Map<String, dynamic> json) {
    return AgentDeleteReq(
      id: json['id'] as int? ?? 0,
      taskID: json['taskID'] as String? ?? '',
      forceDelete: json['forceDelete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskID': taskID,
      'forceDelete': forceDelete,
    };
  }
}

class AgentTokenResetReq {
  final int id;

  const AgentTokenResetReq({required this.id});

  factory AgentTokenResetReq.fromJson(Map<String, dynamic> json) {
    return AgentTokenResetReq(id: json['id'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }
}

class AgentModelConfigUpdateReq {
  final int agentId;
  final int accountId;
  final String model;

  const AgentModelConfigUpdateReq({
    required this.agentId,
    required this.accountId,
    required this.model,
  });

  factory AgentModelConfigUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentModelConfigUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      accountId: json['accountId'] as int? ?? 0,
      model: json['model'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'accountId': accountId,
      'model': model,
    };
  }
}

class AgentOverviewReq {
  final int agentId;

  const AgentOverviewReq({required this.agentId});

  factory AgentOverviewReq.fromJson(Map<String, dynamic> json) {
    return AgentOverviewReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentIdReq {
  final int agentId;

  const AgentIdReq({required this.agentId});

  factory AgentIdReq.fromJson(Map<String, dynamic> json) {
    return AgentIdReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentOverviewSnapshot {
  final String? containerStatus;
  final String? appVersion;
  final String? defaultModel;
  final int? channelCount;
  final int? skillCount;
  final int? jobCount;
  final int? sessionCount;

  const AgentOverviewSnapshot({
    this.containerStatus,
    this.appVersion,
    this.defaultModel,
    this.channelCount,
    this.skillCount,
    this.jobCount,
    this.sessionCount,
  });

  factory AgentOverviewSnapshot.fromJson(Map<String, dynamic> json) {
    return AgentOverviewSnapshot(
      containerStatus: json['containerStatus'] as String?,
      appVersion: json['appVersion'] as String?,
      defaultModel: json['defaultModel'] as String?,
      channelCount: json['channelCount'] as int?,
      skillCount: json['skillCount'] as int?,
      jobCount: json['jobCount'] as int?,
      sessionCount: json['sessionCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (containerStatus != null) 'containerStatus': containerStatus,
      if (appVersion != null) 'appVersion': appVersion,
      if (defaultModel != null) 'defaultModel': defaultModel,
      if (channelCount != null) 'channelCount': channelCount,
      if (skillCount != null) 'skillCount': skillCount,
      if (jobCount != null) 'jobCount': jobCount,
      if (sessionCount != null) 'sessionCount': sessionCount,
    };
  }
}

class AgentOverview {
  final AgentOverviewSnapshot? snapshot;

  const AgentOverview({this.snapshot});

  factory AgentOverview.fromJson(Map<String, dynamic> json) {
    return AgentOverview(
      snapshot: json['snapshot'] is Map<String, dynamic>
          ? AgentOverviewSnapshot.fromJson(
              json['snapshot'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (snapshot != null) 'snapshot': snapshot!.toJson(),
    };
  }
}
