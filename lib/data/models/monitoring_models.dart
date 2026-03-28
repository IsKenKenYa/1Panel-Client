import 'package:equatable/equatable.dart';

/// Metric type enumeration
enum MetricType {
  cpu('cpu'),
  memory('memory'),
  disk('disk'),
  network('network'),
  load('load'),
  uptime('uptime');

  const MetricType(this.value);
  final String value;

  static MetricType fromString(String value) {
    return MetricType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MetricType.cpu,
    );
  }
}

/// Alert level enumeration
enum AlertLevel {
  info('info'),
  warning('warning'),
  error('error'),
  critical('critical');

  const AlertLevel(this.value);
  final String value;

  static AlertLevel fromString(String value) {
    return AlertLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => AlertLevel.info,
    );
  }
}

/// Metric data point model
class MetricDataPoint extends Equatable {
  final String? timestamp;
  final double? value;
  final Map<String, dynamic>? tags;

  const MetricDataPoint({
    this.timestamp,
    this.value,
    this.tags,
  });

  factory MetricDataPoint.fromJson(Map<String, dynamic> json) {
    return MetricDataPoint(
      timestamp: json['timestamp'] as String?,
      value: (json['value'] as num?)?.toDouble(),
      tags: json['tags'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'value': value,
      'tags': tags,
    };
  }

  @override
  List<Object?> get props => [timestamp, value, tags];
}

/// System metrics model
class SystemMetrics extends Equatable {
  final MetricType? type;
  final String? unit;
  final List<MetricDataPoint>? dataPoints;
  final double? min;
  final double? max;
  final double? avg;
  final double? current;

  const SystemMetrics({
    this.type,
    this.unit,
    this.dataPoints,
    this.min,
    this.max,
    this.avg,
    this.current,
  });

