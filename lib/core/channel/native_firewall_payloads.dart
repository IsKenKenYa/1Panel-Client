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