import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'common_models.dart';
import 'firewall_models.dart';

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

class FirewallInventoryScope extends Equatable {
  const FirewallInventoryScope({
    required this.provider,
    required this.family,
    this.table,
    this.zone,
    this.chain,
  });

  final String provider;
  final String family;
  final String? table;
  final String? zone;
  final String? chain;

  Map<String, dynamic> toJson() => {
        'provider': provider,
        'family': family,
        'direction': 'input',
        if (table != null) 'table': table,
        if (zone != null) 'zone': zone,
        if (chain != null) 'chain': chain,
      };

  @override
  List<Object?> get props => [provider, family, table, zone, chain];
}

class FirewallRuleInventoryRequest extends Equatable {
  final int page;
  final int pageSize;
  final String? info;
  final bool? all;
  final List<FirewallInventoryScope>? scopes;
  final List<String>? families;
  final List<String>? actions;
  final List<String>? excludeChains;
  final FirewallInventoryScope? scope;

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

  factory FirewallRuleInventoryRequest.forSearch(
    FirewallRuleSearch search, {
    required String provider,
    bool all = false,
  }) {
    final scopes = switch (provider) {
      'iptables' || 'nftables' => [
          for (final family in ['ipv4', 'ipv6'])
            for (final chain in [
              '1PANEL_BASIC_BEFORE',
              '1PANEL_BASIC',
              '1PANEL_BASIC_AFTER',
            ])
              FirewallInventoryScope(
                provider: provider,
                family: family,
                table: 'filter',
                chain: chain,
              ),
        ],
      'firewalld' => const [
          FirewallInventoryScope(
            provider: 'firewalld',
            family: 'inet',
            zone: 'public',
          ),
        ],
      'ufw' => const [
          FirewallInventoryScope(
            provider: 'ufw',
            family: 'inet',
            chain: 'incoming',
          ),
        ],
      _ => throw StateError('Unsupported firewall provider: $provider'),
    };
    final actions = switch (search.strategy) {
      'accept' => const ['accept'],
      'drop' || 'reject' || 'deny' => const ['deny'],
      _ => null,
    };
    return FirewallRuleInventoryRequest(
      page: search.page,
      pageSize: search.pageSize,
      info: search.info,
      all: all || _filtersFirewallRuleType(search.type) ? true : null,
      scopes: scopes,
      actions: actions,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (info != null) json['info'] = info;
    if (all != null) json['all'] = all;
    if (scopes != null) {
      json['scopes'] = [for (final scope in scopes!) scope.toJson()];
    }
    if (families != null) json['families'] = families;
    if (actions != null) json['actions'] = actions;
    if (excludeChains != null) json['excludeChains'] = excludeChains;
    if (scope != null) json['scope'] = scope!.toJson();
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

class FirewallInventoryPageResult extends PageResult<FirewallRule> {
  const FirewallInventoryPageResult({
    required super.items,
    required super.total,
    required super.page,
    required super.pageSize,
    required super.totalPages,
  });
}

class FirewallRuleInventoryResponse {
  const FirewallRuleInventoryResponse(
      {required this.items, required this.total});

  final List<FirewallRule> items;
  final int total;

  factory FirewallRuleInventoryResponse.fromJson(
    Map<String, dynamic> json, {
    String? serverId,
  }) {
    return FirewallRuleInventoryResponse(
      items: [
        for (final item in json['items'] as List? ?? const [])
          _ruleFromInventory(item as Map<String, dynamic>, serverId),
      ],
      total: json['total'] as int,
    );
  }

  FirewallInventoryPageResult pageFor(FirewallRuleSearch search) {
    var pageItems = items;
    var count = total;
    if (_filtersFirewallRuleType(search.type)) {
      final portRules = search.type == 'port';
      final matching = items.where((rule) {
        final hasPort = rule.port?.isNotEmpty == true;
        return portRules
            ? hasPort
            : !hasPort && rule.address?.isNotEmpty == true;
      }).toList();
      count = matching.length;
      pageItems = matching
          .skip((search.page - 1) * search.pageSize)
          .take(search.pageSize)
          .toList();
    }
    return FirewallInventoryPageResult(
      items: pageItems,
      total: count,
      page: search.page,
      pageSize: search.pageSize,
      totalPages: math.max(1, (count / search.pageSize).ceil()),
    );
  }

  static FirewallRule _ruleFromInventory(
    Map<String, dynamic> item,
    String? serverId,
  ) {
    final rule = item['rule'] as Map<String, dynamic>;
    final observed = item['observed'] as Map<String, dynamic>?;
    final scope = rule['scope'] as Map<String, dynamic>?;
    final address = rule['sourceAddress'] as String?;
    final destination = rule['destinationAddress'] as String?;
    final port = rule['destinationPort'] as String?;
    final protocol = rule['protocol'] as String?;
    final instanceKey = observed?['instanceKey'] as String?;
    final target = _deletionTarget(item, scope, observed, instanceKey);
    return FirewallRule(
      inventoryId: instanceKey?.isNotEmpty == true
          ? instanceKey
          : target?.uuid ?? rule['uuid'] as String?,
      serverId: serverId,
      modernTarget: target,
      supportsLegacyChanges: false,
      chain: scope?['chain'] as String?,
      family: scope?['family'] as String?,
      address: address,
      srcIP: address,
      destination: destination,
      dstIP: destination,
      port: port,
      destPort: port,
      srcPort: rule['sourcePort'] as String?,
      protocol: scope?['provider'] == 'ufw' &&
              protocol == 'all' &&
              port?.isNotEmpty == true
          ? 'tcp/udp'
          : protocol,
      strategy: rule['action'] as String?,
      interface: rule['interface'] as String?,
      description: rule['description'] as String?,
    );
  }

  static FirewallInventoryDeletionTarget? _deletionTarget(
    Map<String, dynamic> item,
    Map<String, dynamic>? scope,
    Map<String, dynamic>? observed,
    String? instanceKey,
  ) {
    if (item['isWhitelist'] == false &&
        scope != null &&
        scope['provider'] is String &&
        scope['family'] is String &&
        observed?['locator'] is Map &&
        observed?['rule'] is Map &&
        observed?['protected'] == false &&
        instanceKey != null &&
        instanceKey.isNotEmpty) {
      return FirewallInventoryDeletionTarget.observed(
        instanceKey: instanceKey,
        scope: scope,
        observed: observed!,
      );
    }
    final desired = item['desired'];
    if (item['isWhitelist'] == null &&
        (item['state'] == 'managed' || item['state'] == 'adopted') &&
        item['match'] == 'exact' &&
        observed?['protected'] == false &&
        desired is Map &&
        desired['protected'] != true &&
        desired['expanded'] != true) {
      final uuid = desired['uuid'];
      if (uuid is String && uuid.isNotEmpty) {
        return FirewallInventoryDeletionTarget.managed(uuid);
      }
    }
    return null;
  }
}

bool _filtersFirewallRuleType(String? type) =>
    type == 'port' || type == 'address';

class FirewallRuleCreateRequest extends Equatable {
  final List<Map<String, dynamic>>? items;
  final bool? initialize;
  final String? backupFile;

  const FirewallRuleCreateRequest({
    this.items,
    this.initialize,
    this.backupFile,
  });

  factory FirewallRuleCreateRequest.forInboundRule({
    String sourceAddress = '',
    String? destinationPort,
    String protocol = 'all',
    required String action,
    String? description,
  }) {
    final address = sourceAddress.trim();
    if (address.isEmpty && destinationPort == null) {
      throw const FormatException('Enter a specific source address.');
    }
    final Iterable<({String address, String? family})> sources = address.isEmpty
        ? const <({String address, String? family})>[
            (address: '', family: null)
          ]
        : address.split(',').map<({String address, String? family})>((part) {
            final input = part.trim();
            return (address: input, family: _addressFamily(input));
          });
    if (!const {'accept', 'drop', 'reject'}.contains(action)) {
      throw const FormatException('Select a valid firewall action.');
    }
    final protocols = switch (protocol) {
      'tcp/udp' => const ['tcp', 'udp'],
      'all' || 'tcp' || 'udp' => [protocol],
      _ => throw const FormatException('Select a valid firewall protocol.'),
    };
    String? port;
    if (destinationPort != null) {
      final ranges = destinationPort.split(',');
      port = ranges.map((range) {
        final limits = range
            .split(RegExp('[-:]'))
            .map((value) => int.tryParse(value.trim(), radix: 10))
            .toList();
        if (limits.length > 2 ||
            limits
                .any((value) => value == null || value < 1 || value > 65535) ||
            limits.first! > limits.last!) {
          throw const FormatException('Enter a valid port or port range.');
        }
        return limits.join('-');
      }).join(',');
    }
    final text = description?.trim();
    return FirewallRuleCreateRequest(items: [
      for (final source in sources)
        for (final protocol in protocols)
          {
            'rule': {
              'protocol': protocol,
              'action': action,
              if (source.family != null) ...{
                'sourceAddress': source.address,
                'scope': {'family': source.family},
              },
              if (port != null) 'destinationPort': port,
              if (text != null && text.isNotEmpty) 'description': text,
            },
            'sourceKind': 'user',
          },
    ]);
  }

  static String _addressFamily(String address) {
    final parts = address.split('/');
    final host = parts.first;
    final isIPv6 = host.contains(':');
    final bytes =
        isIPv6 ? Uri.parseIPv6Address(host) : Uri.parseIPv4Address(host);
    final isMappedIPv4 = isIPv6 &&
        bytes.take(10).every((byte) => byte == 0) &&
        bytes[10] == 255 &&
        bytes[11] == 255;
    if (parts.length != 1) {
      final prefix = int.tryParse(parts.last, radix: 10);
      if (parts.length != 2 ||
          prefix == null ||
          prefix < (isMappedIPv4 ? 96 : 0) ||
          prefix > bytes.length * 8) {
        throw const FormatException('Enter a valid source address prefix.');
      }
    }
    return isIPv6 && !isMappedIPv4 ? 'ipv6' : 'ipv4';
  }

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
  final List<Map<String, dynamic>>? targets;
  final List<String>? uuids;

  const FirewallRuleDeleteRequest(
      {required List<Map<String, dynamic>> this.targets})
      : uuids = null;

  const FirewallRuleDeleteRequest.managed(List<String> this.uuids)
      : targets = null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (targets != null) 'targets': targets,
        if (uuids != null) 'uuids': uuids,
      };

  @override
  List<Object?> get props => [targets, uuids];
}

class FirewallRuleUpdateRequest extends Equatable {
  final String instanceKey;
  // 服务端 filter.Scope 是嵌套对象，不是字符串。
  final Map<String, dynamic> scope;
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
  List<Object?> get props => [backup, provider, subsystem, withDockerRestart];
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
