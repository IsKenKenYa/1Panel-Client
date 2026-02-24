import 'package:equatable/equatable.dart';

/// Website creation request model
class WebsiteCreate extends Equatable {
  final String? domain;
  final String? alias;
  final String type;
  final int? port;
  final int? appId;
  final String? path;
  final String? remark;

  const WebsiteCreate({
    this.domain,
    this.alias,
    required this.type,
    this.port,
    this.appId,
    this.path,
    this.remark,
  });

  factory WebsiteCreate.fromJson(Map<String, dynamic> json) {
    return WebsiteCreate(
      domain: json['domain'] as String?,
      alias: json['alias'] as String?,
      type: json['type'] as String,
      port: json['port'] as int?,
      appId: json['appId'] as int?,
      path: json['path'] as String?,
      remark: json['remark'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'alias': alias,
      'type': type,
      'port': port,
      'appId': appId,
      'path': path,
      'remark': remark,
    };
  }

  @override
  List<Object?> get props => [domain, alias, type, port, appId, path, remark];
}

/// Website information model
class WebsiteInfo extends Equatable {
  final int? id;
  final String? domain;
  final String? alias;
  final String? type;
  final int? port;
  final int? appId;
  final String? appName;
  final String? path;
  final String? remark;
  final String? status;
  final String? createTime;
  final String? updateTime;

