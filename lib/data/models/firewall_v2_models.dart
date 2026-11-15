import 'package:equatable/equatable.dart';

class FirewallPortWhitelistRule extends Equatable {
  final String port;
  final String protocol;
  final String? type;
  final List<String>? sources;

  const FirewallPortWhitelistRule({
    required this.port,
    required this.protocol,
    this.type,
    this.sources,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'port': port, 'protocol': protocol};
    if (type != null) json['type'] = type;
    if (sources != null) json['sources'] = sources;
    return json;
  }

  @override
  List<Object?> get props => [port, protocol, type, sources];
}

class FirewallPortWhitelistOperation extends Equatable {
  final FirewallPortWhitelistRule rule;

  const FirewallPortWhitelistOperation({required this.rule});

  Map<String, dynamic> toJson() => <String, dynamic>{'rule': rule.toJson()};

  @override
  List<Object?> get props => [rule];
}

class FirewallPortWhitelistUpdate extends Equatable {
  final FirewallPortWhitelistRule oldRule;
  final FirewallPortWhitelistRule rule;

  const FirewallPortWhitelistUpdate({
    required this.oldRule,
    required this.rule,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'oldRule': oldRule.toJson(),
        'rule': rule.toJson(),
      };

  @override
  List<Object?> get props => [oldRule, rule];
}

class FirewallIPv6Operation extends Equatable {
  final String status;

  const FirewallIPv6Operation({required this.status});

  Map<String, dynamic> toJson() => <String, dynamic>{'status': status};

  @override
  List<Object?> get props => [status];
}

class FirewallBackendOperation extends Equatable {
  final String backend;
  final String operation;
  final String subsystem;

  const FirewallBackendOperation({
    required this.backend,
    required this.operation,
    required this.subsystem,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'backend': backend,
        'operation': operation,
        'subsystem': subsystem,
      };

  @override
  List<Object?> get props => [backend, operation, subsystem];
}

class FirewallFamilyOperation extends Equatable {
  final String backend;
  final String family;
  final String operation;
  final String subsystem;

  const FirewallFamilyOperation({
    required this.backend,
    required this.family,
    required this.operation,
    required this.subsystem,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'backend': backend,
        'family': family,
        'operation': operation,
        'subsystem': subsystem,
      };

  @override
  List<Object?> get props => [backend, family, operation, subsystem];
}

class FirewallRuleInventoryRequest extends Equatable {
  final int page;
  final int pageSize;
  final String? info;
  final bool? all;
  final List<String>? scopes;
  final List<String>? families;
  final List<String>? actions;
  final List<String>? excludeChains;
  final String? scope;

  const FirewallRuleInventoryRequest({
    required this.page,
    required this.pageSize,
    this.info,
    this.all,
    this.scopes,
    this.families,
    this.actions,
    this.excludeChains,
    this.scope,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (info != null) json['info'] = info;
    if (all != null) json['all'] = all;
    if (scopes != null) json['scopes'] = scopes;
    if (families != null) json['families'] = families;
    if (actions != null) json['actions'] = actions;
    if (excludeChains != null) json['excludeChains'] = excludeChains;
    if (scope != null) json['scope'] = scope;
    return json;
  }

  @override
  List<Object?> get props => [
        page,
        pageSize,
        info,
        all,
        scopes,
        families,
        actions,
        excludeChains,
        scope,
      ];
}

class FirewallRuleCreateRequest extends Equatable {
  final List<Map<String, dynamic>>? items;
  final bool? initialize;
  final String? backupFile;

  const FirewallRuleCreateRequest({
    this.items,
    this.initialize,
    this.backupFile,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (items != null) json['items'] = items;
    if (initialize != null) json['initialize'] = initialize;
    if (backupFile != null) json['backupFile'] = backupFile;
    return json;
  }

  @override
  List<Object?> get props => [items, initialize, backupFile];
}

class FirewallRuleDeleteRequest extends Equatable {
  final List<Map<String, dynamic>> targets;

  const FirewallRuleDeleteRequest({required this.targets});

  Map<String, dynamic> toJson() => <String, dynamic>{'targets': targets};

  @override
  List<Object?> get props => [targets];
}

class FirewallRuleUpdateRequest extends Equatable {
  final String instanceKey;
  final String scope;
  final String? description;
  final int? orderIndex;
  final int? priority;
  final Map<String, dynamic>? rule;

