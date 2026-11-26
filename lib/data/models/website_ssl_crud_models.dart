import 'package:equatable/equatable.dart';

import 'package:onepanel_client/data/models/ssl_detail_models.dart';

/// Website SSL 模型
class WebsiteSSL extends Equatable {
  final int? id;
  final String? primaryDomain;
  final List<String>? domains;
  final String? provider;
  final int? acmeAccountId;
  final String? certURL;
  final String? certPath;
  final String? pem;
  final String? privateKey;
  final String? privateKeyPath;
  final String? startDate;
  final String? expireDate;
  final String? status;
  final String? type;
  final String? description;
  final bool? autoRenew;
  final int? caId;
  final String? keyType;
  final bool? disableCNAME;
  final bool? isIP;
  final int? masterSslId;
  final String? message;
  final String? logPath;
  final int? dnsAccountId;
  final bool? pushDir;
  final bool? pushNode;
  final bool? execShell;
  final String? shell;
  final String? dir;
  final bool? skipDNS;
  final String? nameserver1;
  final String? nameserver2;
  final String? nodes;
  final String? organization;
  final String? createdAt;
  final String? updatedAt;
  final ACMEAccount? acmeAccount;
  final DNSAccount? dnsAccount;
  final List<Website>? websites;

  const WebsiteSSL({
    this.id,
    this.primaryDomain,
    this.domains,
    this.provider,
    this.acmeAccountId,
    this.certURL,
    this.certPath,
    this.pem,
    this.privateKey,
    this.privateKeyPath,
    this.startDate,
    this.expireDate,
    this.status,
    this.type,
    this.description,
    this.autoRenew,
    this.caId,
    this.keyType,
    this.disableCNAME,
    this.isIP,
    this.masterSslId,
    this.message,
    this.logPath,
    this.dnsAccountId,
    this.pushDir,
    this.pushNode,
    this.execShell,
    this.shell,
    this.dir,
    this.skipDNS,
    this.nameserver1,
    this.nameserver2,
    this.nodes,
    this.organization,
    this.createdAt,
    this.updatedAt,
    this.acmeAccount,
    this.dnsAccount,
    this.websites,
  });

