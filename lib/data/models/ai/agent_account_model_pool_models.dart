class AgentAccountModel {
  final int recordId;
  final String id;
  final String name;
  final int contextWindow;
  final int maxTokens;
  final bool reasoning;
  final List<String> input;

  const AgentAccountModel({
    this.recordId = 0,
    this.id = '',
    this.name = '',
    this.contextWindow = 0,
    this.maxTokens = 0,
    this.reasoning = false,
    this.input = const <String>[],
  });

  factory AgentAccountModel.fromJson(Map<String, dynamic> json) {
    return AgentAccountModel(
      recordId: json['recordId'] as int? ?? 0,
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contextWindow: json['contextWindow'] as int? ?? 0,
      maxTokens: json['maxTokens'] as int? ?? 0,
      reasoning: json['reasoning'] as bool? ?? false,
      input: (json['input'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'id': id,
      'name': name,
      'contextWindow': contextWindow,
      'maxTokens': maxTokens,
      'reasoning': reasoning,
      'input': input,
    };
  }
}

class AgentAccountModelReq {
  final int accountId;

  const AgentAccountModelReq({required this.accountId});

  factory AgentAccountModelReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountModelReq(accountId: json['accountId'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'accountId': accountId};
  }
}

class AgentAccountModelCreateReq {
  final int accountId;
  final AgentAccountModel model;

  const AgentAccountModelCreateReq({
    required this.accountId,
    required this.model,
  });

  factory AgentAccountModelCreateReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountModelCreateReq(
      accountId: json['accountId'] as int? ?? 0,
      model: AgentAccountModel.fromJson(
        json['model'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'model': model.toJson(),
    };
  }
}

class AgentAccountModelUpdateReq {
  final int accountId;
  final AgentAccountModel model;

  const AgentAccountModelUpdateReq({
    required this.accountId,
    required this.model,
  });

  factory AgentAccountModelUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountModelUpdateReq(
      accountId: json['accountId'] as int? ?? 0,
      model: AgentAccountModel.fromJson(
        json['model'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'model': model.toJson(),
    };
  }
}

class AgentAccountModelDeleteReq {
  final int accountId;
  final int recordId;

  const AgentAccountModelDeleteReq({
    required this.accountId,
    required this.recordId,
  });

  factory AgentAccountModelDeleteReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountModelDeleteReq(
      accountId: json['accountId'] as int? ?? 0,
      recordId: json['recordId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'recordId': recordId,
    };
  }
}

class ProviderModelInfo {
  final String id;
  final String name;
  final int contextWindow;
  final int maxTokens;
  final bool reasoning;
  final List<String> input;

  const ProviderModelInfo({
    this.id = '',
    this.name = '',
    this.contextWindow = 0,
    this.maxTokens = 0,
    this.reasoning = false,
    this.input = const <String>[],
  });

  factory ProviderModelInfo.fromJson(Map<String, dynamic> json) {
    return ProviderModelInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contextWindow: json['contextWindow'] as int? ?? 0,
      maxTokens: json['maxTokens'] as int? ?? 0,
      reasoning: json['reasoning'] as bool? ?? false,
      input: (json['input'] as List<dynamic>?)
              ?.map((dynamic item) => item.toString())
              .toList() ??
          const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contextWindow': contextWindow,
      'maxTokens': maxTokens,
      'reasoning': reasoning,
      'input': input,
    };
  }
}

class ProviderInfo {
  final String provider;
  final String displayName;
  final String baseUrl;
  final List<ProviderModelInfo> models;

  const ProviderInfo({
    this.provider = '',
    this.displayName = '',
    this.baseUrl = '',
    this.models = const <ProviderModelInfo>[],
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      provider: json['provider'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      models: (json['models'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(ProviderModelInfo.fromJson)
              .toList() ??
          const <ProviderModelInfo>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'displayName': displayName,
      'baseUrl': baseUrl,
      'models': models.map((ProviderModelInfo item) => item.toJson()).toList(),
    };
  }
}
