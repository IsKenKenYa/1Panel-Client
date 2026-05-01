class AgentRoleBinding {
  final String channel;
  final String? accountId;

  const AgentRoleBinding({
    required this.channel,
    this.accountId,
  });

  factory AgentRoleBinding.fromJson(Map<String, dynamic> json) {
    return AgentRoleBinding(
      channel: json['channel'] as String? ?? '',
      accountId: json['accountId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'channel': channel,
      if (accountId != null) 'accountId': accountId,
    };
  }
}

class AgentRoleBindReq {
  final int agentId;
  final String channel;
  final String id;
  final String? accountId;

  const AgentRoleBindReq({
    required this.agentId,
    required this.channel,
    required this.id,
    this.accountId,
  });

  factory AgentRoleBindReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleBindReq(
      agentId: json['agentId'] as int? ?? 0,
      channel: json['channel'] as String? ?? '',
      id: json['id'] as String? ?? '',
      accountId: json['accountId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'channel': channel,
      'id': id,
      if (accountId != null) 'accountId': accountId,
    };
  }
}

class AgentRoleChannelsReq {
  final int agentId;

  const AgentRoleChannelsReq({required this.agentId});

  factory AgentRoleChannelsReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleChannelsReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'agentId': agentId};
  }
}

class AgentRoleChannelItem {
  final String? name;
  final bool bound;
  final List<String> accountIds;

  const AgentRoleChannelItem({
    this.name,
    this.bound = false,
    this.accountIds = const <String>[],
  });

