import 'package:equatable/equatable.dart';
import 'ssl_models.dart' as ssl_models;
export 'package:onepanel_client/data/models/website_aux_models.dart';

/// Website creation request model
class WebsiteCreate extends Equatable {
  final bool? ipv6;
  final String? algorithm;
  final String alias;
  final int? appId;
  final Map<String, dynamic>? appInstall;
  final int? appInstallId;
  final String? appType;
  final bool? createDb;
  final String? dbFormat;
  final String? dbHost;
  final String? dbName;
  final String? dbPassword;
  final String? dbUser;
  final List<WebsiteDomain>? domains;
  final bool? enableSSL;
  final String? ftpPassword;
  final String? ftpUser;
  final String? name;
  final int? parentWebsiteId;
  final int? port;
  final String? proxy;
  final String? proxyType;
  final String? remark;
  final int? runtimeId;
  final List<NginxUpstreamServer>? servers;
  final String? siteDir;
  final String? streamPorts;
  final String? taskId;
  final String type;
  final int webSiteGroupId;
  final int? websiteSSLId;

  const WebsiteCreate({
    this.ipv6,
    this.algorithm,
    required this.alias,
    this.appId,
    this.appInstall,
    this.appInstallId,
    this.appType,
    this.createDb,
    this.dbFormat,
    this.dbHost,
    this.dbName,
    this.dbPassword,
    this.dbUser,
    this.domains,
    this.enableSSL,
    this.ftpPassword,
    this.ftpUser,
    this.name,
    this.parentWebsiteId,
    this.port,
    this.proxy,
    this.proxyType,
    this.remark,
    this.runtimeId,
    this.servers,
    this.siteDir,
    this.streamPorts,
    this.taskId,
    required this.type,
    required this.webSiteGroupId,
    this.websiteSSLId,
  });

