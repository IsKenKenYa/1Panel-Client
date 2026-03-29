import '../common_models.dart';
import 'agent_account_model_pool_models.dart';

class AgentAccountCreateReq {
  final String provider;
  final String name;
  final String apiKey;
  final bool rememberApiKey;
  final String baseURL;
  final String apiType;
  final List<AgentAccountModel>? models;
  final String remark;

  const AgentAccountCreateReq({
    required this.provider,
    required this.name,
    required this.apiKey,
    required this.rememberApiKey,
    required this.baseURL,
    required this.apiType,
    this.models,
    this.remark = '',
  });

  factory AgentAccountCreateReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountCreateReq(
      provider: json['provider'] as String? ?? '',
      name: json['name'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      rememberApiKey: json['rememberApiKey'] as bool? ?? false,
      baseURL: json['baseURL'] as String? ?? '',
      apiType: json['apiType'] as String? ?? '',
      models: (json['models'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(AgentAccountModel.fromJson)
          .toList(),
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'name': name,
      'apiKey': apiKey,
      'rememberApiKey': rememberApiKey,
      'baseURL': baseURL,
      'apiType': apiType,
      if (models != null)
        'models': models!
            .map((AgentAccountModel item) => item.toJson())
            .toList(),
      'remark': remark,
    };
  }
}

class AgentAccountUpdateReq {
  final int id;
  final String name;
  final String apiKey;
  final bool rememberApiKey;
  final String baseURL;
  final String apiType;
  final String remark;
  final bool syncAgents;

  const AgentAccountUpdateReq({
    required this.id,
    required this.name,
    required this.apiKey,
    required this.rememberApiKey,
    required this.baseURL,
    required this.apiType,
    required this.remark,
    this.syncAgents = false,
  });

  factory AgentAccountUpdateReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountUpdateReq(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      rememberApiKey: json['rememberApiKey'] as bool? ?? false,
      baseURL: json['baseURL'] as String? ?? '',
      apiType: json['apiType'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      syncAgents: json['syncAgents'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'apiKey': apiKey,
      'rememberApiKey': rememberApiKey,
      'baseURL': baseURL,
      'apiType': apiType,
      'remark': remark,
      'syncAgents': syncAgents,
    };
  }
}

class AgentAccountSearch extends PageRequest {
  final String provider;
  final String name;

  const AgentAccountSearch({
    this.provider = '',
    this.name = '',
    super.page = 1,
    super.pageSize = 20,
  });

  factory AgentAccountSearch.fromJson(Map<String, dynamic> json) {
    return AgentAccountSearch(
      provider: json['provider'] as String? ?? '',
      name: json['name'] as String? ?? '',
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['provider'] = provider;
    json['name'] = name;
    return json;
  }
}

class AgentAccountItem {
  final int id;
  final String provider;
  final String providerName;
  final String name;
  final String apiKey;
  final bool rememberApiKey;
  final String baseUrl;
  final List<AgentAccountModel> models;
  final String apiType;
  final bool verified;
  final String remark;
  final String createdAt;

  const AgentAccountItem({
    this.id = 0,
    this.provider = '',
    this.providerName = '',
    this.name = '',
    this.apiKey = '',
    this.rememberApiKey = false,
    this.baseUrl = '',
    this.models = const <AgentAccountModel>[],
    this.apiType = '',
    this.verified = false,
    this.remark = '',
    this.createdAt = '',
  });

  factory AgentAccountItem.fromJson(Map<String, dynamic> json) {
    return AgentAccountItem(
      id: json['id'] as int? ?? 0,
      provider: json['provider'] as String? ?? '',
      providerName: json['providerName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      rememberApiKey: json['rememberApiKey'] as bool? ?? false,
      baseUrl: json['baseUrl'] as String? ?? '',
      models: (json['models'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(AgentAccountModel.fromJson)
              .toList() ??
          const <AgentAccountModel>[],
      apiType: json['apiType'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      remark: json['remark'] as String? ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'providerName': providerName,
      'name': name,
      'apiKey': apiKey,
      'rememberApiKey': rememberApiKey,
      'baseUrl': baseUrl,
      'models':
          models.map((AgentAccountModel item) => item.toJson()).toList(),
      'apiType': apiType,
      'verified': verified,
      'remark': remark,
      'createdAt': createdAt,
    };
  }
}

class AgentAccountVerifyReq {
  final String provider;
  final String apiKey;
  final String baseURL;

  const AgentAccountVerifyReq({
    required this.provider,
    required this.apiKey,
    required this.baseURL,
  });

  factory AgentAccountVerifyReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountVerifyReq(
      provider: json['provider'] as String? ?? '',
      apiKey: json['apiKey'] as String? ?? '',
      baseURL: json['baseURL'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'apiKey': apiKey,
      'baseURL': baseURL,
    };
  }
}

class AgentAccountDeleteReq {
  final int id;

  const AgentAccountDeleteReq({required this.id});

  factory AgentAccountDeleteReq.fromJson(Map<String, dynamic> json) {
    return AgentAccountDeleteReq(id: json['id'] as int? ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'id': id};
  }
}
