import 'package:equatable/equatable.dart';

/// Clam扫描创建请求
class ClamCreate extends Equatable {
  final int? alertCount;
  final String? alertMethod;
  final String? alertTitle;
  final String? description;
  final String? infectedDir;
  final String? infectedStrategy;
  final String? name;
  final String? path;
  final String? spec;
  final String? status;
  final int? timeout;

  const ClamCreate({
    this.alertCount,
    this.alertMethod,
    this.alertTitle,
    this.description,
    this.infectedDir,
    this.infectedStrategy,
    this.name,
    this.path,
    this.spec,
    this.status,
    this.timeout,
  });

  factory ClamCreate.fromJson(Map<String, dynamic> json) {
    return ClamCreate(
      alertCount: json['alertCount'] as int?,
      alertMethod: json['alertMethod'] as String?,
      alertTitle: json['alertTitle'] as String?,
      description: json['description'] as String?,
      infectedDir: json['infectedDir'] as String?,
      infectedStrategy: json['infectedStrategy'] as String?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      spec: json['spec'] as String?,
      status: json['status'] as String?,
      timeout: json['timeout'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertCount': alertCount,
      'alertMethod': alertMethod,
      'alertTitle': alertTitle,
      'description': description,
      'infectedDir': infectedDir,
      'infectedStrategy': infectedStrategy,
      'name': name,
      'path': path,
      'spec': spec,
      'status': status,
      'timeout': timeout,
    };
  }

  @override
  List<Object?> get props => [
        alertCount,
        alertMethod,
        alertTitle,
        description,
        infectedDir,
        infectedStrategy,
        name,
        path,
        spec,
        status,
        timeout,
      ];
}

/// Clam扫描删除请求
class ClamDelete extends Equatable {
  final List<int>? ids;
  final bool? removeInfected;

  const ClamDelete({
    this.ids,
    this.removeInfected,
  });

  factory ClamDelete.fromJson(Map<String, dynamic> json) {
    return ClamDelete(
      ids: (json['ids'] as List<dynamic>?)?.map((e) => e as int).toList(),
      removeInfected: json['removeInfected'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
      'removeInfected': removeInfected,
    };
  }

  @override
  List<Object?> get props => [ids, removeInfected];
}

/// Clam扫描更新请求
class ClamUpdate extends Equatable {
  final int? alertCount;
  final String? alertMethod;
  final String? alertTitle;
  final String? description;
  final int? id;
  final String? infectedDir;
  final String? infectedStrategy;
  final String? name;
  final String? path;
  final String? spec;
  final String? status;
  final int? timeout;

  const ClamUpdate({
    this.alertCount,
    this.alertMethod,
    this.alertTitle,
    this.description,
    this.id,
    this.infectedDir,
    this.infectedStrategy,
    this.name,
    this.path,
    this.spec,
    this.status,
    this.timeout,
  });

  factory ClamUpdate.fromJson(Map<String, dynamic> json) {
    return ClamUpdate(
      alertCount: json['alertCount'] as int?,
      alertMethod: json['alertMethod'] as String?,
      alertTitle: json['alertTitle'] as String?,
      description: json['description'] as String?,
      id: json['id'] as int?,
      infectedDir: json['infectedDir'] as String?,
      infectedStrategy: json['infectedStrategy'] as String?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      spec: json['spec'] as String?,
      status: json['status'] as String?,
      timeout: json['timeout'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alertCount': alertCount,
      'alertMethod': alertMethod,
      'alertTitle': alertTitle,
      'description': description,
      'id': id,
      'infectedDir': infectedDir,
      'infectedStrategy': infectedStrategy,
      'name': name,
      'path': path,
      'spec': spec,
      'status': status,
      'timeout': timeout,
    };
  }

  @override
  List<Object?> get props => [
        alertCount,
        alertMethod,
        alertTitle,
        description,
        id,
        infectedDir,
        infectedStrategy,
        name,
        path,
        spec,
        status,
        timeout,
      ];
}

/// Clam状态更新请求
class ClamUpdateStatus extends Equatable {
  final int? id;
  final String? status;