  factory SystemMetrics.fromJson(Map<String, dynamic> json) {
    return SystemMetrics(
      type: json['type'] != null
          ? MetricType.fromString(json['type'] as String)
          : null,
      unit: json['unit'] as String?,
      dataPoints: (json['dataPoints'] as List?)
          ?.map(
              (item) => MetricDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      avg: (json['avg'] as num?)?.toDouble(),
      current: (json['current'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type?.value,
      'unit': unit,
      'dataPoints': dataPoints?.map((point) => point.toJson()).toList(),
      'min': min,
      'max': max,
      'avg': avg,
      'current': current,
    };
  }

  @override
  List<Object?> get props => [type, unit, dataPoints, min, max, avg, current];
}

/// CPU metrics model
class CPUMetrics extends Equatable {
  final double? usagePercent;
  final double? loadAverage1m;
  final double? loadAverage5m;
  final double? loadAverage15m;
  final int? cores;
  final List<CPUCoreMetrics>? coreMetrics;

  const CPUMetrics({
    this.usagePercent,
    this.loadAverage1m,
    this.loadAverage5m,
    this.loadAverage15m,
    this.cores,
    this.coreMetrics,
  });

  factory CPUMetrics.fromJson(Map<String, dynamic> json) {
    return CPUMetrics(
      usagePercent: (json['usagePercent'] as num?)?.toDouble(),
      loadAverage1m: (json['loadAverage1m'] as num?)?.toDouble(),
      loadAverage5m: (json['loadAverage5m'] as num?)?.toDouble(),
      loadAverage15m: (json['loadAverage15m'] as num?)?.toDouble(),
      cores: json['cores'] as int?,
      coreMetrics: (json['coreMetrics'] as List?)
          ?.map((item) => CPUCoreMetrics.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usagePercent': usagePercent,
      'loadAverage1m': loadAverage1m,
      'loadAverage5m': loadAverage5m,
      'loadAverage15m': loadAverage15m,
      'cores': cores,
      'coreMetrics': coreMetrics?.map((core) => core.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        usagePercent,
        loadAverage1m,
        loadAverage5m,
        loadAverage15m,
        cores,
        coreMetrics
      ];
}

/// CPU core metrics model
class CPUCoreMetrics extends Equatable {
  final int? coreId;
  final double? usagePercent;
  final String? frequency;

  const CPUCoreMetrics({
    this.coreId,
    this.usagePercent,
    this.frequency,
  });

  factory CPUCoreMetrics.fromJson(Map<String, dynamic> json) {
    return CPUCoreMetrics(
      coreId: json['coreId'] as int?,
      usagePercent: (json['usagePercent'] as num?)?.toDouble(),
      frequency: json['frequency'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coreId': coreId,
      'usagePercent': usagePercent,
      'frequency': frequency,
    };
  }

  @override
  List<Object?> get props => [coreId, usagePercent, frequency];
}

/// Memory metrics model
class MemoryMetrics extends Equatable {
  final int? total;
  final int? used;
  final int? free;
  final int? available;
  final int? cached;
  final int? buffers;
  final double? usagePercent;

  const MemoryMetrics({
    this.total,
    this.used,
    this.free,
    this.available,
    this.cached,
    this.buffers,
    this.usagePercent,
  });

  factory MemoryMetrics.fromJson(Map<String, dynamic> json) {
    return MemoryMetrics(
      total: json['total'] as int?,
      used: json['used'] as int?,
      free: json['free'] as int?,
      available: json['available'] as int?,
      cached: json['cached'] as int?,
      buffers: json['buffers'] as int?,
      usagePercent: (json['usagePercent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'used': used,
      'free': free,
      'available': available,
      'cached': cached,
      'buffers': buffers,
      'usagePercent': usagePercent,
    };
  }

  @override
  List<Object?> get props =>
      [total, used, free, available, cached, buffers, usagePercent];
}

/// Disk metrics model
class DiskMetrics extends Equatable {
  final String? device;
  final String? mountPoint;
  final int? total;
  final int? used;
  final int? free;
  final double? usagePercent;
  final double? readSpeed;
  final double? writeSpeed;
  final int? iops;

  const DiskMetrics({
    this.device,
    this.mountPoint,
    this.total,
    this.used,
    this.free,
    this.usagePercent,
    this.readSpeed,
    this.writeSpeed,
    this.iops,
  });

  factory DiskMetrics.fromJson(Map<String, dynamic> json) {
    return DiskMetrics(
      device: json['device'] as String?,
      mountPoint: json['mountPoint'] as String?,
      total: json['total'] as int?,
      used: json['used'] as int?,
      free: json['free'] as int?,
      usagePercent: (json['usagePercent'] as num?)?.toDouble(),
      readSpeed: (json['readSpeed'] as num?)?.toDouble(),
      writeSpeed: (json['writeSpeed'] as num?)?.toDouble(),
      iops: json['iops'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device,
      'mountPoint': mountPoint,
      'total': total,
      'used': used,
      'free': free,
      'usagePercent': usagePercent,
      'readSpeed': readSpeed,
      'writeSpeed': writeSpeed,
      'iops': iops,
    };
  }

  @override
  List<Object?> get props => [
        device,
        mountPoint,
        total,
        used,
        free,
        usagePercent,
        readSpeed,
        writeSpeed,
        iops
      ];
}

/// Network metrics model
class NetworkMetrics extends Equatable {
  final String? interface;
  final int? bytesReceived;
  final int? bytesSent;
  final int? packetsReceived;
  final int? packetsSent;
  final double? receiveSpeed;
  final double? transmitSpeed;

  const NetworkMetrics({
    this.interface,
    this.bytesReceived,
    this.bytesSent,
    this.packetsReceived,
    this.packetsSent,
    this.receiveSpeed,
    this.transmitSpeed,
  });

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      interface: json['interface'] as String?,
      bytesReceived: json['bytesReceived'] as int?,
      bytesSent: json['bytesSent'] as int?,
      packetsReceived: json['packetsReceived'] as int?,
      packetsSent: json['packetsSent'] as int?,
      receiveSpeed: (json['receiveSpeed'] as num?)?.toDouble(),
      transmitSpeed: (json['transmitSpeed'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'interface': interface,
      'bytesReceived': bytesReceived,
      'bytesSent': bytesSent,
      'packetsReceived': packetsReceived,
      'packetsSent': packetsSent,
      'receiveSpeed': receiveSpeed,
      'transmitSpeed': transmitSpeed,
    };
  }

  @override
  List<Object?> get props => [
        interface,
        bytesReceived,
        bytesSent,
        packetsReceived,
        packetsSent,
        receiveSpeed,
        transmitSpeed
      ];
}

/// Alert rule model
class AlertRule extends Equatable {
  final int? id;
  final String? name;
  final MetricType? metricType;
  final String? condition;
  final double? threshold;
  final AlertLevel? level;
  final bool? enabled;
  final String? description;
  final int? cooldown;
  final String? createTime;
  final String? updateTime;

  const AlertRule({
    this.id,
    this.name,
    this.metricType,
    this.condition,
    this.threshold,
    this.level,
    this.enabled,
    this.description,
    this.cooldown,
    this.createTime,
    this.updateTime,
  });

  factory AlertRule.fromJson(Map<String, dynamic> json) {
    return AlertRule(
      id: json['id'] as int?,
      name: json['name'] as String?,
      metricType: json['metricType'] != null
          ? MetricType.fromString(json['metricType'] as String)
          : null,
      condition: json['condition'] as String?,
      threshold: (json['threshold'] as num?)?.toDouble(),
      level: json['level'] != null
          ? AlertLevel.fromString(json['level'] as String)
          : null,
      enabled: json['enabled'] as bool?,
      description: json['description'] as String?,
      cooldown: json['cooldown'] as int?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'metricType': metricType?.value,
      'condition': condition,
      'threshold': threshold,
      'level': level?.value,
      'enabled': enabled,
      'description': description,
      'cooldown': cooldown,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        metricType,
        condition,
        threshold,
        level,
        enabled,
        description,
        cooldown,
        createTime,
        updateTime
      ];
}

/// Alert notification model
class AlertNotification extends Equatable {
  final int? id;
  final String? ruleName;
  final AlertLevel? level;
  final String? message;
  final String? details;
  final String? status;
  final String? timestamp;
  final bool? acknowledged;

  const AlertNotification({
    this.id,
    this.ruleName,
    this.level,
    this.message,
    this.details,
    this.status,
    this.timestamp,
    this.acknowledged,
  });

  factory AlertNotification.fromJson(Map<String, dynamic> json) {
    return AlertNotification(
      id: json['id'] as int?,
      ruleName: json['ruleName'] as String?,
      level: json['level'] != null
          ? AlertLevel.fromString(json['level'] as String)
          : null,
      message: json['message'] as String?,
      details: json['details'] as String?,
      status: json['status'] as String?,
      timestamp: json['timestamp'] as String?,
      acknowledged: json['acknowledged'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ruleName': ruleName,
      'level': level?.value,
      'message': message,
      'details': details,
      'status': status,
      'timestamp': timestamp,
      'acknowledged': acknowledged,
    };
  }

  @override
  List<Object?> get props =>
      [id, ruleName, level, message, details, status, timestamp, acknowledged];
}

/// Security configuration model
class SecurityConfig extends Equatable {
  final bool? sslEnabled;
  final String? sslCert;
  final String? sslKey;
  final bool? mfaEnabled;
  final String? jwtSecret;
  final int? jwtExpireHours;
  final bool? ipWhitelistEnabled;
  final List<String>? ipWhitelist;
  final int? maxLoginAttempts;
  final int? lockoutDuration;
  final bool? passwordPolicyEnabled;
  final int? minPasswordLength;
  final bool? requireUppercase;
  final bool? requireLowercase;
  final bool? requireNumbers;
  final bool? requireSpecialChars;

  const SecurityConfig({
    this.sslEnabled,
    this.sslCert,
    this.sslKey,
    this.mfaEnabled,
    this.jwtSecret,
    this.jwtExpireHours,
    this.ipWhitelistEnabled,
    this.ipWhitelist,
    this.maxLoginAttempts,
    this.lockoutDuration,
    this.passwordPolicyEnabled,
    this.minPasswordLength,
    this.requireUppercase,
    this.requireLowercase,
    this.requireNumbers,
    this.requireSpecialChars,
  });

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      sslEnabled: json['sslEnabled'] as bool?,
      sslCert: json['sslCert'] as String?,
      sslKey: json['sslKey'] as String?,
      mfaEnabled: json['mfaEnabled'] as bool?,
      jwtSecret: json['jwtSecret'] as String?,
      jwtExpireHours: json['jwtExpireHours'] as int?,
      ipWhitelistEnabled: json['ipWhitelistEnabled'] as bool?,
      ipWhitelist:
          (json['ipWhitelist'] as List?)?.map((e) => e as String).toList(),
      maxLoginAttempts: json['maxLoginAttempts'] as int?,
      lockoutDuration: json['lockoutDuration'] as int?,
      passwordPolicyEnabled: json['passwordPolicyEnabled'] as bool?,
      minPasswordLength: json['minPasswordLength'] as int?,
      requireUppercase: json['requireUppercase'] as bool?,
      requireLowercase: json['requireLowercase'] as bool?,
      requireNumbers: json['requireNumbers'] as bool?,
      requireSpecialChars: json['requireSpecialChars'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sslEnabled': sslEnabled,
      'sslCert': sslCert,
      'sslKey': sslKey,
      'mfaEnabled': mfaEnabled,
      'jwtSecret': jwtSecret,
      'jwtExpireHours': jwtExpireHours,
      'ipWhitelistEnabled': ipWhitelistEnabled,
      'ipWhitelist': ipWhitelist,
      'maxLoginAttempts': maxLoginAttempts,
      'lockoutDuration': lockoutDuration,
      'passwordPolicyEnabled': passwordPolicyEnabled,
      'minPasswordLength': minPasswordLength,
      'requireUppercase': requireUppercase,
      'requireLowercase': requireLowercase,
      'requireNumbers': requireNumbers,
      'requireSpecialChars': requireSpecialChars,
    };
  }

  @override
  List<Object?> get props => [
        sslEnabled,
        sslCert,
        sslKey,
        mfaEnabled,
        jwtSecret,
        jwtExpireHours,
        ipWhitelistEnabled,
        ipWhitelist,
        maxLoginAttempts,
        lockoutDuration,
        passwordPolicyEnabled,
        minPasswordLength,
        requireUppercase,
        requireLowercase,
        requireNumbers,
        requireSpecialChars,
      ];
}