  factory WebsiteCreate.fromJson(Map<String, dynamic> json) {
    return WebsiteCreate(
      ipv6: json['IPV6'] as bool? ?? json['ipv6'] as bool?,
      algorithm: json['algorithm'] as String?,
      alias: json['alias'] as String? ?? '',
      appId: json['appID'] as int? ?? json['appId'] as int?,
      appInstall: json['appInstall'] as Map<String, dynamic>?,
      appInstallId:
          json['appInstallID'] as int? ?? json['appInstallId'] as int?,
      appType: json['appType'] as String?,
      createDb: json['createDb'] as bool?,
      dbFormat: json['dbFormat'] as String?,
      dbHost: json['dbHost'] as String?,
      dbName: json['dbName'] as String?,
      dbPassword: json['dbPassword'] as String?,
      dbUser: json['dbUser'] as String?,
      domains: (json['domains'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(WebsiteDomain.fromJson)
          .toList(),
      enableSSL: json['enableSSL'] as bool?,
      ftpPassword: json['ftpPassword'] as String?,
      ftpUser: json['ftpUser'] as String?,
      name: json['name'] as String?,
      parentWebsiteId:
          json['parentWebsiteID'] as int? ?? json['parentWebsiteId'] as int?,
      port: json['port'] as int?,
      proxy: json['proxy'] as String?,
      proxyType: json['proxyType'] as String?,
      remark: json['remark'] as String?,
      runtimeId: json['runtimeID'] as int? ?? json['runtimeId'] as int?,
      servers: (json['servers'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(NginxUpstreamServer.fromJson)
          .toList(),
      siteDir: json['siteDir'] as String?,
      streamPorts: json['streamPorts'] as String?,
      taskId: json['taskID'] as String? ?? json['taskId'] as String?,
      type: json['type'] as String? ?? '',
      webSiteGroupId:
          json['webSiteGroupID'] as int? ?? json['webSiteGroupId'] as int? ?? 0,
      websiteSSLId:
          json['websiteSSLID'] as int? ?? json['websiteSSLId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (ipv6 != null) 'IPV6': ipv6,
      if (algorithm != null) 'algorithm': algorithm,
      'alias': alias,
      if (appId != null) 'appID': appId,
      if (appInstall != null) 'appInstall': appInstall,
      if (appInstallId != null) 'appInstallID': appInstallId,
      if (appType != null) 'appType': appType,
      if (createDb != null) 'createDb': createDb,
      if (dbFormat != null) 'dbFormat': dbFormat,
      if (dbHost != null) 'dbHost': dbHost,
      if (dbName != null) 'dbName': dbName,
      if (dbPassword != null) 'dbPassword': dbPassword,
      if (dbUser != null) 'dbUser': dbUser,
      if (domains != null) 'domains': domains!.map((e) => e.toJson()).toList(),
      if (enableSSL != null) 'enableSSL': enableSSL,
      if (ftpPassword != null) 'ftpPassword': ftpPassword,
      if (ftpUser != null) 'ftpUser': ftpUser,
      if (name != null) 'name': name,
      if (parentWebsiteId != null) 'parentWebsiteID': parentWebsiteId,
      if (port != null) 'port': port,
      if (proxy != null) 'proxy': proxy,
      if (proxyType != null) 'proxyType': proxyType,
      if (remark != null) 'remark': remark,
      if (runtimeId != null) 'runtimeID': runtimeId,
      if (servers != null) 'servers': servers!.map((e) => e.toJson()).toList(),
      if (siteDir != null) 'siteDir': siteDir,
      if (streamPorts != null) 'streamPorts': streamPorts,
      if (taskId != null) 'taskID': taskId,
      'type': type,
      'webSiteGroupID': webSiteGroupId,
      if (websiteSSLId != null) 'websiteSSLID': websiteSSLId,
    };
  }

  @override
  List<Object?> get props => [
        ipv6,
        algorithm,
        alias,
        appId,
        appInstall,
        appInstallId,
        appType,
        createDb,
        dbFormat,
        dbHost,
        dbName,
        dbPassword,
        dbUser,
        domains,
        enableSSL,
        ftpPassword,
        ftpUser,
        name,
        parentWebsiteId,
        port,
        proxy,
        proxyType,
        remark,
        runtimeId,
        servers,
        siteDir,
        streamPorts,
        taskId,
        type,
        webSiteGroupId,
        websiteSSLId,
      ];
}

class WebsiteUpdate extends Equatable {
  const WebsiteUpdate({
    required this.id,
    required this.primaryDomain,
    required this.remark,
    required this.webSiteGroupId,
    required this.ipv6,
    required this.favorite,
  });

  final int id;
  final String primaryDomain;
  final String remark;
  final int webSiteGroupId;
  final bool ipv6;
  final bool favorite;

  factory WebsiteUpdate.fromJson(Map<String, dynamic> json) {
    return WebsiteUpdate(
      id: json['id'] as int? ?? 0,
      primaryDomain: json['primaryDomain'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      webSiteGroupId:
          json['webSiteGroupId'] as int? ?? json['webSiteGroupID'] as int? ?? 0,
      ipv6: json['IPV6'] as bool? ?? json['ipv6'] as bool? ?? false,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryDomain': primaryDomain,
      'remark': remark,
      'webSiteGroupId': webSiteGroupId,
      'IPV6': ipv6,
      'favorite': favorite,
    };
  }

  @override
  List<Object?> get props => [
        id,
        primaryDomain,
        remark,
        webSiteGroupId,
        ipv6,
        favorite,
      ];
}

/// Website information model
class WebsiteInfo extends Equatable {
  final int? id;
  final String? primaryDomain;
  final String? alias;
  final String? type;
  final String? status;
  final String? protocol;
  final String? siteDir;
  final String? sitePath;
  final String? remark;
  final String? rewrite;
  final String? httpConfig;
  final String? proxy;
  final String? proxyType;
  final String? group;
  final String? user;
  final String? streamPorts;
  final String? expireDate;
  final String? sslExpireDate;
  final String? sslStatus;
  final String? createdAt;
  final String? updatedAt;
  final bool? ipv6;
  final bool? accessLog;
  final String? accessLogPath;
  final bool? errorLog;
  final String? errorLogPath;
  final bool? defaultServer;
  final bool? favorite;
  final bool? openBaseDir;
  final String? algorithm;
  final bool? udp;
  final int? runtimeId;
  final String? runtimeName;
  final String? runtimeTypeName;
  final int? appInstallId;
  final String? appName;
  final int? dbId;
  final String? dbType;
  final int? ftpId;
  final int? parentWebsiteId;
  final String? parentSite;
  final List<dynamic>? childSites;
  final int? webSiteGroupId;
  final int? webSiteSSLId;
  final ssl_models.WebsiteSSL? webSiteSSL;
  final List<WebsiteDomain> domains;
  final List<NginxUpstreamServer> servers;

  const WebsiteInfo({
    this.id,
    this.primaryDomain,
    this.alias,
    this.type,
    this.status,
    this.protocol,
    this.siteDir,
    this.sitePath,
    this.remark,
    this.rewrite,
    this.httpConfig,
    this.proxy,
    this.proxyType,
    this.group,
    this.user,
    this.streamPorts,
    this.expireDate,
    this.sslExpireDate,
    this.sslStatus,
    this.createdAt,
    this.updatedAt,
    this.ipv6,
    this.accessLog,
    this.accessLogPath,
    this.errorLog,
    this.errorLogPath,
    this.defaultServer,
    this.favorite,
    this.openBaseDir,
    this.algorithm,
    this.udp,
    this.runtimeId,
    this.runtimeName,
    this.runtimeTypeName,
    this.appInstallId,
    this.appName,
    this.dbId,
    this.dbType,
    this.ftpId,
    this.parentWebsiteId,
    this.parentSite,
    this.childSites,
    this.webSiteGroupId,
    this.webSiteSSLId,
    this.webSiteSSL,
    this.domains = const [],
    this.servers = const [],
  });

  String? get displayDomain {
    if (primaryDomain != null && primaryDomain!.isNotEmpty) {
      return primaryDomain;
    }
    final domainFromList = domains.isNotEmpty ? domains.first.domain : null;
    return domainFromList ?? alias;
  }

  factory WebsiteInfo.fromJson(Map<String, dynamic> json) {
    return WebsiteInfo(
      id: json['id'] as int?,
      primaryDomain:
          json['primaryDomain'] as String? ?? json['domain'] as String?,
      alias: json['alias'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      protocol: json['protocol'] as String?,
      siteDir: json['siteDir'] as String?,
      sitePath: json['sitePath'] as String?,
      remark: json['remark'] as String?,
      rewrite: json['rewrite'] as String?,
      httpConfig: json['httpConfig'] as String?,
      proxy: json['proxy'] as String?,
      proxyType: json['proxyType'] as String?,
      group: json['group'] as String?,
      user: json['user'] as String?,
      streamPorts: json['streamPorts'] as String?,
      expireDate: json['expireDate'] as String?,
      sslExpireDate: json['sslExpireDate'] as String?,
      sslStatus: json['sslStatus'] as String?,
      createdAt: json['createdAt'] as String? ?? json['createTime'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updateTime'] as String?,
      ipv6: json['IPV6'] as bool? ?? json['ipv6'] as bool?,
      accessLog: json['accessLog'] as bool?,
      accessLogPath: json['accessLogPath'] as String?,
      errorLog: json['errorLog'] as bool?,
      errorLogPath: json['errorLogPath'] as String?,
      defaultServer: json['defaultServer'] as bool?,
      favorite: json['favorite'] as bool?,
      openBaseDir: json['openBaseDir'] as bool?,
      algorithm: json['algorithm'] as String?,
      udp: json['udp'] as bool?,
      runtimeId: json['runtimeID'] as int? ?? json['runtimeId'] as int?,
      runtimeName: json['runtimeName'] as String?,
      runtimeTypeName: json['runtimeType'] as String?,
      appInstallId:
          json['appInstallId'] as int? ?? json['appInstallID'] as int?,
      appName: json['appName'] as String?,
      dbId: json['dbID'] as int? ?? json['dbId'] as int?,
      dbType: json['dbType'] as String?,
      ftpId: json['ftpId'] as int?,
      parentWebsiteId:
          json['parentWebsiteID'] as int? ?? json['parentWebsiteId'] as int?,
      parentSite: json['parentSite'] as String?,
      childSites: json['childSites'] as List?,
      webSiteGroupId:
          json['webSiteGroupId'] as int? ?? json['webSiteGroupID'] as int?,
      webSiteSSLId:
          json['webSiteSSLId'] as int? ?? json['webSiteSSLID'] as int?,
      webSiteSSL: json['webSiteSSL'] is Map<String, dynamic>
          ? ssl_models.WebsiteSSL.fromJson(
              json['webSiteSSL'] as Map<String, dynamic>)
          : null,
      domains: (json['domains'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(WebsiteDomain.fromJson)
              .toList() ??
          const [],
      servers: (json['servers'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(NginxUpstreamServer.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryDomain': primaryDomain,
      'alias': alias,
      'type': type,
      'status': status,
      'protocol': protocol,
      'siteDir': siteDir,
      'sitePath': sitePath,
      'remark': remark,
      'rewrite': rewrite,
      'httpConfig': httpConfig,
      'proxy': proxy,
      'proxyType': proxyType,
      'group': group,
      'user': user,
      'streamPorts': streamPorts,
      'expireDate': expireDate,
      'sslExpireDate': sslExpireDate,
      'sslStatus': sslStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'IPV6': ipv6,
      'accessLog': accessLog,
      'accessLogPath': accessLogPath,
      'errorLog': errorLog,
      'errorLogPath': errorLogPath,
      'defaultServer': defaultServer,
      'favorite': favorite,
      'openBaseDir': openBaseDir,
      'algorithm': algorithm,
      'udp': udp,
      'runtimeID': runtimeId,
      'runtimeName': runtimeName,
      'runtimeType': runtimeTypeName,
      'appInstallId': appInstallId,
      'appName': appName,
      'dbID': dbId,
      'dbType': dbType,
      'ftpId': ftpId,
      'parentWebsiteID': parentWebsiteId,
      'parentSite': parentSite,
      'childSites': childSites,
      'webSiteGroupId': webSiteGroupId,
      'webSiteSSLId': webSiteSSLId,
      'webSiteSSL': webSiteSSL?.toJson(),
      'domains': domains.map((e) => e.toJson()).toList(),
      'servers': servers.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        primaryDomain,
        alias,
        type,
        status,
        protocol,
        siteDir,
        sitePath,
        remark,
        rewrite,
        httpConfig,
        proxy,
        proxyType,
        group,
        user,
        streamPorts,
        expireDate,
        sslExpireDate,
        sslStatus,
        createdAt,
        updatedAt,
        ipv6,
        accessLog,
        accessLogPath,
        errorLog,
        errorLogPath,
        defaultServer,
        favorite,
        openBaseDir,
        algorithm,
        udp,
        runtimeId,
        runtimeName,
        runtimeTypeName,
        appInstallId,
        appName,
        dbId,
        dbType,
        ftpId,
        parentWebsiteId,
        parentSite,
        childSites,
        webSiteGroupId,
        webSiteSSLId,
        webSiteSSL,
        domains,
        servers,
      ];
}

/// Website search request model
class WebsiteSearch extends Equatable {
  final int page;
  final int pageSize;
  final String order;
  final String orderBy;
  final String? name;
  final String? type;
  final int? websiteGroupId;

  const WebsiteSearch({
    this.page = 1,
    this.pageSize = 10,
    this.order = 'descending',
    this.orderBy = 'createdAt',
    this.name,
    this.type,
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
      if (websiteGroupId != null) 'websiteGroupId': websiteGroupId,
    };
  }

  @override
  List<Object?> get props =>
      [page, pageSize, order, orderBy, name, type, websiteGroupId];
}

/// Website PHP version update request
class WebsitePhpVersionRequest extends Equatable {
  final int websiteId;
  final int? runtimeId;

  const WebsitePhpVersionRequest({
    required this.websiteId,
    this.runtimeId,
  });

  factory WebsitePhpVersionRequest.fromJson(Map<String, dynamic> json) {
    return WebsitePhpVersionRequest(
      websiteId: json['websiteID'] as int? ?? json['websiteId'] as int? ?? 0,
      runtimeId: json['runtimeID'] as int? ?? json['runtimeId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'websiteID': websiteId,
      if (runtimeId != null) 'runtimeID': runtimeId,
    };
  }

  @override
  List<Object?> get props => [websiteId, runtimeId];
}

/// Nginx scope param item
class WebsiteNginxParam extends Equatable {
  final String? name;
  final List<String> params;

  const WebsiteNginxParam({this.name, this.params = const []});

  factory WebsiteNginxParam.fromJson(Map<String, dynamic> json) {
    return WebsiteNginxParam(
      name: json['name'] as String?,
      params:
          (json['params'] as List?)?.whereType<String>().toList() ?? const [],
    );
  }

  WebsiteNginxParam copyWith({String? name, List<String>? params}) {
    return WebsiteNginxParam(
      name: name ?? this.name,
      params: params ?? this.params,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'params': params,
    };
  }

  @override
  List<Object?> get props => [name, params];
}

/// Nginx scope response
class WebsiteNginxScopeResponse extends Equatable {
  final bool? enable;
  final List<WebsiteNginxParam> params;

  const WebsiteNginxScopeResponse({this.enable, this.params = const []});

  factory WebsiteNginxScopeResponse.fromJson(Map<String, dynamic> json) {
    return WebsiteNginxScopeResponse(
      enable: json['enable'] as bool?,
      params: (json['params'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(WebsiteNginxParam.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      'params': params.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [enable, params];
}

/// Website domain model
class WebsiteDomain extends Equatable {
  final int? id;
  final String? domain;
  final int? websiteId;
  final bool? ssl;
  final int? port;
  final String? createdAt;
  final String? updatedAt;
  final String? websiteName;
  final bool? isDefault;

  const WebsiteDomain({
    this.id,
    this.domain,
    this.websiteId,
    this.ssl,
    this.port,
    this.createdAt,
    this.updatedAt,
    this.websiteName,
    this.isDefault,
  });

  factory WebsiteDomain.fromJson(Map<String, dynamic> json) {
    return WebsiteDomain(
      id: json['id'] as int?,
      domain: json['domain'] as String?,
      websiteId: json['websiteId'] as int? ?? json['websiteID'] as int?,
      ssl: json['ssl'] as bool?,
      port: json['port'] as int?,
      createdAt: json['createdAt'] as String? ?? json['createTime'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updateTime'] as String?,
      websiteName: json['websiteName'] as String?,
      isDefault: json['isDefault'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain': domain,
      'websiteId': websiteId,
      'ssl': ssl,
      'port': port,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'websiteName': websiteName,
      'isDefault': isDefault,
    };
  }

  @override
  List<Object?> get props => [
        id,
        domain,
        websiteId,
        ssl,
        port,
        createdAt,
        updatedAt,
        websiteName,
        isDefault
      ];
}

/// Nginx upstream server model
class NginxUpstreamServer extends Equatable {
  final String? server;
  final int? weight;
  final int? maxFails;
  final int? maxConns;
  final int? failTimeout;
  final String? failTimeoutUnit;
  final String? flag;

  const NginxUpstreamServer({
    this.server,
    this.weight,
    this.maxFails,
    this.maxConns,
    this.failTimeout,
    this.failTimeoutUnit,
    this.flag,
  });

  factory NginxUpstreamServer.fromJson(Map<String, dynamic> json) {
    return NginxUpstreamServer(
      server: json['server'] as String?,
      weight: json['weight'] as int?,
      maxFails: json['maxFails'] as int?,
      maxConns: json['maxConns'] as int?,
      failTimeout: json['failTimeout'] as int?,
      failTimeoutUnit: json['failTimeoutUnit'] as String?,
      flag: json['flag'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'weight': weight,
      'maxFails': maxFails,
      'maxConns': maxConns,
      'failTimeout': failTimeout,
      'failTimeoutUnit': failTimeoutUnit,
      'flag': flag,
    };
  }

  @override
  List<Object?> get props =>
      [server, weight, maxFails, maxConns, failTimeout, failTimeoutUnit, flag];
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
  List<Object?> get props => [
        id,
        domain,
        certType,
        issuer,
        startDate,
        expireDate,
        days,
        status,
        createTime,
        updateTime
      ];
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
      domains:
          (json['domains'] as List?)?.map((e) => e as String).toList() ?? [],
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
