class AgentPluginInstallReq {
  final int agentId;
  final String type;
  final String taskID;

  const AgentPluginInstallReq({
    required this.agentId,
    required this.type,
    required this.taskID,
  });

  factory AgentPluginInstallReq.fromJson(Map<String, dynamic> json) {
    return AgentPluginInstallReq(
      agentId: json['agentId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      taskID: json['taskID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'type': type,
      'taskID': taskID,
    };
  }
}

class AgentPluginCheckReq {
  final int agentId;
  final String type;

  const AgentPluginCheckReq({
    required this.agentId,
    required this.type,
  });

  factory AgentPluginCheckReq.fromJson(Map<String, dynamic> json) {
    return AgentPluginCheckReq(
      agentId: json['agentId'] as int? ?? 0,
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'type': type,
    };
  }
}

class AgentPluginStatus {
  final bool installed;

  const AgentPluginStatus({this.installed = false});

  factory AgentPluginStatus.fromJson(Map<String, dynamic> json) {
    return AgentPluginStatus(installed: json['installed'] as bool? ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'installed': installed,
    };
  }
}