  const ClamUpdateStatus({
    this.id,
    this.status,
  });

  factory ClamUpdateStatus.fromJson(Map<String, dynamic> json) {
    return ClamUpdateStatus(
      id: json['id'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, status];
}

/// Clam基础信息响应
class ClamBaseInfo extends Equatable {
  final String? createdAt;
  final String? description;
  final int? id;
  final String? infectedDir;
  final String? infectedStrategy;
  final String? lastHandleAt;
  final String? name;
  final String? path;
  final String? spec;
  final String? status;
  final int? timeout;
  final String? updatedAt;

  const ClamBaseInfo({
    this.createdAt,
    this.description,
    this.id,
    this.infectedDir,
    this.infectedStrategy,
    this.lastHandleAt,
    this.name,
    this.path,
    this.spec,
    this.status,
    this.timeout,
    this.updatedAt,
  });

  factory ClamBaseInfo.fromJson(Map<String, dynamic> json) {
    return ClamBaseInfo(
      createdAt: json['createdAt'] as String?,
      description: json['description'] as String?,
      id: json['id'] as int?,
      infectedDir: json['infectedDir'] as String?,
      infectedStrategy: json['infectedStrategy'] as String?,
      lastHandleAt: json['lastHandleAt'] as String?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      spec: json['spec'] as String?,
      status: json['status'] as String?,
      timeout: json['timeout'] as int?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'description': description,
      'id': id,
      'infectedDir': infectedDir,
      'infectedStrategy': infectedStrategy,
      'lastHandleAt': lastHandleAt,
      'name': name,
      'path': path,
      'spec': spec,
      'status': status,
      'timeout': timeout,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        createdAt,
        description,
        id,
        infectedDir,
        infectedStrategy,
        lastHandleAt,
        name,
        path,
        spec,
        status,
        timeout,
        updatedAt,
      ];
}

/// Clam文件搜索请求
class ClamFileReq extends Equatable {
  final int? clamId;
  final String? name;
  final int? page;
  final int? pageSize;

  const ClamFileReq({
    this.clamId,
    this.name,
    this.page,
    this.pageSize,
  });

  factory ClamFileReq.fromJson(Map<String, dynamic> json) {
    return ClamFileReq(
      clamId: json['clamId'] as int?,
      name: json['name'] as String?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clamId': clamId,
      'name': name,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [clamId, name, page, pageSize];
}

/// Clam日志搜索请求
class ClamLogSearch extends Equatable {
  final int? clamId;
  final int? page;
  final int? pageSize;

  const ClamLogSearch({
    this.clamId,
    this.page,
    this.pageSize,
  });

  factory ClamLogSearch.fromJson(Map<String, dynamic> json) {
    return ClamLogSearch(
      clamId: json['clamId'] as int?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clamId': clamId,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [clamId, page, pageSize];
}

/// Clam日志信息
class ClamLogInfo extends Equatable {
  final String? createdAt;
  final int? id;
  final String? name;
  final String? path;
  final String? status;

  const ClamLogInfo({
    this.createdAt,
    this.id,
    this.name,
    this.path,
    this.status,
  });

  factory ClamLogInfo.fromJson(Map<String, dynamic> json) {
    return ClamLogInfo(
      createdAt: json['createdAt'] as String?,
      id: json['id'] as int?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'id': id,
      'name': name,
      'path': path,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [createdAt, id, name, path, status];
}

/// Clam文件信息
class ClamFileInfo extends Equatable {
  final String? createdAt;
  final int? id;
  final String? name;
  final String? path;
  final String? status;

  const ClamFileInfo({
    this.createdAt,
    this.id,
    this.name,
    this.path,
    this.status,
  });

  factory ClamFileInfo.fromJson(Map<String, dynamic> json) {
    return ClamFileInfo(
      createdAt: json['createdAt'] as String?,
      id: json['id'] as int?,
      name: json['name'] as String?,
      path: json['path'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'id': id,
      'name': name,
      'path': path,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [createdAt, id, name, path, status];
}

/// 设备基础信息
class DeviceBaseInfo extends Equatable {
  final String? dns;
  final String? hostname;
  final String? localTime;
  final String? ntp;
  final String? productName;
  final String? productVersion;
  final String? systemName;
  final String? systemVersion;
  final String? timeZone;

  const DeviceBaseInfo({
    this.dns,
    this.hostname,
    this.localTime,
    this.ntp,
    this.productName,
    this.productVersion,
    this.systemName,
    this.systemVersion,
    this.timeZone,
  });

  factory DeviceBaseInfo.fromJson(Map<String, dynamic> json) {
    return DeviceBaseInfo(
      dns: json['dns'] as String?,
      hostname: json['hostname'] as String?,
      localTime: json['localTime'] as String?,
      ntp: json['ntp'] as String?,
      productName: json['productName'] as String?,
      productVersion: json['productVersion'] as String?,
      systemName: json['systemName'] as String?,
      systemVersion: json['systemVersion'] as String?,
      timeZone: json['timeZone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dns': dns,
      'hostname': hostname,
      'localTime': localTime,
      'ntp': ntp,
      'productName': productName,
      'productVersion': productVersion,
      'systemName': systemName,
      'systemVersion': systemVersion,
      'timeZone': timeZone,
    };
  }

  @override
  List<Object?> get props => [
        dns,
        hostname,
        localTime,
        ntp,
        productName,
        productVersion,
        systemName,
        systemVersion,
        timeZone,
      ];
}

/// 设备配置更新请求
class DeviceConfUpdate extends Equatable {
  final String? dns;
  final String? hostname;
  final String? ntp;
  final String? swap;

  const DeviceConfUpdate({
    this.dns,
    this.hostname,
    this.ntp,
    this.swap,
  });

  factory DeviceConfUpdate.fromJson(Map<String, dynamic> json) {
    return DeviceConfUpdate(
      dns: json['dns'] as String?,
      hostname: json['hostname'] as String?,
      ntp: json['ntp'] as String?,
      swap: json['swap'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dns': dns,
      'hostname': hostname,
      'ntp': ntp,
      'swap': swap,
    };
  }

  @override
  List<Object?> get props => [dns, hostname, ntp, swap];
}

/// 设备密码更新请求
class DevicePasswdUpdate extends Equatable {
  final String? oldPasswd;
  final String? newPasswd;

  const DevicePasswdUpdate({
    this.oldPasswd,
    this.newPasswd,
  });

  factory DevicePasswdUpdate.fromJson(Map<String, dynamic> json) {
    return DevicePasswdUpdate(
      oldPasswd: json['oldPasswd'] as String?,
      newPasswd: json['newPasswd'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oldPasswd': oldPasswd,
      'newPasswd': newPasswd,
    };
  }

  @override
  List<Object?> get props => [oldPasswd, newPasswd];
}

/// Fail2ban基础信息
class Fail2banBaseInfo extends Equatable {
  final String? bantime;
  final String? findtime;
  final bool? isEnable;
  final String? maxretry;
  final String? port;
  final String? version;

  const Fail2banBaseInfo({
    this.bantime,
    this.findtime,
    this.isEnable,
    this.maxretry,
    this.port,
    this.version,
  });

  factory Fail2banBaseInfo.fromJson(Map<String, dynamic> json) {
    return Fail2banBaseInfo(
      bantime: json['bantime'] as String?,
      findtime: json['findtime'] as String?,
      isEnable: json['isEnable'] as bool?,
      maxretry: json['maxretry'] as String?,
      port: json['port'] as String?,
      version: json['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bantime': bantime,
      'findtime': findtime,
      'isEnable': isEnable,
      'maxretry': maxretry,
      'port': port,
      'version': version,
    };
  }

  @override
  List<Object?> get props =>
      [bantime, findtime, isEnable, maxretry, port, version];
}

/// Fail2ban更新请求
class Fail2banUpdate extends Equatable {
  final String? bantime;
  final String? findtime;
  final bool? isEnable;
  final String? maxretry;
  final String? port;

  const Fail2banUpdate({
    this.bantime,
    this.findtime,
    this.isEnable,
    this.maxretry,
    this.port,
  });

  factory Fail2banUpdate.fromJson(Map<String, dynamic> json) {
    return Fail2banUpdate(
      bantime: json['bantime'] as String?,
      findtime: json['findtime'] as String?,
      isEnable: json['isEnable'] as bool?,
      maxretry: json['maxretry'] as String?,
      port: json['port'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bantime': bantime,
      'findtime': findtime,
      'isEnable': isEnable,
      'maxretry': maxretry,
      'port': port,
    };
  }

  @override
  List<Object?> get props => [bantime, findtime, isEnable, maxretry, port];
}

/// Fail2ban SSHD操作请求
class Fail2banSet extends Equatable {
  final List<String>? ips;
  final String? operate;

  const Fail2banSet({
    this.ips,
    this.operate,
  });

  factory Fail2banSet.fromJson(Map<String, dynamic> json) {
    return Fail2banSet(
      ips: (json['ips'] as List<dynamic>?)?.map((e) => e as String).toList(),
      operate: json['operate'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ips': ips,
      'operate': operate,
    };
  }

  @override
  List<Object?> get props => [ips, operate];
}

/// Fail2ban搜索请求
class Fail2banSearch extends Equatable {
  final String? ip;
  final int? page;
  final int? pageSize;
  final String? status;

  const Fail2banSearch({
    this.ip,
    this.page,
    this.pageSize,
    this.status,
  });

  factory Fail2banSearch.fromJson(Map<String, dynamic> json) {
    return Fail2banSearch(
      ip: json['ip'] as String?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'page': page,
      'pageSize': pageSize,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [ip, page, pageSize, status];
}

/// Fail2ban记录信息
class Fail2banRecord extends Equatable {
  final String? createdAt;
  final String? ip;
  final String? status;

  const Fail2banRecord({
    this.createdAt,
    this.ip,
    this.status,
  });

  factory Fail2banRecord.fromJson(Map<String, dynamic> json) {
    return Fail2banRecord(
      createdAt: json['createdAt'] as String?,
      ip: json['ip'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'ip': ip,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [createdAt, ip, status];
}

/// FTP基础信息
class FtpBaseInfo extends Equatable {
  final String? baseDir;
  final String? status;
  final String? version;

  const FtpBaseInfo({
    this.baseDir,
    this.status,
    this.version,
  });

  factory FtpBaseInfo.fromJson(Map<String, dynamic> json) {
    return FtpBaseInfo(
      baseDir: json['baseDir'] as String?,
      status: json['status'] as String?,
      version: json['version'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseDir': baseDir,
      'status': status,
      'version': version,
    };
  }

  @override
  List<Object?> get props => [baseDir, status, version];
}

/// FTP创建请求
class FtpCreate extends Equatable {
  final String? baseDir;
  final String? password;
  final String? path;
  final String? user;

  const FtpCreate({
    this.baseDir,
    this.password,
    this.path,
    this.user,
  });

  factory FtpCreate.fromJson(Map<String, dynamic> json) {
    return FtpCreate(
      baseDir: json['baseDir'] as String?,
      password: json['password'] as String?,
      path: json['path'] as String?,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseDir': baseDir,
      'password': password,
      'path': path,
      'user': user,
    };
  }

  @override
  List<Object?> get props => [baseDir, password, path, user];
}

/// FTP更新请求
class FtpUpdate extends Equatable {
  final String? baseDir;
  final int? id;
  final String? password;
  final String? path;
  final String? user;

  const FtpUpdate({
    this.baseDir,
    this.id,
    this.password,
    this.path,
    this.user,
  });

  factory FtpUpdate.fromJson(Map<String, dynamic> json) {
    return FtpUpdate(
      baseDir: json['baseDir'] as String?,
      id: json['id'] as int?,
      password: json['password'] as String?,
      path: json['path'] as String?,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseDir': baseDir,
      'id': id,
      'password': password,
      'path': path,
      'user': user,
    };
  }

  @override
  List<Object?> get props => [baseDir, id, password, path, user];
}

/// FTP删除请求
class FtpDelete extends Equatable {
  final List<int>? ids;

  const FtpDelete({
    this.ids,
  });

  factory FtpDelete.fromJson(Map<String, dynamic> json) {
    return FtpDelete(
      ids: (json['ids'] as List<dynamic>?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ids': ids,
    };
  }

  @override
  List<Object?> get props => [ids];
}

/// FTP搜索请求
class FtpSearch extends Equatable {
  final String? info;
  final int? page;
  final int? pageSize;

  const FtpSearch({
    this.info,
    this.page,
    this.pageSize,
  });

  factory FtpSearch.fromJson(Map<String, dynamic> json) {
    return FtpSearch(
      info: json['info'] as String?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'info': info,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [info, page, pageSize];
}

/// FTP信息
class FtpInfo extends Equatable {
  final String? baseDir;
  final String? createdAt;
  final int? id;
  final String? path;
  final String? status;
  final String? user;

  const FtpInfo({
    this.baseDir,
    this.createdAt,
    this.id,
    this.path,
    this.status,
    this.user,
  });

  factory FtpInfo.fromJson(Map<String, dynamic> json) {
    return FtpInfo(
      baseDir: json['baseDir'] as String?,
      createdAt: json['createdAt'] as String?,
      id: json['id'] as int?,
      path: json['path'] as String?,
      status: json['status'] as String?,
      user: json['user'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseDir': baseDir,
      'createdAt': createdAt,
      'id': id,
      'path': path,
      'status': status,
      'user': user,
    };
  }

  @override
  List<Object?> get props => [baseDir, createdAt, id, path, status, user];
}

/// FTP日志搜索请求
class FtpLogSearch extends Equatable {
  final int? ftpId;
  final int? page;
  final int? pageSize;

  const FtpLogSearch({
    this.ftpId,
    this.page,
    this.pageSize,
  });

  factory FtpLogSearch.fromJson(Map<String, dynamic> json) {
    return FtpLogSearch(
      ftpId: json['ftpId'] as int?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ftpId': ftpId,
      'page': page,
      'pageSize': pageSize,
    };
  }

  @override
  List<Object?> get props => [ftpId, page, pageSize];
}

/// 系统清理请求
class Clean extends Equatable {
  final List<String>? cleanData;

  const Clean({
    this.cleanData,
  });

  factory Clean.fromJson(Map<String, dynamic> json) {
    return Clean(
      cleanData: (json['cleanData'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cleanData': cleanData,
    };
  }

  @override
  List<Object?> get props => [cleanData];
}

/// 系统清理数据项
class CleanData extends Equatable {
  final String? name;
  final String? size;
  final String? path;

  const CleanData({
    this.name,
    this.size,
    this.path,
  });

  factory CleanData.fromJson(Map<String, dynamic> json) {
    return CleanData(
      name: json['name'] as String?,
      size: json['size'] as String?,
      path: json['path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'size': size,
      'path': path,
    };
  }

  @override
  List<Object?> get props => [name, size, path];
}

/// 系统清理树形结构
class CleanTree extends Equatable {
  final String? label;
  final String? value;
  final List<CleanTree>? children;

  const CleanTree({
    this.label,
    this.value,
    this.children,
  });

  factory CleanTree.fromJson(Map<String, dynamic> json) {
    return CleanTree(
      label: json['label'] as String?,
      value: json['value'] as String?,
      children: (json['children'] as List<dynamic>?)
          ?.map((e) => CleanTree.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'children': children?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [label, value, children];
}

/// 系统清理日志
class CleanLog extends Equatable {
  final String? createdAt;
  final String? detail;
  final int? id;
  final String? status;

  const CleanLog({
    this.createdAt,
    this.detail,
    this.id,
    this.status,
  });

  factory CleanLog.fromJson(Map<String, dynamic> json) {
    return CleanLog(
      createdAt: json['createdAt'] as String?,
      detail: json['detail'] as String?,
      id: json['id'] as int?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'detail': detail,
      'id': id,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [createdAt, detail, id, status];
}

/// 系统扫描请求
class Scan extends Equatable {
  final String? scanType;

  const Scan({
    this.scanType,
  });

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      scanType: json['scanType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scanType': scanType,
    };
  }

  @override
  List<Object?> get props => [scanType];
}