  const WebsiteInfo({
    this.id,
    this.domain,
    this.alias,
    this.type,
    this.port,
    this.appId,
    this.appName,
    this.path,
    this.remark,
    this.status,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteInfo.fromJson(Map<String, dynamic> json) {
    return WebsiteInfo(
      id: json['id'] as int?,
      domain: json['domain'] as String?,
      alias: json['alias'] as String?,
      type: json['type'] as String?,
      port: json['port'] as int?,
      appId: json['appId'] as int?,
      appName: json['appName'] as String?,
      path: json['path'] as String?,
      remark: json['remark'] as String?,
      status: json['status'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'alias': alias,
      'type': type,
      'port': port,
      'appId': appId,
      'appName': appName,
      'path': path,
      'remark': remark,
      'status': status,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, domain, alias, type, port, appId, appName, path, remark, status, createTime, updateTime];
}

/// Website search request model
class WebsiteSearch extends Equatable {
  final int page;
  final int pageSize;
  final String order;
  final String orderBy;
  final String? name;
  final String? type;
  final String? status;
  final int? websiteGroupId;

  const WebsiteSearch({
    this.page = 1,
    this.pageSize = 10,
    this.order = 'descending',
    this.orderBy = 'createdAt',
    this.name,
    this.type,
    this.status,
    this.websiteGroupId,
  });

  factory WebsiteSearch.fromJson(Map<String, dynamic> json) {
    return WebsiteSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      order: json['order'] as String? ?? 'descending',
      orderBy: json['orderBy'] as String? ?? 'createdAt',
      name: json['name'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      websiteGroupId: json['websiteGroupId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      'order': order,
      'orderBy': orderBy,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (websiteGroupId != null) 'websiteGroupId': websiteGroupId,
    };
  }

  @override
  List<Object?> get props => [page, pageSize, order, orderBy, name, type, status, websiteGroupId];
}

/// Website domain model
class WebsiteDomain extends Equatable {
  final int? id;
  final String? domain;
  final int? websiteId;
  final String? websiteName;
  final bool? isDefault;
  final bool? ssl;
  final String? createTime;

  const WebsiteDomain({
    this.id,
    this.domain,
    this.websiteId,
    this.websiteName,
    this.isDefault,
    this.ssl,
    this.createTime,
  });

  factory WebsiteDomain.fromJson(Map<String, dynamic> json) {
    return WebsiteDomain(
      id: json['id'] as int?,
      domain: json['domain'] as String?,
      websiteId: json['websiteId'] as int?,
      websiteName: json['websiteName'] as String?,
      isDefault: json['isDefault'] as bool?,
      ssl: json['ssl'] as bool?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'websiteId': websiteId,
      'websiteName': websiteName,
      'isDefault': isDefault,
      'ssl': ssl,
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props => [id, domain, websiteId, websiteName, isDefault, ssl, createTime];
}

/// SSL certificate model
class SSLCertificate extends Equatable {
  final int? id;
  final String? domain;
  final String? certType;
  final String? issuer;
  final String? startDate;
  final String? expireDate;
  final int? days;
  final String? status;
  final String? createTime;
  final String? updateTime;

  const SSLCertificate({
    this.id,
    this.domain,
    this.certType,
    this.issuer,
    this.startDate,
    this.expireDate,
    this.days,
    this.status,
    this.createTime,
    this.updateTime,
  });

  factory SSLCertificate.fromJson(Map<String, dynamic> json) {
    return SSLCertificate(
      id: json['id'] as int?,
      domain: json['domain'] as String?,
      certType: json['certType'] as String?,
      issuer: json['issuer'] as String?,
      startDate: json['startDate'] as String?,
      expireDate: json['expireDate'] as String?,
      days: json['days'] as int?,
      status: json['status'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'certType': certType,
      'issuer': issuer,
      'startDate': startDate,
      'expireDate': expireDate,
      'days': days,
      'status': status,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, domain, certType, issuer, startDate, expireDate, days, status, createTime, updateTime];
}

/// SSL apply request model
class SSLApply extends Equatable {
  final List<String> domains;
  final String? email;
  final String? keyType;
  final int? websiteId;
  final int? autoRenew;

  const SSLApply({
    required this.domains,
    this.email,
    this.keyType,
    this.websiteId,
    this.autoRenew,
  });

  factory SSLApply.fromJson(Map<String, dynamic> json) {
    return SSLApply(
      domains: (json['domains'] as List?)?.map((e) => e as String).toList() ?? [],
      email: json['email'] as String?,
      keyType: json['keyType'] as String?,
      websiteId: json['websiteId'] as int?,
      autoRenew: json['autoRenew'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domains': domains,
      'email': email,
      'keyType': keyType,
      'websiteId': websiteId,
      'autoRenew': autoRenew,
    };
  }

  @override
  List<Object?> get props => [domains, email, keyType, websiteId, autoRenew];
}

/// Website config model
class WebsiteConfig extends Equatable {
  final int? id;
  final int? websiteId;
  final String? configType;
  final String? content;
  final String? createTime;
  final String? updateTime;

  const WebsiteConfig({
    this.id,
    this.websiteId,
    this.configType,
    this.content,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteConfig.fromJson(Map<String, dynamic> json) {
    return WebsiteConfig(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      configType: json['configType'] as String?,
      content: json['content'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'configType': configType,
      'content': content,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, configType, content, createTime, updateTime];
}

/// Website rewrite rule model
class WebsiteRewrite extends Equatable {
  final int? id;
  final int? websiteId;
  final String? name;
  final String? content;
  final String? createTime;

  const WebsiteRewrite({
    this.id,
    this.websiteId,
    this.name,
    this.content,
    this.createTime,
  });

  factory WebsiteRewrite.fromJson(Map<String, dynamic> json) {
    return WebsiteRewrite(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      name: json['name'] as String?,
      content: json['content'] as String?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'name': name,
      'content': content,
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, name, content, createTime];
}

/// Website proxy model
class WebsiteProxy extends Equatable {
  final int? id;
  final int? websiteId;
  final String? type;
  final String? address;
  final int? port;
  final String? path;
  final bool? enable;
  final String? createTime;

  const WebsiteProxy({
    this.id,
    this.websiteId,
    this.type,
    this.address,
    this.port,
    this.path,
    this.enable,
    this.createTime,
  });

  factory WebsiteProxy.fromJson(Map<String, dynamic> json) {
    return WebsiteProxy(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      type: json['type'] as String?,
      address: json['address'] as String?,
      port: json['port'] as int?,
      path: json['path'] as String?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'type': type,
      'address': address,
      'port': port,
      'path': path,
      'enable': enable,
      'createTime': createTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, type, address, port, path, enable, createTime];
}

/// Website traffic statistics model
class WebsiteTraffic extends Equatable {
  final int? websiteId;
  final String? date;
  final int? visits;
  final int? bandwidth;
  final int? requests;

  const WebsiteTraffic({
    this.websiteId,
    this.date,
    this.visits,
    this.bandwidth,
    this.requests,
  });

  factory WebsiteTraffic.fromJson(Map<String, dynamic> json) {
    return WebsiteTraffic(
      websiteId: json['websiteId'] as int?,
      date: json['date'] as String?,
      visits: json['visits'] as int?,
      bandwidth: json['bandwidth'] as int?,
      requests: json['requests'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'websiteId': websiteId,
      'date': date,
      'visits': visits,
      'bandwidth': bandwidth,
      'requests': requests,
    };
  }

  @override
  List<Object?> get props => [websiteId, date, visits, bandwidth, requests];
}

/// SSL certificate info model (more detailed than SSLCertificate)
class SSLCertificateInfo extends Equatable {
  final int? id;
  final List<String>? domains;
  final String? certType;
  final String? issuer;
  final String? startDate;
  final String? expireDate;
  final int? days;
  final String? status;
  final String? dnsProvider;
  final String? keyType;
  final String? cert;
  final String? privateKey;
  final String? chain;
  final bool? autoRenew;
  final String? createTime;
  final String? updateTime;

  const SSLCertificateInfo({
    this.id,
    this.domains,
    this.certType,
    this.issuer,
    this.startDate,
    this.expireDate,
    this.days,
    this.status,
    this.dnsProvider,
    this.keyType,
    this.cert,
    this.privateKey,
    this.chain,
    this.autoRenew,
    this.createTime,
    this.updateTime,
  });

  factory SSLCertificateInfo.fromJson(Map<String, dynamic> json) {
    return SSLCertificateInfo(
      id: json['id'] as int?,
      domains: (json['domains'] as List?)?.map((e) => e as String).toList(),
      certType: json['certType'] as String?,
      issuer: json['issuer'] as String?,
      startDate: json['startDate'] as String?,
      expireDate: json['expireDate'] as String?,
      days: json['days'] as int?,
      status: json['status'] as String?,
      dnsProvider: json['dnsProvider'] as String?,
      keyType: json['keyType'] as String?,
      cert: json['cert'] as String?,
      privateKey: json['privateKey'] as String?,
      chain: json['chain'] as String?,
      autoRenew: json['autoRenew'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domains': domains,
      'certType': certType,
      'issuer': issuer,
      'startDate': startDate,
      'expireDate': expireDate,
      'days': days,
      'status': status,
      'dnsProvider': dnsProvider,
      'keyType': keyType,
      'cert': cert,
      'privateKey': privateKey,
      'chain': chain,
      'autoRenew': autoRenew,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        id,
        domains,
        certType,
        issuer,
        startDate,
        expireDate,
        days,
        status,
        dnsProvider,
        keyType,
        cert,
        privateKey,
        chain,
        autoRenew,
        createTime,
        updateTime,
      ];
}

/// Website authentication model
class WebsiteAuth extends Equatable {
  final int? id;
  final int? websiteId;
  final String? username;
  final String? password;
  final String? remark;
  final bool? enable;
  final String? createTime;
  final String? updateTime;

  const WebsiteAuth({
    this.id,
    this.websiteId,
    this.username,
    this.password,
    this.remark,
    this.enable,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteAuth.fromJson(Map<String, dynamic> json) {
    return WebsiteAuth(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      remark: json['remark'] as String?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'username': username,
      'password': password,
      'remark': remark,
      'enable': enable,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, username, password, remark, enable, createTime, updateTime];
}

/// Website authentication path model
class WebsiteAuthPath extends Equatable {
  final int? id;
  final int? websiteId;
  final String? path;
  final String? content;
  final String? remark;
  final bool? enable;
  final String? createTime;
  final String? updateTime;

  const WebsiteAuthPath({
    this.id,
    this.websiteId,
    this.path,
    this.content,
    this.remark,
    this.enable,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteAuthPath.fromJson(Map<String, dynamic> json) {
    return WebsiteAuthPath(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      path: json['path'] as String?,
      content: json['content'] as String?,
      remark: json['remark'] as String?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'path': path,
      'content': content,
      'remark': remark,
      'enable': enable,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, path, content, remark, enable, createTime, updateTime];
}

/// Website database model
class WebsiteDatabase extends Equatable {
  final int? id;
  final String? websiteId;
  final String? database;
  final String? username;
  final String? password;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const WebsiteDatabase({
    this.id,
    this.websiteId,
    this.database,
    this.username,
    this.password,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteDatabase.fromJson(Map<String, dynamic> json) {
    return WebsiteDatabase(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as String?,
      database: json['database'] as String?,
      username: json['username'] as String?,
      password: json['password'] as String?,
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'database': database,
      'username': username,
      'password': password,
      'remark': remark,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, database, username, password, remark, createTime, updateTime];
}

/// Website directory model
class WebsiteDirectory extends Equatable {
  final String? path;
  final String? permission;
  final String? user;
  final String? group;

  const WebsiteDirectory({
    this.path,
    this.permission,
    this.user,
    this.group,
  });

  factory WebsiteDirectory.fromJson(Map<String, dynamic> json) {
    return WebsiteDirectory(
      path: json['path'] as String?,
      permission: json['permission'] as String?,
      user: json['user'] as String?,
      group: json['group'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'permission': permission,
      'user': user,
      'group': group,
    };
  }

  @override
  List<Object?> get props => [path, permission, user, group];
}

/// Website load balancer model
class WebsiteLoadBalancer extends Equatable {
  final int? id;
  final String? name;
  final String? type;
  final String? address;
  final int? port;
  final String? path;
  final bool? enable;
  final List<String>? upstreams;
  final String? createTime;
  final String? updateTime;

  const WebsiteLoadBalancer({
    this.id,
    this.name,
    this.type,
    this.address,
    this.port,
    this.path,
    this.enable,
    this.upstreams,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteLoadBalancer.fromJson(Map<String, dynamic> json) {
    return WebsiteLoadBalancer(
      id: json['id'] as int?,
      name: json['name'] as String?,
      type: json['type'] as String?,
      address: json['address'] as String?,
      port: json['port'] as int?,
      path: json['path'] as String?,
      enable: json['enable'] as bool?,
      upstreams: (json['upstreams'] as List?)?.map((e) => e as String).toList(),
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'port': port,
      'path': path,
      'enable': enable,
      'upstreams': upstreams,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, name, type, address, port, path, enable, upstreams, createTime, updateTime];
}

/// Website leech protection model
class WebsiteLeech extends Equatable {
  final int? id;
  final int? websiteId;
  final List<String>? extensions;
  final List<String>? domains;
  final bool? enable;
  final String? remark;
  final String? createTime;
  final String? updateTime;

  const WebsiteLeech({
    this.id,
    this.websiteId,
    this.extensions,
    this.domains,
    this.enable,
    this.remark,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteLeech.fromJson(Map<String, dynamic> json) {
    return WebsiteLeech(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      extensions: (json['extensions'] as List?)?.map((e) => e as String).toList(),
      domains: (json['domains'] as List?)?.map((e) => e as String).toList(),
      enable: json['enable'] as bool?,
      remark: json['remark'] as String?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'extensions': extensions,
      'domains': domains,
      'enable': enable,
      'remark': remark,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, extensions, domains, enable, remark, createTime, updateTime];
}

/// Website log model
class WebsiteLog extends Equatable {
  final String? path;
  final String? type;
  final int? lines;
  final String? content;

  const WebsiteLog({
    this.path,
    this.type,
    this.lines,
    this.content,
  });

  factory WebsiteLog.fromJson(Map<String, dynamic> json) {
    return WebsiteLog(
      path: json['path'] as String?,
      type: json['type'] as String?,
      lines: json['lines'] as int?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'type': type,
      'lines': lines,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [path, type, lines, content];
}

/// Website real IP model
class WebsiteRealIP extends Equatable {
  final int? id;
  final int? websiteId;
  final String? header;
  final String? addr;
  final bool? enable;
  final String? createTime;
  final String? updateTime;

  const WebsiteRealIP({
    this.id,
    this.websiteId,
    this.header,
    this.addr,
    this.enable,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteRealIP.fromJson(Map<String, dynamic> json) {
    return WebsiteRealIP(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      header: json['header'] as String?,
      addr: json['addr'] as String?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'header': header,
      'addr': addr,
      'enable': enable,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, header, addr, enable, createTime, updateTime];
}

/// Website redirect model
class WebsiteRedirect extends Equatable {
  final int? id;
  final int? websiteId;
  final String? type;
  final String? domain;
  final String? path;
  final String? target;
  final bool? keepPath;
  final int? statusCode;
  final bool? enable;
  final String? createTime;
  final String? updateTime;

  const WebsiteRedirect({
    this.id,
    this.websiteId,
    this.type,
    this.domain,
    this.path,
    this.target,
    this.keepPath,
    this.statusCode,
    this.enable,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteRedirect.fromJson(Map<String, dynamic> json) {
    return WebsiteRedirect(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      type: json['type'] as String?,
      domain: json['domain'] as String?,
      path: json['path'] as String?,
      target: json['target'] as String?,
      keepPath: json['keepPath'] as bool?,
      statusCode: json['statusCode'] as int?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'type': type,
      'domain': domain,
      'path': path,
      'target': target,
      'keepPath': keepPath,
      'statusCode': statusCode,
      'enable': enable,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, type, domain, path, target, keepPath, statusCode, enable, createTime, updateTime];
}

/// Website resource model
class WebsiteResource extends Equatable {
  final String? type;
  final String? content;

  const WebsiteResource({
    this.type,
    this.content,
  });

  factory WebsiteResource.fromJson(Map<String, dynamic> json) {
    return WebsiteResource(
      type: json['type'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [type, content];
}

/// Website SSL model
class WebsiteSSL extends Equatable {
  final int? id;
  final int? websiteId;
  final List<String>? domains;
  final String? certType;
  final String? issuer;
  final String? startDate;
  final String? expireDate;
  final int? days;
  final String? status;
  final String? keyType;
  final bool? enable;
  final String? createTime;
  final String? updateTime;

  const WebsiteSSL({
    this.id,
    this.websiteId,
    this.domains,
    this.certType,
    this.issuer,
    this.startDate,
    this.expireDate,
    this.days,
    this.status,
    this.keyType,
    this.enable,
    this.createTime,
    this.updateTime,
  });

  factory WebsiteSSL.fromJson(Map<String, dynamic> json) {
    return WebsiteSSL(
      id: json['id'] as int?,
      websiteId: json['websiteId'] as int?,
      domains: (json['domains'] as List?)?.map((e) => e as String).toList(),
      certType: json['certType'] as String?,
      issuer: json['issuer'] as String?,
      startDate: json['startDate'] as String?,
      expireDate: json['expireDate'] as String?,
      days: json['days'] as int?,
      status: json['status'] as String?,
      keyType: json['keyType'] as String?,
      enable: json['enable'] as bool?,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'websiteId': websiteId,
      'domains': domains,
      'certType': certType,
      'issuer': issuer,
      'startDate': startDate,
      'expireDate': expireDate,
      'days': days,
      'status': status,
      'keyType': keyType,
      'enable': enable,
      'createTime': createTime,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [id, websiteId, domains, certType, issuer, startDate, expireDate, days, status, keyType, enable, createTime, updateTime];
}
