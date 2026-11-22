import 'dart:convert';

import '../../data/models/firewall_models.dart';

/// 防火墙通道返回结构。
///
/// 规则字段、基础状态与 V2 分区数据在 Dart 侧整理，原生界面只负责展示。

Map<String, Object?> firewallBasePayload(FirewallBaseInfo info) {
  return <String, Object?>{
    'name': info.name,
    'isExist': info.isExist,
    'isActive': info.isActive,
    'isInit': info.isInit,
    'isBind': info.isBind,
    'version': info.version,
    'pingStatus': info.pingStatus,
  };
}

/// 规则列表：端口与 IP 共用同一字段形状。
List<Map<String, Object?>> firewallRulePayloads(
  List<FirewallRule> rules, {
  String? serverId,
}) {
  final inventoryCounts = <String, int>{};
  for (final rule in rules) {
    final id = rule.inventoryId;
    if (id != null) {
      inventoryCounts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
  }
  final usedIds = <String>{};
  return rules.indexed.map((entry) {
    final (index, rule) = entry;
    final Object? id = rule.inventoryId ?? (rule.id == 0 ? null : rule.id);
    return <String, Object?>{
      'id': id != null && usedIds.add(id.toString()) ? id : 'row-$index',
      'inventoryId': rule.inventoryId,
      'serverId': serverId,
      'canDelete': rule.canDelete &&
          (rule.supportsLegacyChanges ||
              inventoryCounts[rule.inventoryId] == 1),
      'family': rule.family ?? '',
      'chain': rule.chain ?? '',
      'protocol': rule.protocol ?? '',
      'port': rule.port ?? '',
      'address': rule.address ?? '',
      'strategy': rule.strategy ?? '',
      'description': rule.description ?? '',
      'supportsLegacyChanges': rule.supportsLegacyChanges,
    };
  }).toList(growable: false);
}

/// V2 分区数据：键值对平铺，嵌套结构转成 JSON 文本。
Map<String, String> firewallFlatPayload(Map<String, dynamic> data) {
  final result = <String, String>{};
  for (final entry in data.entries) {
    final value = entry.value;
    if (value == null) {
      result[entry.key] = '';
    } else if (value is String) {
      result[entry.key] = value;
    } else if (value is num || value is bool) {
      result[entry.key] = '$value';
    } else {
      result[entry.key] = jsonEncode(value);
    }
  }
  return result;
}

/// V2 转发分区：基础信息平铺并附结构化转发规则。
Map<String, Object?> firewallForwardPayload(
  Map<String, dynamic> base,
  Map<String, dynamic> rules,
) {
  final items = (rules['items'] as List? ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
  final ruleRows = items.indexed.map((entry) {
    final (index, item) = entry;
    final rawId = item['id'];
    final hasId = rawId is num ||
        (rawId is String && rawId.trim().isNotEmpty);
    return <String, Object?>{
      'id': hasId ? rawId : 'row-$index',
      'num': '${item['num'] ?? ''}',
      'family': '${item['family'] ?? ''}',
      'chain': '${item['chain'] ?? ''}',
      'protocol': '${item['protocol'] ?? ''}',
      'port': '${item['port'] ?? ''}',
      'address': '${item['address'] ?? ''}',
      'targetIP': '${item['targetIP'] ?? ''}',
      'targetPort': '${item['targetPort'] ?? ''}',
      'interface': '${item['interface'] ?? ''}',
      'strategy': '${item['strategy'] ?? ''}',
      'description': '${item['description'] ?? ''}',
      'usedStatus': '${item['usedStatus'] ?? ''}',
      'syncStatus': '${item['syncStatus'] ?? ''}',
      'isDesired': item['isDesired'] == true,
      'isRuntime': item['isRuntime'] == true,
    };
  }).toList(growable: false);
  final total = rules['total'];
  return <String, Object?>{
    ...firewallFlatPayload(base),
    'rules': ruleRows,
    'total': total is num ? total : ruleRows.length,
  };
}

/// V2 Docker 分区：基础信息平铺并附策略与发布端口。
Map<String, Object?> firewallDockerPayload(
  Map<String, dynamic> ports,
  List<dynamic> endpoints,
) {
  final containers = (ports['containers'] as List? ?? endpoints)
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList(growable: false);
  final policyRows = <Map<String, Object?>>[];
  final publishedRows = <Map<String, Object?>>[];
  final seenPolicies = <String>{};
  final seenPublished = <String>{};

  void collect(List<dynamic> source) {
    for (final raw in source.whereType<Map>()) {
      final endpoint = raw.cast<String, dynamic>();
      final hostIP = '${endpoint['hostIP'] ?? ''}';
      final hostPort = '${endpoint['hostPort'] ?? ''}';
      final protocolName = '${endpoint['protocol'] ?? ''}';
      final containerName = '${endpoint['containerName'] ?? ''}';
      final publishedKey =
          '$containerName|$hostIP|$hostPort|$protocolName|${endpoint['family'] ?? ''}';
      if (seenPublished.add(publishedKey)) {
        publishedRows.add(<String, Object?>{
          'id': 'published-${publishedRows.length}',
          'containerName': containerName,
          'containerState': '${endpoint['containerState'] ?? ''}',
          'application': '${endpoint['application'] ?? ''}',
          'compose': '${endpoint['compose'] ?? ''}',
          'family': '${endpoint['family'] ?? ''}',
          'hostIP': hostIP,
          'hostPort': hostPort,
          'containerPort': '${endpoint['containerPort'] ?? ''}',
          'protocol': protocolName,
          'mode': '${endpoint['mode'] ?? ''}',
          'effective': endpoint['effective'] == true,
          'trafficPath': '${endpoint['trafficPath'] ?? ''}',
        });
      }
      final policyUUID = '${endpoint['policyUUID'] ?? ''}'.trim();
      if (policyUUID.isEmpty || !seenPolicies.add(policyUUID)) {
        continue;
      }
      policyRows.add(<String, Object?>{
        'id': policyUUID,
        'hostIP': hostIP,
        'hostPort': hostPort,
        'family': '${endpoint['family'] ?? ''}',
        'protocol': protocolName,
        'mode': '${endpoint['mode'] ?? ''}',
        'sources': [
          for (final source in endpoint['sources'] as List? ?? const [])
            '$source',
        ],
        'containerName': containerName,
        'containerState': '${endpoint['containerState'] ?? ''}',
        'application': '${endpoint['application'] ?? ''}',
        'compose': '${endpoint['compose'] ?? ''}',
        'trafficPath': '${endpoint['trafficPath'] ?? ''}',
        'managementTarget': '${endpoint['managementTarget'] ?? ''}',
        'effective': endpoint['effective'] == true,
      });
    }
  }

  for (final container in containers) {
    collect(container['endpoints'] as List? ?? const <dynamic>[]);
  }
  collect(ports['orphanPolicies'] as List? ?? const <dynamic>[]);

  final base = ports['base'];
  return <String, Object?>{
    ...firewallFlatPayload(
      base is Map ? base.cast<String, dynamic>() : const <String, dynamic>{},
    ),
    'policies': policyRows,
    'publishedPorts': publishedRows,
  };
}

/// V2 设置分区：配置平铺并附端口白名单与后端分组。
Map<String, Object?> firewallSettingsPayload(Map<String, dynamic> settings) {
  final whitelist =
      (settings['portWhiteList'] as List? ?? const <dynamic>[])
          .whereType<Map>()
          .map((row) => row.cast<String, dynamic>())
          .indexed
          .map((entry) {
            final (index, rule) = entry;
            return <String, Object?>{
              'id': 'whitelist-$index',
              'port': '${rule['port'] ?? ''}',
              'protocol': '${rule['protocol'] ?? ''}',
              'type': '${rule['type'] ?? ''}',
              'sources': [
                for (final source in rule['sources'] as List? ?? const [])
                  '$source',
              ],
            };
          })
          .toList(growable: false);
  final backends = <Map<String, Object?>>[];
  for (final subsystem in const ['system', 'forwarding', 'docker']) {
    final group = settings[subsystem];
    if (group is! Map) continue;
    final options = (group['options'] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((option) => option.cast<String, dynamic>())
        .map((option) => <String, Object?>{
              'name': '${option['name'] ?? ''}',
              'installed': option['installed'] == true,
              'active': option['active'] == true,
              'initialized': option['initialized'] == true,
              'bound': option['bound'] == true,
              'supported': option['supported'] == true,
              'message': '${option['message'] ?? ''}',
            })
        .toList(growable: false);
    backends.add(<String, Object?>{
      'subsystem': subsystem,
      'selected': '${group['selected'] ?? ''}',
      'current': '${group['current'] ?? ''}',
      'options': options,
    });
  }
  return <String, Object?>{
    ...firewallFlatPayload(settings),
    'whitelist': whitelist,
    'backends': backends,
  };
}

/// 从规则通道字段组装端口规则更新请求。
FirewallUpdatePortRequest firewallPortUpdateRequest(Map arguments) {
  return FirewallUpdatePortRequest(
    oldRule: _portPayload(arguments['oldRule']),
    newRule: _portPayload(arguments['newRule']),
  );
}

FirewallPortRulePayload _portPayload(Object? value) {
  final map = value is Map ? value : const <String, dynamic>{};
  return FirewallPortRulePayload(
    operation: '${map['operation'] ?? 'edit'}',
    address: '${map['address'] ?? ''}',
    port: '${map['port'] ?? ''}',
    source: '${map['source'] ?? ''}',
    protocol: '${map['protocol'] ?? ''}',
    strategy: '${map['strategy'] ?? ''}',
    description: '${map['description'] ?? ''}',
    chain: '${map['chain'] ?? ''}'.isEmpty ? null : '${map['chain']}',
  );
}

FirewallUpdateIpRequest firewallIpUpdateRequest(Map arguments) {
  return FirewallUpdateIpRequest(
    oldRule: _ipPayload(arguments['oldRule']),
    newRule: _ipPayload(arguments['newRule']),
  );
}

FirewallIpRulePayload _ipPayload(Object? value) {
  final map = value is Map ? value : const <String, dynamic>{};
  return FirewallIpRulePayload(
    operation: '${map['operation'] ?? 'edit'}',
    address: '${map['address'] ?? ''}',
    strategy: '${map['strategy'] ?? ''}',
    description: '${map['description'] ?? ''}',
  );
}

FirewallDescriptionUpdate firewallDescriptionUpdate(Map arguments) {
  return FirewallDescriptionUpdate(
    type: '${arguments['type'] ?? 'port'}',
    description: '${arguments['description'] ?? ''}',
    chain: '${arguments['chain'] ?? ''}',
    srcIP: '${arguments['srcIP'] ?? ''}',
    dstIP: '${arguments['dstIP'] ?? ''}',
    srcPort: '${arguments['srcPort'] ?? ''}',
    dstPort: '${arguments['dstPort'] ?? ''}',
    protocol: '${arguments['protocol'] ?? ''}',
    strategy: '${arguments['strategy'] ?? ''}',
  );
}