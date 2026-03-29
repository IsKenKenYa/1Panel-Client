class AgentSkillsReq {
  final int agentId;

  const AgentSkillsReq({required this.agentId});

  factory AgentSkillsReq.fromJson(Map<String, dynamic> json) {
    return AgentSkillsReq(agentId: json['agentId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'agentId': agentId};
  }
}

class AgentSkillSearchReq {
  final int agentId;
  final String source;
  final String keyword;

  const AgentSkillSearchReq({
    required this.agentId,
    required this.source,
    required this.keyword,
  });

  factory AgentSkillSearchReq.fromJson(Map<String, dynamic> json) {
    return AgentSkillSearchReq(
      agentId: json['agentId'] as int? ?? 0,
      source: json['source'] as String? ?? '',
      keyword: json['keyword'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'source': source,
      'keyword': keyword,
    };
  }
}

class AgentSkillItem {
  final String name;
  final String description;
  final String source;
  final bool bundled;
  final bool disabled;

  const AgentSkillItem({
    this.name = '',
    this.description = '',
    this.source = '',
    this.bundled = false,
    this.disabled = false,
  });

  factory AgentSkillItem.fromJson(Map<String, dynamic> json) {
    return AgentSkillItem(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source'] as String? ?? '',
      bundled: json['bundled'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'source': source,
      'bundled': bundled,
      'disabled': disabled,
    };
  }
}

class AgentSkillSearchItem {
  final String slug;
  final String name;
  final String description;
  final String summary;
  final String version;
  final String source;
  final String score;

  const AgentSkillSearchItem({
    this.slug = '',
    this.name = '',
    this.description = '',
    this.summary = '',
    this.version = '',
    this.source = '',
    this.score = '',
  });

  factory AgentSkillSearchItem.fromJson(Map<String, dynamic> json) {
    return AgentSkillSearchItem(
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      version: json['version'] as String? ?? '',
      source: json['source'] as String? ?? '',
      score: json['score'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'description': description,
      'summary': summary,
      'version': version,
      'source': source,
      'score': score,
    };
  }
}

class AgentSkillUpdateReq {
  final int agentId;
  final String name;
  final bool enabled;

  const AgentSkillUpdateReq({
    required this.agentId,
    required this.name,
    required this.enabled,
  });

  factory AgentSkillUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentSkillUpdateReq(
      agentId: json['agentId'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'name': name,
      'enabled': enabled,
    };
  }
}

class AgentSkillInstallReq {
  final int agentId;
  final String source;
  final String slug;
  final String taskID;

  const AgentSkillInstallReq({
    required this.agentId,
    required this.source,
    required this.slug,
    required this.taskID,
  });

  factory AgentSkillInstallReq.fromJson(Map<String, dynamic> json) {
    return AgentSkillInstallReq(
      agentId: json['agentId'] as int? ?? 0,
      source: json['source'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      taskID: json['taskID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'source': source,
      'slug': slug,
      'taskID': taskID,
    };
  }
}