  static List<String>? _parseDomains(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().toList();
    }
    if (raw is String) {
      final parts =
          raw.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty).toList();
      return parts.isEmpty ? null : parts;
    }
    return null;
  }

  factory WebsiteSSL.fromJson(Map<String, dynamic> json) {
    return WebsiteSSL(
      id: json['id'] as int?,
      primaryDomain: json['primaryDomain'] as String?,
      domains: _parseDomains(json['domains']),
      provider: json['provider'] as String?,
      acmeAccountId: json['acmeAccountId'] as int?,
      certURL: json['certURL'] as String?,
      certPath: json['certPath'] as String?,
      pem: json['pem'] as String?,
      privateKey: json['privateKey'] as String?,
      privateKeyPath: json['privateKeyPath'] as String?,
      startDate: json['startDate'] as String?,
      expireDate: json['expireDate'] as String?,
      status: json['status'] as String?,
      type: json['type'] as String?,
      description: json['description'] as String?,
      autoRenew: json['autoRenew'] as bool?,
      caId: json['caId'] as int?,
      keyType: json['keyType'] as String?,
      disableCNAME: json['disableCNAME'] as bool?,
      isIP: json['isIP'] as bool? ?? json['isIp'] as bool?,
      masterSslId: json['masterSslId'] as int?,
      message: json['message'] as String?,
      logPath: json['logPath'] as String?,
      dnsAccountId: json['dnsAccountId'] as int?,
      pushDir: json['pushDir'] as bool?,
      pushNode: json['pushNode'] as bool?,
      execShell: json['execShell'] as bool?,
      shell: json['shell'] as String?,
      dir: json['dir'] as String?,
      skipDNS: json['skipDNS'] as bool?,
      nameserver1: json['nameserver1'] as String?,
      nameserver2: json['nameserver2'] as String?,
      nodes: json['nodes'] as String?,
      organization: json['organization'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      acmeAccount: json['acmeAccount'] != null
          ? ACMEAccount.fromJson(json['acmeAccount'] as Map<String, dynamic>)
          : null,
      dnsAccount: json['dnsAccount'] != null
          ? DNSAccount.fromJson(json['dnsAccount'] as Map<String, dynamic>)
          : null,
      websites: (json['websites'] as List?)
          ?.map((item) => Website.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryDomain': primaryDomain,
      'domains': domains,
      'provider': provider,
      'acmeAccountId': acmeAccountId,
      'certURL': certURL,
      'certPath': certPath,
      'pem': pem,
      'privateKey': privateKey,
      'privateKeyPath': privateKeyPath,
      'startDate': startDate,
      'expireDate': expireDate,
      'status': status,
      'type': type,
      'description': description,
      'autoRenew': autoRenew,
      'caId': caId,
      'keyType': keyType,
      'disableCNAME': disableCNAME,
      'isIP': isIP,
      'masterSslId': masterSslId,
      'message': message,
      'logPath': logPath,
      'dnsAccountId': dnsAccountId,
      'pushDir': pushDir,
      'pushNode': pushNode,
      'execShell': execShell,
      'shell': shell,
      'dir': dir,
      'skipDNS': skipDNS,
      'nameserver1': nameserver1,
      'nameserver2': nameserver2,
      'nodes': nodes,
      'organization': organization,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'acmeAccount': acmeAccount?.toJson(),
      'dnsAccount': dnsAccount?.toJson(),
      'websites': websites?.map((item) => item.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        primaryDomain,
        domains,
        provider,
        acmeAccountId,
        certURL,
        certPath,
        pem,
        privateKey,
        privateKeyPath,
        startDate,
        expireDate,
        status,
        type,
        description,
        autoRenew,
        caId,
        keyType,
        disableCNAME,
        isIP,
        masterSslId,
        message,
        logPath,
        dnsAccountId,
        pushDir,
        pushNode,
        execShell,
        shell,
        dir,
        skipDNS,
        nameserver1,
        nameserver2,
        nodes,
        organization,
        createdAt,
        updatedAt,
        acmeAccount,
        dnsAccount,
        websites,
      ];
}

/// Website HTTPS config response model
class WebsiteHttpsConfig extends Equatable {
  final bool? enable;
  final String? httpConfig;
  final String? algorithm;
  final bool? hsts;
  final bool? hstsIncludeSubDomains;
  final bool? http3;
  final String? httpsPort;
  final List<int> httpsPorts;
  final List<String> sslProtocol;
  final WebsiteSSL? ssl;

  const WebsiteHttpsConfig({
    this.enable,
    this.httpConfig,
    this.algorithm,
    this.hsts,
    this.hstsIncludeSubDomains,
    this.http3,
    this.httpsPort,
    this.httpsPorts = const [],
    this.sslProtocol = const [],
    this.ssl,
  });

  factory WebsiteHttpsConfig.fromJson(Map<String, dynamic> json) {
    return WebsiteHttpsConfig(
      enable: json['enable'] as bool?,
      httpConfig: json['httpConfig'] as String?,
      algorithm: json['algorithm'] as String?,
      hsts: json['hsts'] as bool?,
      hstsIncludeSubDomains: json['hstsIncludeSubDomains'] as bool?,
      http3: json['http3'] as bool?,
      httpsPort: json['httpsPort']?.toString(),
      httpsPorts: (json['httpsPorts'] as List?)
              ?.whereType<num>()
              .map((e) => e.toInt())
              .toList() ??
          const [],
      sslProtocol:
          (json['SSLProtocol'] as List?)?.whereType<String>().toList() ??
              const [],
      ssl: json['SSL'] is Map<String, dynamic>
          ? WebsiteSSL.fromJson(json['SSL'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      'httpConfig': httpConfig,
      'algorithm': algorithm,
      'hsts': hsts,
      'hstsIncludeSubDomains': hstsIncludeSubDomains,
      'http3': http3,
      'httpsPort': httpsPort,
      'httpsPorts': httpsPorts,
      'SSLProtocol': sslProtocol,
      'SSL': ssl?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        enable,
        httpConfig,
        algorithm,
        hsts,
        hstsIncludeSubDomains,
        http3,
        httpsPort,
        httpsPorts,
        sslProtocol,
        ssl,
      ];
}

/// Website HTTPS update request model
class WebsiteHttpsUpdateRequest extends Equatable {
  final int websiteId;
  final bool? enable;
  final String? httpConfig;
  final String? type;
  final int? websiteSSLId;
  final String? certificate;
  final String? certificatePath;
  final String? privateKey;
  final String? privateKeyPath;
  final List<int>? httpsPorts;
  final List<String>? sslProtocol;
  final bool? hsts;
  final bool? hstsIncludeSubDomains;
  final bool? http3;
  final String? algorithm;
  final String? importType;

  const WebsiteHttpsUpdateRequest({
    required this.websiteId,
    this.enable,
    this.httpConfig,
    this.type,
    this.websiteSSLId,
    this.certificate,
    this.certificatePath,
    this.privateKey,
    this.privateKeyPath,
    this.httpsPorts,
    this.sslProtocol,
    this.hsts,
    this.hstsIncludeSubDomains,
    this.http3,
    this.algorithm,
    this.importType,
  });

  factory WebsiteHttpsUpdateRequest.fromJson(Map<String, dynamic> json) {
    return WebsiteHttpsUpdateRequest(
      websiteId: json['websiteId'] as int? ?? json['websiteID'] as int? ?? 0,
      enable: json['enable'] as bool?,
      httpConfig: json['httpConfig'] as String?,
      type: json['type'] as String?,
      websiteSSLId:
          json['websiteSSLId'] as int? ?? json['websiteSSLID'] as int?,
      certificate: json['certificate'] as String?,
      certificatePath: json['certificatePath'] as String?,
      privateKey: json['privateKey'] as String?,
      privateKeyPath: json['privateKeyPath'] as String?,
      httpsPorts: (json['httpsPorts'] as List?)
          ?.whereType<num>()
          .map((e) => e.toInt())
          .toList(),
      sslProtocol: (json['SSLProtocol'] as List?)?.whereType<String>().toList(),
      hsts: json['hsts'] as bool?,
      hstsIncludeSubDomains: json['hstsIncludeSubDomains'] as bool?,
      http3: json['http3'] as bool?,
      algorithm: json['algorithm'] as String?,
      importType: json['importType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'websiteId': websiteId,
      if (enable != null) 'enable': enable,
      if (httpConfig != null) 'httpConfig': httpConfig,
      if (type != null) 'type': type,
      if (websiteSSLId != null) 'websiteSSLId': websiteSSLId,
      if (certificate != null) 'certificate': certificate,
      if (certificatePath != null) 'certificatePath': certificatePath,
      if (privateKey != null) 'privateKey': privateKey,
      if (privateKeyPath != null) 'privateKeyPath': privateKeyPath,
      if (httpsPorts != null) 'httpsPorts': httpsPorts,
      if (sslProtocol != null) 'SSLProtocol': sslProtocol,
      if (hsts != null) 'hsts': hsts,
      if (hstsIncludeSubDomains != null)
        'hstsIncludeSubDomains': hstsIncludeSubDomains,
      if (http3 != null) 'http3': http3,
      if (algorithm != null) 'algorithm': algorithm,
      if (importType != null) 'importType': importType,
    };
  }

  @override
  List<Object?> get props => [
        websiteId,
        enable,
        httpConfig,
        type,
        websiteSSLId,
        certificate,
        certificatePath,
        privateKey,
        privateKeyPath,
        httpsPorts,
        sslProtocol,
        hsts,
        hstsIncludeSubDomains,
        http3,
        algorithm,
        importType,
      ];
}

/// Website SSL 创建模型
class WebsiteSSLCreate extends Equatable {
  final int acmeAccountId;
  final String primaryDomain;
  final String provider;
  final int? id;
  final bool? apply;
  final bool? autoRenew;
  final String? description;
  final String? dir;
  final bool? disableCNAME;
  final int? dnsAccountId;
  final bool? execShell;
  final bool? isIp;
  final String? keyType;
  final String? nameserver1;
  final String? nameserver2;
  final String? nodes;
  final String? otherDomains;
  final bool? pushDir;
  final bool? pushNode;
  final String? shell;
  final bool? skipDNS;

  const WebsiteSSLCreate({
    required this.acmeAccountId,
    required this.primaryDomain,
    required this.provider,
    this.id,
    this.apply,
    this.autoRenew,
    this.description,
    this.dir,
    this.disableCNAME,
    this.dnsAccountId,
    this.execShell,
    this.isIp,
    this.keyType,
    this.nameserver1,
    this.nameserver2,
    this.nodes,
    this.otherDomains,
    this.pushDir,
    this.pushNode,
    this.shell,
    this.skipDNS,
  });

  factory WebsiteSSLCreate.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLCreate(
      acmeAccountId: json['acmeAccountId'] as int? ?? 0,
      primaryDomain: json['primaryDomain'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      id: json['id'] as int?,
      apply: json['apply'] as bool?,
      autoRenew: json['autoRenew'] as bool?,
      description: json['description'] as String?,
      dir: json['dir'] as String?,
      disableCNAME: json['disableCNAME'] as bool?,
      dnsAccountId: json['dnsAccountId'] as int?,
      execShell: json['execShell'] as bool?,
      isIp: json['isIp'] as bool? ?? json['isIP'] as bool?,
      keyType: json['keyType'] as String?,
      nameserver1: json['nameserver1'] as String?,
      nameserver2: json['nameserver2'] as String?,
      nodes: json['nodes'] as String?,
      otherDomains: json['otherDomains'] as String?,
      pushDir: json['pushDir'] as bool?,
      pushNode: json['pushNode'] as bool?,
      shell: json['shell'] as String?,
      skipDNS: json['skipDNS'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acmeAccountId': acmeAccountId,
      'primaryDomain': primaryDomain,
      'provider': provider,
      if (id != null) 'id': id,
      if (apply != null) 'apply': apply,
      if (autoRenew != null) 'autoRenew': autoRenew,
      if (description != null) 'description': description,
      if (dir != null) 'dir': dir,
      if (disableCNAME != null) 'disableCNAME': disableCNAME,
      if (dnsAccountId != null) 'dnsAccountId': dnsAccountId,
      if (execShell != null) 'execShell': execShell,
      if (isIp != null) 'isIp': isIp,
      if (keyType != null) 'keyType': keyType,
      if (nameserver1 != null) 'nameserver1': nameserver1,
      if (nameserver2 != null) 'nameserver2': nameserver2,
      if (nodes != null) 'nodes': nodes,
      if (otherDomains != null) 'otherDomains': otherDomains,
      if (pushDir != null) 'pushDir': pushDir,
      if (pushNode != null) 'pushNode': pushNode,
      if (shell != null) 'shell': shell,
      if (skipDNS != null) 'skipDNS': skipDNS,
    };
  }

  @override
  List<Object?> get props => [
        acmeAccountId,
        primaryDomain,
        provider,
        id,
        apply,
        autoRenew,
        description,
        dir,
        disableCNAME,
        dnsAccountId,
        execShell,
        isIp,
        keyType,
        nameserver1,
        nameserver2,
        nodes,
        otherDomains,
        pushDir,
        pushNode,
        shell,
        skipDNS,
      ];
}

/// Website SSL 申请模型
class WebsiteSSLApply extends Equatable {
  final int id;
  final bool? disableLog;
  final List<String>? nameservers;
  final bool? skipDNSCheck;

  const WebsiteSSLApply({
    required this.id,
    this.disableLog,
    this.nameservers,
    this.skipDNSCheck,
  });

  factory WebsiteSSLApply.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLApply(
      id: json['ID'] as int? ?? json['id'] as int? ?? 0,
      disableLog: json['disableLog'] as bool?,
      nameservers: (json['nameservers'] as List?)?.whereType<String>().toList(),
      skipDNSCheck: json['skipDNSCheck'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      if (disableLog != null) 'disableLog': disableLog,
      if (nameservers != null) 'nameservers': nameservers,
      if (skipDNSCheck != null) 'skipDNSCheck': skipDNSCheck,
    };
  }

  @override
  List<Object?> get props => [id, disableLog, nameservers, skipDNSCheck];
}

/// Website SSL 解析模型
class WebsiteSSLResolve extends Equatable {
  final int acmeAccountId;
  final int websiteSSLId;

  const WebsiteSSLResolve({
    required this.acmeAccountId,
    required this.websiteSSLId,
  });

  factory WebsiteSSLResolve.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLResolve(
      acmeAccountId: json['acmeAccountId'] as int? ?? 0,
      websiteSSLId: json['websiteSSLId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acmeAccountId': acmeAccountId,
      'websiteSSLId': websiteSSLId,
    };
  }

  @override
  List<Object?> get props => [acmeAccountId, websiteSSLId];
}

/// Website SSL 搜索模型
class WebsiteSSLSearch extends Equatable {
  final int page;
  final int pageSize;
  final String? domain;
  final String? acmeAccountId;
  final String order;
  final String orderBy;

  const WebsiteSSLSearch({
    required this.page,
    required this.pageSize,
    this.domain,
    this.acmeAccountId,
    this.order = 'descending',
    this.orderBy = 'expire_date',
  });

  factory WebsiteSSLSearch.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLSearch(
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 10,
      domain: json['domain'] as String?,
      acmeAccountId:
          json['acmeAccountID'] as String? ?? json['acmeAccountId'] as String?,
      order: json['order'] as String? ?? 'descending',
      orderBy: json['orderBy'] as String? ?? 'expire_date',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'pageSize': pageSize,
      if (domain != null) 'domain': domain,
      if (acmeAccountId != null) 'acmeAccountID': acmeAccountId,
      'order': order,
      'orderBy': orderBy,
    };
  }

  @override
  List<Object?> get props =>
      [page, pageSize, domain, acmeAccountId, order, orderBy];
}

/// Website SSL 更新模型
class WebsiteSSLUpdate extends Equatable {
  final int id;
  final String primaryDomain;
  final String provider;
  final int? acmeAccountId;
  final bool? apply;
  final bool? autoRenew;
  final String? description;
  final String? dir;
  final bool? disableCNAME;
  final int? dnsAccountId;
  final bool? execShell;
  final String? keyType;
  final String? nameserver1;
  final String? nameserver2;
  final String? nodes;
  final String? otherDomains;
  final bool? pushDir;
  final bool? pushNode;
  final String? shell;
  final bool? skipDNS;

  const WebsiteSSLUpdate({
    required this.id,
    required this.primaryDomain,
    required this.provider,
    this.acmeAccountId,
    this.apply,
    this.autoRenew,
    this.description,
    this.dir,
    this.disableCNAME,
    this.dnsAccountId,
    this.execShell,
    this.keyType,
    this.nameserver1,
    this.nameserver2,
    this.nodes,
    this.otherDomains,
    this.pushDir,
    this.pushNode,
    this.shell,
    this.skipDNS,
  });

  factory WebsiteSSLUpdate.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLUpdate(
      id: json['id'] as int? ?? 0,
      primaryDomain: json['primaryDomain'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      acmeAccountId: json['acmeAccountId'] as int?,
      apply: json['apply'] as bool?,
      autoRenew: json['autoRenew'] as bool?,
      description: json['description'] as String?,
      dir: json['dir'] as String?,
      disableCNAME: json['disableCNAME'] as bool?,
      dnsAccountId: json['dnsAccountId'] as int?,
      execShell: json['execShell'] as bool?,
      keyType: json['keyType'] as String?,
      nameserver1: json['nameserver1'] as String?,
      nameserver2: json['nameserver2'] as String?,
      nodes: json['nodes'] as String?,
      otherDomains: json['otherDomains'] as String?,
      pushDir: json['pushDir'] as bool?,
      pushNode: json['pushNode'] as bool?,
      shell: json['shell'] as String?,
      skipDNS: json['skipDNS'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primaryDomain': primaryDomain,
      'provider': provider,
      if (acmeAccountId != null) 'acmeAccountId': acmeAccountId,
      if (apply != null) 'apply': apply,
      if (autoRenew != null) 'autoRenew': autoRenew,
      if (description != null) 'description': description,
      if (dir != null) 'dir': dir,
      if (disableCNAME != null) 'disableCNAME': disableCNAME,
      if (dnsAccountId != null) 'dnsAccountId': dnsAccountId,
      if (execShell != null) 'execShell': execShell,
      if (keyType != null) 'keyType': keyType,
      if (nameserver1 != null) 'nameserver1': nameserver1,
      if (nameserver2 != null) 'nameserver2': nameserver2,
      if (nodes != null) 'nodes': nodes,
      if (otherDomains != null) 'otherDomains': otherDomains,
      if (pushDir != null) 'pushDir': pushDir,
      if (pushNode != null) 'pushNode': pushNode,
      if (shell != null) 'shell': shell,
      if (skipDNS != null) 'skipDNS': skipDNS,
    };
  }

  @override
  List<Object?> get props => [
        id,
        primaryDomain,
        provider,
        acmeAccountId,
        apply,
        autoRenew,
        description,
        dir,
        disableCNAME,
        dnsAccountId,
        execShell,
        keyType,
        nameserver1,
        nameserver2,
        nodes,
        otherDomains,
        pushDir,
        pushNode,
        shell,
        skipDNS,
      ];
}

/// Website SSL 上传模型
class WebsiteSSLUpload extends Equatable {
  final int? sslID;
  final String? privateKey;
  final String? certificate;
  final String? certificatePath;
  final String? privateKeyPath;
  final String? description;
  final String type;

  const WebsiteSSLUpload({
    this.sslID,
    this.privateKey,
    this.certificate,
    this.certificatePath,
    this.privateKeyPath,
    this.description,
    required this.type,
  });

  factory WebsiteSSLUpload.fromJson(Map<String, dynamic> json) {
    return WebsiteSSLUpload(
      sslID: json['sslID'] as int?,
      privateKey: json['privateKey'] as String?,
      certificate: json['certificate'] as String?,
      certificatePath: json['certificatePath'] as String?,
      privateKeyPath: json['privateKeyPath'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'paste',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sslID': sslID,
      'privateKey': privateKey,
      'certificate': certificate,
      'certificatePath': certificatePath,
      'privateKeyPath': privateKeyPath,
      if (description != null) 'description': description,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [
        sslID,
        privateKey,
        certificate,
        certificatePath,
        privateKeyPath,
        description,
        type
      ];
}
