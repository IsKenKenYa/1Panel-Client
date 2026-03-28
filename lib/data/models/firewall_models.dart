import 'package:equatable/equatable.dart';

class FirewallBaseInfo extends Equatable {
  const FirewallBaseInfo({
    this.name = '',
    this.isExist = false,
    this.isActive = false,
    this.isInit = false,
    this.isBind = false,
    this.version = '',
    this.pingStatus = '',
  });

  final String name;
  final bool isExist;
  final bool isActive;
  final bool isInit;
  final bool isBind;
  final String version;
  final String pingStatus;

  factory FirewallBaseInfo.fromJson(Map<String, dynamic> json) {
    return FirewallBaseInfo(
      name: json['name'] as String? ?? '',
      isExist: json['isExist'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      isInit: json['isInit'] as bool? ?? false,
      isBind: json['isBind'] as bool? ?? false,
      version: json['version'] as String? ?? '',
      pingStatus: json['pingStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isExist': isExist,
      'isActive': isActive,
      'isInit': isInit,
      'isBind': isBind,
      'version': version,
      'pingStatus': pingStatus,
    };
  }

  @override
  List<Object?> get props => [
        name,
        isExist,
        isActive,
        isInit,
        isBind,
        version,
        pingStatus,
      ];
}

class FirewallRule extends Equatable {
  const FirewallRule({
    this.id,
    this.family,
    this.address,
    this.destination,
    this.port,
    this.srcPort,
    this.destPort,
    this.protocol,
    this.strategy,
    this.usedStatus,
    this.description,
  });

  final int? id;
  final String? family;
  final String? address;
  final String? destination;
  final String? port;
  final String? srcPort;
  final String? destPort;
  final String? protocol;
  final String? strategy;
  final String? usedStatus;
  final String? description;

  factory FirewallRule.fromJson(Map<String, dynamic> json) {
    return FirewallRule(
      id: json['id'] as int?,
      family: json['family'] as String?,
      address: json['address'] as String?,
      destination: json['destination'] as String?,
      port: json['port']?.toString(),
      srcPort: json['srcPort']?.toString(),
      destPort: json['destPort']?.toString(),
      protocol: json['protocol'] as String?,
      strategy: json['strategy'] as String?,
      usedStatus: json['usedStatus'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (family != null) 'family': family,
      if (address != null) 'address': address,
      if (destination != null) 'destination': destination,
      if (port != null) 'port': port,
      if (srcPort != null) 'srcPort': srcPort,
      if (destPort != null) 'destPort': destPort,
      if (protocol != null) 'protocol': protocol,
      if (strategy != null) 'strategy': strategy,
      if (usedStatus != null) 'usedStatus': usedStatus,
      if (description != null) 'description': description,
    };
  }

  @override
  List<Object?> get props => [
        id,
        family,
        address,
        destination,
        port,
        srcPort,
        destPort,
        protocol,
        strategy,
        usedStatus,
        description,
      ];
}

class FirewallRuleSearch extends Equatable {
  const FirewallRuleSearch({
    this.page = 1,
    this.pageSize = 20,
    this.type,
    this.strategy,
    this.info,
  });

  final int page;
  final int pageSize;
  final String? type;
  final String? strategy;
  final String? info;

  factory FirewallRuleSearch.fromJson(Map<String, dynamic> json) {
    return FirewallRuleSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      type: json['type'] as String?,
      strategy: json['strategy'] as String?,
      info: json['info'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final result = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (type != null && type!.isNotEmpty) {
      result['type'] = type;
    }
    if (strategy != null && strategy!.isNotEmpty) {
      result['strategy'] = strategy;
    }
    if (info != null && info!.isNotEmpty) {
      result['info'] = info;
    }
    return result;
  }

  @override
  List<Object?> get props => [page, pageSize, type, strategy, info];
}

class FirewallOperation extends Equatable {
  const FirewallOperation({
    required this.operation,
    this.withDockerRestart = false,
  });

  final String operation;
  final bool withDockerRestart;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'withDockerRestart': withDockerRestart,
    };
  }

  @override
  List<Object?> get props => [operation, withDockerRestart];
}

enum FirewallRuleKind {
  rule('rule'),
  ip('address'),
  port('port');

  const FirewallRuleKind(this.value);
  final String value;
}

class FirewallPortRulePayload extends Equatable {
  const FirewallPortRulePayload({
    required this.operation,
    required this.address,
    required this.port,
    required this.source,
    required this.protocol,
    required this.strategy,
    this.description,
    this.chain,
  });

  final String operation;
  final String address;
  final String port;
  final String source;
  final String protocol;
  final String strategy;
  final String? description;
  final String? chain;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'address': address,
      'port': port,
      'source': source,
      'protocol': protocol,
      'strategy': strategy,
      if (description != null) 'description': description,
      if (chain != null) 'chain': chain,
    };
  }

  @override
  List<Object?> get props => [
        operation,
        address,
        port,
        source,
        protocol,
        strategy,
        description,
        chain,
      ];
}

class FirewallIpRulePayload extends Equatable {
  const FirewallIpRulePayload({
    required this.operation,
    required this.address,
    required this.strategy,
    this.description,
  });

  final String operation;
  final String address;
  final String strategy;
  final String? description;

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'address': address,
      'strategy': strategy,
      if (description != null) 'description': description,
    };
  }

  @override
  List<Object?> get props => [operation, address, strategy, description];
}

class FirewallUpdatePortRequest extends Equatable {
  const FirewallUpdatePortRequest({
    required this.oldRule,
    required this.newRule,
  });

  final FirewallPortRulePayload oldRule;
  final FirewallPortRulePayload newRule;

  Map<String, dynamic> toJson() {
    return {
      'oldRule': oldRule.toJson(),
      'newRule': newRule.toJson(),
    };
  }

  @override
  List<Object?> get props => [oldRule, newRule];
}

class FirewallUpdateIpRequest extends Equatable {
  const FirewallUpdateIpRequest({
    required this.oldRule,
    required this.newRule,
  });

  final FirewallIpRulePayload oldRule;
  final FirewallIpRulePayload newRule;

  Map<String, dynamic> toJson() {
    return {
      'oldRule': oldRule.toJson(),
      'newRule': newRule.toJson(),
    };
  }

  @override
  List<Object?> get props => [oldRule, newRule];
}

class FirewallDescriptionUpdate extends Equatable {
  const FirewallDescriptionUpdate({
    required this.type,
    required this.description,
    this.chain = '',
    this.srcIP = '',
    this.dstIP = '',
    this.srcPort = '',
    this.dstPort = '',
    this.protocol = '',
    this.strategy = '',
  });

  final String type;
  final String description;
  final String chain;
  final String srcIP;
  final String dstIP;
  final String srcPort;
  final String dstPort;
  final String protocol;
  final String strategy;

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'chain': chain,
      'srcIP': srcIP,
      'dstIP': dstIP,
      'srcPort': srcPort,
      'dstPort': dstPort,
      'protocol': protocol,
      'strategy': strategy,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
        type,
        description,
        chain,
        srcIP,
        dstIP,
        srcPort,
        dstPort,
        protocol,
        strategy,
      ];
}

class FirewallBatchRuleRequest extends Equatable {
  const FirewallBatchRuleRequest({
    required this.type,
    required this.rules,
  });

  final String type;
  final List<Map<String, dynamic>> rules;

  Map<String, dynamic> toJson() => {
        'type': type,
        'rules': rules,
      };

  @override
  List<Object?> get props => [type, rules];
}
