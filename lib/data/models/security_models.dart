import 'package:equatable/equatable.dart';

/// Security scan request model
class SecurityScan extends Equatable {
  final String scanType;
  final String? target;
  final Map<String, dynamic>? options;
  final bool? autoFix;

  const SecurityScan({
    required this.scanType,
    this.target,
    this.options,
    this.autoFix,
  });

  factory SecurityScan.fromJson(Map<String, dynamic> json) {
    return SecurityScan(
      scanType: json['scanType'] as String,
      target: json['target'] as String?,
      options: json['options'] as Map<String, dynamic>?,
      autoFix: json['autoFix'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanType': scanType,
      'target': target,
      'options': options,
      'autoFix': autoFix,
    };
  }

  @override
  List<Object?> get props => [scanType, target, options, autoFix];
}

/// Security scan result model
class SecurityScanResult extends Equatable {
  final int? id;
  final String? scanType;
  final String? target;
  final String? status;
  final List<SecurityIssue>? issues;
  final String? startTime;
  final String? endTime;
  final String? createTime;

  const SecurityScanResult({
    this.id,
    this.scanType,
    this.target,
    this.status,
    this.issues,
    this.startTime,
    this.endTime,
    this.createTime,
  });

  factory SecurityScanResult.fromJson(Map<String, dynamic> json) {
    return SecurityScanResult(
      id: json['id'] as int?,
      scanType: json['scanType'] as String?,
      target: json['target'] as String?,
      status: json['status'] as String?,
      issues: (json['issues'] as List?)
          ?.map((item) => SecurityIssue.fromJson(item as Map<String, dynamic>))
          .toList(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scanType': scanType,
      'target': target,
      'status': status,
      'issues': issues?.map((issue) => issue.toJson()).toList(),
      'startTime': startTime,
      'endTime': endTime,
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props =>
      [id, scanType, target, status, issues, startTime, endTime, createTime];
}

/// Security issue model
class SecurityIssue extends Equatable {
  final String? severity;
  final String? type;
  final String? title;
  final String? description;
  final String? affectedResource;
  final String? recommendation;
  final String? cveId;
  final String? cvssScore;

  const SecurityIssue({
    this.severity,
    this.type,
    this.title,
    this.description,
    this.affectedResource,
    this.recommendation,
    this.cveId,
    this.cvssScore,
  });

  factory SecurityIssue.fromJson(Map<String, dynamic> json) {
    return SecurityIssue(
      severity: json['severity'] as String?,
      type: json['type'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      affectedResource: json['affectedResource'] as String?,
      recommendation: json['recommendation'] as String?,
      cveId: json['cveId'] as String?,
      cvssScore: json['cvssScore'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'severity': severity,
      'type': type,
      'title': title,
      'description': description,
      'affectedResource': affectedResource,
      'recommendation': recommendation,
      'cveId': cveId,
      'cvssScore': cvssScore,
    };
  }

  @override
  List<Object?> get props => [
        severity,
        type,
        title,
        description,
        affectedResource,
        recommendation,
        cveId,
        cvssScore
      ];
}

/// Intrusion detection rule model
class IntrusionRule extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? pattern;
  final String? action;
  final bool? enabled;
  final String? severity;
  final String? description;
  final String? createTime;
  final String? updateTime;

  const IntrusionRule({
    this.id,
    this.name,
    this.type,
    this.pattern,
    this.action,
    this.enabled,
    this.severity,
    this.description,
    this.createTime,
    this.updateTime,
  });

  factory IntrusionRule.fromJson(Map<String, dynamic> json) {
    return IntrusionRule(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      pattern: json['pattern'] as String?,
      action: json['action'] as String?,
      enabled: json['enabled'] as bool?,
      severity: json['severity'] as String?,
      description: json['description'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'pattern': pattern,
      'action': action,
      'enabled': enabled,
      'severity': severity,
      'description': description,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        pattern,
        action,
        enabled,
        severity,
        description,
        createTime,
        updateTime
      ];
}

/// Intrusion event model
class IntrusionEvent extends Equatable {
  final int? id;
  final String? sourceIp;
  final String? target;
  final String? type;
  final String? severity;
  final String? description;
  final String? ruleId;
  final String? ruleName;
  final String? timestamp;
  final bool? blocked;

  const IntrusionEvent({
    this.id,
    this.sourceIp,
    this.target,
    this.type,
    this.severity,
    this.description,
    this.ruleId,
    this.ruleName,
    this.timestamp,
    this.blocked,
  });

  factory IntrusionEvent.fromJson(Map<String, dynamic> json) {
    return IntrusionEvent(
      id: json['id'] as int?,
      sourceIp: json['sourceIp'] as String?,
      target: json['target'] as String?,
      type: json['type'] as String?,
      severity: json['severity'] as String?,
      description: json['description'] as String?,
      ruleId: json['ruleId'] as String?,
      ruleName: json['ruleName'] as String?,
      timestamp: json['timestamp'] as String?,
      blocked: json['blocked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceIp': sourceIp,
      'target': target,
      'type': type,
      'severity': severity,
      'description': description,
      'ruleId': ruleId,
      'ruleName': ruleName,
      'timestamp': timestamp,
      'blocked': blocked,
    };
  }

  @override
  List<Object?> get props => [
        id,
        sourceIp,
        target,
        type,
        severity,
        description,
        ruleId,
        ruleName,
        timestamp,
        blocked
      ];
}

/// Access control rule model
class AccessControlRule extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? source;
  final String? target;
  final String? action;
  final String? protocol;
  final int? port;
  final bool? enabled;
  final String? createTime;
  final String? updateTime;

  const AccessControlRule({
    this.id,
    this.name,
    this.type,
    this.source,
    this.target,
    this.action,
    this.protocol,
    this.port,
    this.enabled,
    this.createTime,
    this.updateTime,
  });

  factory AccessControlRule.fromJson(Map<String, dynamic> json) {
    return AccessControlRule(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      source: json['source'] as String?,
      target: json['target'] as String?,
      action: json['action'] as String?,
      protocol: json['protocol'] as String?,
      port: json['port'] as int?,
      enabled: json['enabled'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'source': source,
      'target': target,
      'action': action,
      'protocol': protocol,
      'port': port,
      'enabled': enabled,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        source,
        target,
        action,
        protocol,
        port,
        enabled,
        createTime,
        updateTime
      ];
}

/// Security status model
class SecurityStatus extends Equatable {
  final bool? firewallEnabled;
  final bool? intrusionDetectionEnabled;
  final bool? autoScanEnabled;
  final int? scanInterval;
  final int? lastScanTime;
  final int? threatsDetected;
  final int? blockedAttacks;

  const SecurityStatus({
    this.firewallEnabled,
    this.intrusionDetectionEnabled,
    this.autoScanEnabled,
    this.scanInterval,
    this.lastScanTime,
    this.threatsDetected,
    this.blockedAttacks,
  });

  factory SecurityStatus.fromJson(Map<String, dynamic> json) {
    return SecurityStatus(
      firewallEnabled: json['firewallEnabled'] as bool?,
      intrusionDetectionEnabled: json['intrusionDetectionEnabled'] as bool?,
      autoScanEnabled: json['autoScanEnabled'] as bool?,
      scanInterval: json['scanInterval'] as int?,
      lastScanTime: json['lastScanTime'] as int?,
      threatsDetected: json['threatsDetected'] as int?,
      blockedAttacks: json['blockedAttacks'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firewallEnabled': firewallEnabled,
      'intrusionDetectionEnabled': intrusionDetectionEnabled,
      'autoScanEnabled': autoScanEnabled,
      'scanInterval': scanInterval,
      'lastScanTime': lastScanTime,
      'threatsDetected': threatsDetected,
      'blockedAttacks': blockedAttacks,
    };
  }

  @override
  List<Object?> get props => [
        firewallEnabled,
        intrusionDetectionEnabled,
        autoScanEnabled,
        scanInterval,
        lastScanTime,
        threatsDetected,
        blockedAttacks
      ];
}

/// Security configuration model
class SecurityConfig extends Equatable {
  final bool? enableFirewall;
  final bool? enableIntrusionDetection;
  final bool? enableAutoScan;
  final int? scanInterval;
  final String? scanType;
  final bool? enableNotifications;
  final String? notificationEmail;
  final Map<String, dynamic>? customRules;

  const SecurityConfig({
    this.enableFirewall,
    this.enableIntrusionDetection,
    this.enableAutoScan,
    this.scanInterval,
    this.scanType,
    this.enableNotifications,
    this.notificationEmail,
    this.customRules,
  });

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      enableFirewall: json['enableFirewall'] as bool?,
      enableIntrusionDetection: json['enableIntrusionDetection'] as bool?,
      enableAutoScan: json['enableAutoScan'] as bool?,
      scanInterval: json['scanInterval'] as int?,
      scanType: json['scanType'] as String?,
      enableNotifications: json['enableNotifications'] as bool?,
      notificationEmail: json['notificationEmail'] as String?,
      customRules: json['customRules'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableFirewall': enableFirewall,
      'enableIntrusionDetection': enableIntrusionDetection,
      'enableAutoScan': enableAutoScan,
      'scanInterval': scanInterval,
      'scanType': scanType,
      'enableNotifications': enableNotifications,
      'notificationEmail': notificationEmail,
      'customRules': customRules,
    };
  }

  @override
  List<Object?> get props => [
        enableFirewall,
        enableIntrusionDetection,
        enableAutoScan,
        scanInterval,
        scanType,
        enableNotifications,
        notificationEmail,
        customRules
      ];
}

/// Security log model
class SecurityLog extends Equatable {
  final int? id;
  final String? level;
  final String? type;
  final String? message;
  final String? source;
  final String? target;
  final String? details;
  final String? timestamp;

  const SecurityLog({
    this.id,
    this.level,
    this.type,
    this.message,
    this.source,
    this.target,
    this.details,
    this.timestamp,
  });

  factory SecurityLog.fromJson(Map<String, dynamic> json) {
    return SecurityLog(
      id: json['id'] as int?,
      level: json['level'] as String?,
      type: json['type'] as String?,
      message: json['message'] as String?,
      source: json['source'] as String?,
      target: json['target'] as String?,
      details: json['details'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level,
      'type': type,
      'message': message,
      'source': source,
      'target': target,
      'details': details,
      'timestamp': timestamp,
    };
  }

  @override
  List<Object?> get props =>
      [id, level, type, message, source, target, details, timestamp];
}