  const FirewallRuleUpdateRequest({
    required this.instanceKey,
    required this.scope,
    this.description,
    this.orderIndex,
    this.priority,
    this.rule,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'instanceKey': instanceKey,
      'scope': scope,
    };
    if (description != null) json['description'] = description;
    if (orderIndex != null) json['orderIndex'] = orderIndex;
    if (priority != null) json['priority'] = priority;
    if (rule != null) json['rule'] = rule;
    return json;
  }

  @override
  List<Object?> get props =>
      [instanceKey, scope, description, orderIndex, priority, rule];
}

class FirewallRuleReorderRequest extends Equatable {
  final String instanceKey;
  final String scope;
  final int? priority;
  final int? targetPosition;

  const FirewallRuleReorderRequest({
    required this.instanceKey,
    required this.scope,
    this.priority,
    this.targetPosition,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'instanceKey': instanceKey,
      'scope': scope,
    };
    if (priority != null) json['priority'] = priority;
    if (targetPosition != null) json['targetPosition'] = targetPosition;
    return json;
  }

  @override
  List<Object?> get props => [instanceKey, scope, priority, targetPosition];
}

class FirewallRuleResetRequest extends Equatable {
  final bool? backup;
  final String? provider;
  final String? subsystem;
  final bool? withDockerRestart;

  const FirewallRuleResetRequest({
    this.backup,
    this.provider,
    this.subsystem,
    this.withDockerRestart,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (backup != null) json['backup'] = backup;
    if (provider != null) json['provider'] = provider;
    if (subsystem != null) json['subsystem'] = subsystem;
    if (withDockerRestart != null) {
      json['withDockerRestart'] = withDockerRestart;
    }
    return json;
  }

  @override
  List<Object?> get props =>
      [backup, provider, subsystem, withDockerRestart];
}

class FirewallNativeDetailRequest extends Equatable {
  final String name;
  final String nativeKind;
  final String provider;
  final bool? permanent;

  const FirewallNativeDetailRequest({
    required this.name,
    required this.nativeKind,
    required this.provider,
    this.permanent,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'nativeKind': nativeKind,
      'provider': provider,
    };
    if (permanent != null) json['permanent'] = permanent;
    return json;
  }

  @override
  List<Object?> get props => [name, nativeKind, provider, permanent];
}

class FirewallForwardEnableRequest extends Equatable {
  final String? backupFile;
  final String? taskID;

  const FirewallForwardEnableRequest({this.backupFile, this.taskID});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (backupFile != null) json['backupFile'] = backupFile;
    if (taskID != null) json['taskID'] = taskID;
    return json;
  }

  @override
  List<Object?> get props => [backupFile, taskID];
}

class FirewallForwardOperateV2Request extends Equatable {
  final List<Map<String, dynamic>> rules;
  final bool? import;

  const FirewallForwardOperateV2Request({required this.rules, this.import});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'rules': rules};
    if (import != null) json['import'] = import;
    return json;
  }

  @override
  List<Object?> get props => [rules, import];
}

class FirewallForwardSearchRequest extends Equatable {
  final int page;
  final int pageSize;
  final bool? all;
  final String? info;
  final String? status;
  final String? strategy;

  const FirewallForwardSearchRequest({
    required this.page,
    required this.pageSize,
    this.all,
    this.info,
    this.status,
    this.strategy,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (all != null) json['all'] = all;
    if (info != null) json['info'] = info;
    if (status != null) json['status'] = status;
    if (strategy != null) json['strategy'] = strategy;
    return json;
  }

  @override
  List<Object?> get props => [page, pageSize, all, info, status, strategy];
}

class FirewallDockerOperation extends Equatable {
  final String operation;
  final String? backupFile;
  final String? taskID;

  const FirewallDockerOperation({
    required this.operation,
    this.backupFile,
    this.taskID,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'operation': operation};
    if (backupFile != null) json['backupFile'] = backupFile;
    if (taskID != null) json['taskID'] = taskID;
    return json;
  }

  @override
  List<Object?> get props => [operation, backupFile, taskID];
}

class FirewallDockerPolicyBatch extends Equatable {
  final List<Map<String, dynamic>> policies;
  final bool? import;

  const FirewallDockerPolicyBatch({required this.policies, this.import});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'policies': policies};
    if (import != null) json['import'] = import;
    return json;
  }

  @override
  List<Object?> get props => [policies, import];
}

class FirewallDockerPolicyBatchDelete extends Equatable {
  final List<String> uuids;

  const FirewallDockerPolicyBatchDelete({required this.uuids});

  Map<String, dynamic> toJson() => <String, dynamic>{'uuids': uuids};

  @override
  List<Object?> get props => [uuids];
}
