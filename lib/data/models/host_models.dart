import 'package:equatable/equatable.dart';

/// 主机创建模型
class HostCreate extends Equatable {
  final String name;
  final String? address;
  final int? port;
  final String? username;
  final String? password;
  final String? privateKey;
  final String? groupID;
  final String? description;
  final Map<String, dynamic>? vars;

  const HostCreate({
    required this.name,
    this.address,
    this.port,
    this.username,
    this.password,
    this.privateKey,
    this.groupID,
    this.description,
    this.vars,
  });

  factory HostCreate.fromJson(Map<String, dynamic> json) {
    return HostCreate(
      name: json['name'] as String,
      address: json['address'] as String?,
      port: json['port'] as int?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      groupID: json['groupID'] as String?,
      description: json['description'] as String?,
      vars: json['vars'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'port': port,
      'username': username,
      'password': password,
      'privateKey': privateKey,
      'groupID': groupID,
      'description': description,
      'vars': vars,
    };
  }

  @override
  List<Object?> get props => [
        name,
        address,
        port,
        username,
        password,
        privateKey,
        groupID,
        description,
        vars,
      ];
}

/// 主机更新模型
class HostUpdate extends HostCreate {
  final int id;

  const HostUpdate({
    required this.id,
    required super.name,
    super.address,
    super.port,
    super.username,
    super.password,
    super.privateKey,
    super.groupID,
    super.description,
    super.vars,
  });