  factory AgentRoleChannelItem.fromJson(Map<String, dynamic> json) {
    return AgentRoleChannelItem(
      name: json['name'] as String?,
      bound: json['bound'] as bool? ?? false,
      accountIds: (json['accountIds'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      'bound': bound,
      'accountIds': accountIds,
    };
  }
}

class AgentRoleCreateReq {
  final int agentId;
  final String name;
  final String? model;
  final List<AgentRoleBinding>? bindings;

  const AgentRoleCreateReq({
    required this.agentId,
    required this.name,
    this.model,
    this.bindings,
  });

  factory AgentRoleCreateReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleCreateReq(
      agentId: json['agentId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      model: json['model'] as String?,
      bindings: (json['bindings'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(AgentRoleBinding.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'name': name,
      if (model != null) 'model': model,
      if (bindings != null)
        'bindings':
            bindings!.map((AgentRoleBinding item) => item.toJson()).toList(),
    };
  }
}

class AgentRoleCreateResp {
  final String? output;

  const AgentRoleCreateResp({this.output});

  factory AgentRoleCreateResp.fromJson(Map<String, dynamic> json) {
    return AgentRoleCreateResp(output: json['output'] as String?);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (output != null) 'output': output,
    };
  }
}

class AgentRoleDeleteReq {
  final int agentId;
  final String id;

  const AgentRoleDeleteReq({
    required this.agentId,
    required this.id,
  });

  factory AgentRoleDeleteReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleDeleteReq(
      agentId: json['agentId'] as int? ?? 0,
      id: json['id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'id': id,
    };
  }
}

class AgentConfiguredAgentsReq {
  final int agentId;

  const AgentConfiguredAgentsReq({required this.agentId});

  factory AgentConfiguredAgentsReq.fromJson(Map<String, dynamic> json) {
    return AgentConfiguredAgentsReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'agentId': agentId};
  }
}

class AgentConfiguredAgentItem {
  final String? id;
  final String? name;
  final String? model;
  final String? workspace;
  final String? agentDir;
  final List<AgentRoleBinding> bindings;

  const AgentConfiguredAgentItem({
    this.id,
    this.name,
    this.model,
    this.workspace,
    this.agentDir,
    this.bindings = const <AgentRoleBinding>[],
  });

  factory AgentConfiguredAgentItem.fromJson(Map<String, dynamic> json) {
    return AgentConfiguredAgentItem(
      id: json['id'] as String?,
      name: json['name'] as String?,
      model: json['model'] as String?,
      workspace: json['workspace'] as String?,
      agentDir: json['agentDir'] as String?,
      bindings: (json['bindings'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AgentRoleBinding.fromJson)
              .toList() ??
          const <AgentRoleBinding>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (workspace != null) 'workspace': workspace,
      if (agentDir != null) 'agentDir': agentDir,
      'bindings':
          bindings.map((AgentRoleBinding item) => item.toJson()).toList(),
    };
  }
}

class AgentRoleMarkdownFilesReq {
  final int agentId;
  final String workspace;

  const AgentRoleMarkdownFilesReq({
    required this.agentId,
    required this.workspace,
  });

  factory AgentRoleMarkdownFilesReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleMarkdownFilesReq(
      agentId: json['agentId'] as int? ?? 0,
      workspace: json['workspace'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'workspace': workspace,
    };
  }
}

class AgentRoleMarkdownFileItem {
  final String? name;
  final String? content;

  const AgentRoleMarkdownFileItem({
    this.name,
    this.content,
  });

  factory AgentRoleMarkdownFileItem.fromJson(Map<String, dynamic> json) {
    return AgentRoleMarkdownFileItem(
      name: json['name'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (content != null) 'content': content,
    };
  }
}

class AgentRoleMarkdownFileUpdateItem {
  final String name;
  final String? content;

  const AgentRoleMarkdownFileUpdateItem({
    required this.name,
    this.content,
  });

  factory AgentRoleMarkdownFileUpdateItem.fromJson(Map<String, dynamic> json) {
    return AgentRoleMarkdownFileUpdateItem(
      name: json['name'] as String? ?? '',
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      if (content != null) 'content': content,
    };
  }
}

class AgentRoleMarkdownFilesUpdateReq {
  final int agentId;
  final String workspace;
  final List<AgentRoleMarkdownFileUpdateItem> files;
  final bool? restart;

  const AgentRoleMarkdownFilesUpdateReq({
    required this.agentId,
    required this.workspace,
    required this.files,
    this.restart,
  });

  factory AgentRoleMarkdownFilesUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentRoleMarkdownFilesUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      workspace: json['workspace'] as String? ?? '',
      files: (json['files'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AgentRoleMarkdownFileUpdateItem.fromJson)
              .toList() ??
          const <AgentRoleMarkdownFileUpdateItem>[],
      restart: json['restart'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'workspace': workspace,
      'files': files
          .map((AgentRoleMarkdownFileUpdateItem item) => item.toJson())
          .toList(),
      if (restart != null) 'restart': restart,
    };
  }
}

class AgentModelConfig {
  final int? accountId;
  final String? model;
  final List<String> fallbacks;

  const AgentModelConfig({
    this.accountId,
    this.model,
    this.fallbacks = const <String>[],
  });

  factory AgentModelConfig.fromJson(Map<String, dynamic> json) {
    return AgentModelConfig(
      accountId: json['accountId'] as int?,
      model: json['model'] as String?,
      fallbacks: (json['fallbacks'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (accountId != null) 'accountId': accountId,
      if (model != null) 'model': model,
      'fallbacks': fallbacks,
    };
  }
}

class AgentRemarkUpdateReq {
  final int id;
  final String? remark;

  const AgentRemarkUpdateReq({
    required this.id,
    this.remark,
  });

  factory AgentRemarkUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentRemarkUpdateReq(
      id: json['id'] as int? ?? 0,
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remark != null) 'remark': remark,
    };
  }
}

class AgentWebsiteBindReq {
  final int agentId;
  final int websiteId;

  const AgentWebsiteBindReq({
    required this.agentId,
    required this.websiteId,
  });

  factory AgentWebsiteBindReq.fromJson(Map<String, dynamic> json) {
    return AgentWebsiteBindReq(
      agentId: json['agentId'] as int? ?? 0,
      websiteId: json['websiteId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agentId': agentId,
      'websiteId': websiteId,
    };
  }
}