  factory HostUpdate.fromJson(Map<String, dynamic> json) {
    return HostUpdate(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      port: json['port'] as int?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      groupID: json['groupID'] as String?,
      description: json['description'] as String?,
      vars: json['vars'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['id'] = id;
    return json;
  }

  @override
  List<Object?> get props => [...super.props, id];
}

/// 主机搜索模型
class HostSearch extends Equatable {
  final String? info;
  final String? status;
  final int page;
  final int pageSize;

  const HostSearch({
    this.info,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });

  factory HostSearch.fromJson(Map<String, dynamic> json) {
    return HostSearch(
      info: json['info'] as String?,
      status: json['status'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'info': info,
      'status': status,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [info, status, page, pageSize];
}

/// 主机信息模型
class HostInfo extends Equatable {
  final int id;
  final String name;
  final String? addr;
  final int? port;
  final String? user;
  final int? groupID;
  final String? groupBelong;
  final String? authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;
  final bool? rememberPassword;
  final String? description;
  final String status;
  final String? version;
  final String? osType;
  final String? osArch;
  final String? kernelVersion;
  final String? memoryInfo;
  final String? cpuInfo;
  final String? diskInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? vars;
  final String? agentVersion;
  final bool? isActive;
  final DateTime? lastHeartbeat;

  const HostInfo({
    required this.id,
    required this.name,
    this.addr,
    this.port,
    this.user,
    this.groupID,
    this.groupBelong,
    this.authMode,
    this.password,
    this.privateKey,
    this.passPhrase,
    this.rememberPassword,
    this.description,
    required this.status,
    this.version,
    this.osType,
    this.osArch,
    this.kernelVersion,
    this.memoryInfo,
    this.cpuInfo,
    this.diskInfo,
    this.createdAt,
    this.updatedAt,
    this.vars,
    this.agentVersion,
    this.isActive,
    this.lastHeartbeat,
  });

  factory HostInfo.fromJson(Map<String, dynamic> json) {
    return HostInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      addr: json['addr'] as String? ?? json['address'] as String?,
      port: json['port'] as int?,
      user: json['user'] as String? ?? json['username'] as String?,
      groupID: json['groupID'] as int? ??
          int.tryParse(json['groupID']?.toString() ?? ''),
      groupBelong: json['groupBelong'] as String?,
      authMode: json['authMode'] as String?,
      password: json['password'] as String?,
      privateKey: json['privateKey'] as String?,
      passPhrase: json['passPhrase'] as String?,
      rememberPassword: json['rememberPassword'] as bool?,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'unknown',
      version: json['version'] as String?,
      osType: json['osType'] as String?,
      osArch: json['osArch'] as String?,
      kernelVersion: json['kernelVersion'] as String?,
      memoryInfo: json['memoryInfo'] as String?,
      cpuInfo: json['cpuInfo'] as String?,
      diskInfo: json['diskInfo'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      vars: json['vars'] as Map<String, dynamic>?,
      agentVersion: json['agentVersion'] as String?,
      isActive: json['isActive'] as bool?,
      lastHeartbeat: json['lastHeartbeat'] != null
          ? DateTime.parse(json['lastHeartbeat'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'addr': addr,
      'port': port,
      'user': user,
      'groupID': groupID,
      'groupBelong': groupBelong,
      'authMode': authMode,
      'password': password,
      'privateKey': privateKey,
      'passPhrase': passPhrase,
      'rememberPassword': rememberPassword,
      'description': description,
      'status': status,
      'version': version,
      'osType': osType,
      'osArch': osArch,
      'kernelVersion': kernelVersion,
      'memoryInfo': memoryInfo,
      'cpuInfo': cpuInfo,
      'diskInfo': diskInfo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'vars': vars,
      'agentVersion': agentVersion,
      'isActive': isActive,
      'lastHeartbeat': lastHeartbeat?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        addr,
        port,
        user,
        groupID,
        groupBelong,
        authMode,
        password,
        privateKey,
        passPhrase,
        rememberPassword,
        description,
        status,
        version,
        osType,
        osArch,
        kernelVersion,
        memoryInfo,
        cpuInfo,
        diskInfo,
        createdAt,
        updatedAt,
        vars,
        agentVersion,
        isActive,
        lastHeartbeat,
      ];

  String? get address => addr;
  String? get username => user;
}

/// 主机监控数据模型
class HostMonitor extends Equatable {
  final int hostId;
  final double? cpuUsage;
  final double? memoryUsage;
  final double? diskUsage;
  final double? networkIn;
  final double? networkOut;
  final int? load1;
  final int? load5;
  final int? load15;
  final DateTime? timestamp;

  const HostMonitor({
    required this.hostId,
    this.cpuUsage,
    this.memoryUsage,
    this.diskUsage,
    this.networkIn,
    this.networkOut,
    this.load1,
    this.load5,
    this.load15,
    this.timestamp,
  });

  factory HostMonitor.fromJson(Map<String, dynamic> json) {
    return HostMonitor(
      hostId: json['hostId'] as int,
      cpuUsage: (json['cpuUsage'] as num?)?.toDouble(),
      memoryUsage: (json['memoryUsage'] as num?)?.toDouble(),
      diskUsage: (json['diskUsage'] as num?)?.toDouble(),
      networkIn: (json['networkIn'] as num?)?.toDouble(),
      networkOut: (json['networkOut'] as num?)?.toDouble(),
      load1: json['load1'] as int?,
      load5: json['load5'] as int?,
      load15: json['load15'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
      'cpuUsage': cpuUsage,
      'memoryUsage': memoryUsage,
      'diskUsage': diskUsage,
      'networkIn': networkIn,
      'networkOut': networkOut,
      'load1': load1,
      'load5': load5,
      'load15': load15,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        hostId,
        cpuUsage,
        memoryUsage,
        diskUsage,
        networkIn,
        networkOut,
        load1,
        load5,
        load15,
        timestamp,
      ];
}

/// 主机监控设置模型
class HostMonitorSetting extends Equatable {
  final int hostId;
  final bool enableCpu;
  final bool enableMemory;
  final bool enableDisk;
  final bool enableNetwork;
  final bool enableLoad;
  final int? interval;
  final int? retention;

  const HostMonitorSetting({
    required this.hostId,
    this.enableCpu = true,
    this.enableMemory = true,
    this.enableDisk = true,
    this.enableNetwork = true,
    this.enableLoad = true,
    this.interval,
    this.retention,
  });

  factory HostMonitorSetting.fromJson(Map<String, dynamic> json) {
    return HostMonitorSetting(
      hostId: json['hostId'] as int,
      enableCpu: json['enableCpu'] as bool? ?? true,
      enableMemory: json['enableMemory'] as bool? ?? true,
      enableDisk: json['enableDisk'] as bool? ?? true,
      enableNetwork: json['enableNetwork'] as bool? ?? true,
      enableLoad: json['enableLoad'] as bool? ?? true,
      interval: json['interval'] as int?,
      retention: json['retention'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hostId': hostId,
      'enableCpu': enableCpu,
      'enableMemory': enableMemory,
      'enableDisk': enableDisk,
      'enableNetwork': enableNetwork,
      'enableLoad': enableLoad,
      'interval': interval,
      'retention': retention,
    };
  }

  @override
  List<Object?> get props => [
        hostId,
        enableCpu,
        enableMemory,
        enableDisk,
        enableNetwork,
        enableLoad,
        interval,
        retention,
      ];
}

/// 主机状态枚举
enum HostStatus {
  online('online', '在线'),
  offline('offline', '离线'),
  connecting('connecting', '连接中'),
  error('error', '错误'),
  maintenance('maintenance', '维护中');

  const HostStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static HostStatus fromString(String value) {
    return HostStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => HostStatus.offline,
    );
  }
}

/// 操作系统类型枚举
enum OSType {
  linux('linux', 'Linux'),
  windows('windows', 'Windows'),
  macos('macos', 'macOS'),
  other('other', '其他');

  const OSType(this.value, this.displayName);

  final String value;
  final String displayName;

  static OSType fromString(String value) {
    return OSType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => OSType.other,
    );
  }
}
