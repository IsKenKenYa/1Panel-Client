import 'package:equatable/equatable.dart';

/// OpenResty status model
class OpenrestyStatus extends Equatable {
  final int? accepts;
  final int? active;
  final int? handled;
  final int? requests;
  final int? reading;
  final int? writing;
  final int? waiting;

  const OpenrestyStatus({
    this.accepts,
    this.active,
    this.handled,
    this.requests,
    this.reading,
    this.writing,
    this.waiting,
  });

  factory OpenrestyStatus.fromJson(Map<String, dynamic> json) {
    return OpenrestyStatus(
      accepts: json['accepts'] as int?,
      active: json['active'] as int?,
      handled: json['handled'] as int?,
      requests: json['requests'] as int?,
      reading: json['reading'] as int?,
      writing: json['writing'] as int?,
      waiting: json['waiting'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accepts': accepts,
      'active': active,
      'handled': handled,
      'requests': requests,
      'reading': reading,
      'writing': writing,
      'waiting': waiting,
    };
  }

  @override
  List<Object?> get props => [
        accepts,
        active,
        handled,
        requests,
        reading,
        writing,
        waiting,
      ];
}

class OpenrestyFile extends Equatable {
  final String? content;

  const OpenrestyFile({this.content});

  factory OpenrestyFile.fromJson(Map<String, dynamic> json) {
    return OpenrestyFile(
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  @override
  List<Object?> get props => [content];
}

class OpenrestyHttpsConfig extends Equatable {
  final bool? https;
  final bool? sslRejectHandshake;

  const OpenrestyHttpsConfig({
    this.https,
    this.sslRejectHandshake,
  });

  factory OpenrestyHttpsConfig.fromJson(Map<String, dynamic> json) {
    return OpenrestyHttpsConfig(
      https: json['https'] as bool?,
      sslRejectHandshake: json['sslRejectHandshake'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'https': https,
      'sslRejectHandshake': sslRejectHandshake,
    };
  }

  @override
  List<Object?> get props => [https, sslRejectHandshake];
}

class OpenrestyModule extends Equatable {
  final bool? enable;
  final String? name;
  final String? packages;
  final String? params;
  final String? script;

  const OpenrestyModule({
    this.enable,
    this.name,
    this.packages,
    this.params,
    this.script,
  });

  factory OpenrestyModule.fromJson(Map<String, dynamic> json) {
    return OpenrestyModule(
      enable: json['enable'] as bool?,
      name: json['name'] as String?,
      packages: json['packages'] as String?,
      params: json['params'] as String?,
      script: json['script'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enable': enable,
      'name': name,
      'packages': packages,
      'params': params,
      'script': script,
    };
  }

  @override
  List<Object?> get props => [enable, name, packages, params, script];
}

class OpenrestyBuildConfig extends Equatable {
  final String? mirror;
  final List<OpenrestyModule> modules;

  const OpenrestyBuildConfig({
    this.mirror,
    this.modules = const [],
  });

  factory OpenrestyBuildConfig.fromJson(Map<String, dynamic> json) {
    return OpenrestyBuildConfig(
      mirror: json['mirror'] as String?,
      modules: (json['modules'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(OpenrestyModule.fromJson)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mirror': mirror,
      'modules': modules.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [mirror, modules];
}

class OpenrestyParam extends Equatable {
  final String? name;
  final List<String> params;

  const OpenrestyParam({
    this.name,
    this.params = const [],
  });

  factory OpenrestyParam.fromJson(Map<String, dynamic> json) {
    return OpenrestyParam(
      name: json['name'] as String?,
      params: (json['params'] as List?)?.whereType<String>().toList() ?? const [],
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

enum NginxKey {
  indexKey('index'),
  limitConn('limit-conn'),
  ssl('ssl'),
  cache('cache'),
  httpPer('http-per'),
  proxyCache('proxy-cache');

  const NginxKey(this.value);

  final String value;

  static NginxKey fromString(String value) {
    return NginxKey.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NginxKey.indexKey,
    );
  }
}

class OpenrestyBuildRequest extends Equatable {
  final String mirror;
  final String taskId;

  const OpenrestyBuildRequest({
    required this.mirror,
    required this.taskId,
  });

  factory OpenrestyBuildRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyBuildRequest(
      mirror: json['mirror'] as String,
      taskId: json['taskID'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mirror': mirror,
      'taskID': taskId,
    };
  }

  @override
  List<Object?> get props => [mirror, taskId];
}

class OpenrestyConfigFileUpdateRequest extends Equatable {
  final String content;
  final bool? backup;

  const OpenrestyConfigFileUpdateRequest({
    required this.content,
    this.backup,
  });

  factory OpenrestyConfigFileUpdateRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyConfigFileUpdateRequest(
      content: json['content'] as String,
      backup: json['backup'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (backup != null) 'backup': backup,
    };
  }

  @override
  List<Object?> get props => [content, backup];
}

enum OpenrestyDefaultHttpsOperate {
  enable('enable'),
  disable('disable');

  const OpenrestyDefaultHttpsOperate(this.value);

  final String value;
}

class OpenrestyDefaultHttpsUpdateRequest extends Equatable {
  final OpenrestyDefaultHttpsOperate operate;
  final bool? sslRejectHandshake;

  const OpenrestyDefaultHttpsUpdateRequest({
    required this.operate,
    this.sslRejectHandshake,
  });

  factory OpenrestyDefaultHttpsUpdateRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyDefaultHttpsUpdateRequest(
      operate: OpenrestyDefaultHttpsOperate.values.firstWhere(
        (e) => e.value == json['operate'],
        orElse: () => OpenrestyDefaultHttpsOperate.enable,
      ),
      sslRejectHandshake: json['sslRejectHandshake'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operate': operate.value,
      if (sslRejectHandshake != null) 'sslRejectHandshake': sslRejectHandshake,
    };
  }

  @override
  List<Object?> get props => [operate, sslRejectHandshake];
}

enum OpenrestyModuleOperate {
  create('create'),
  delete('delete'),
  update('update');

  const OpenrestyModuleOperate(this.value);

  final String value;
}

class OpenrestyModuleUpdateRequest extends Equatable {
  final String name;
  final OpenrestyModuleOperate operate;
  final bool? enable;
  final String? packages;
  final String? params;
  final String? script;

  const OpenrestyModuleUpdateRequest({
    required this.name,
    required this.operate,
    this.enable,
    this.packages,
    this.params,
    this.script,
  });

  factory OpenrestyModuleUpdateRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyModuleUpdateRequest(
      name: json['name'] as String,
      operate: OpenrestyModuleOperate.values.firstWhere(
        (e) => e.value == json['operate'],
        orElse: () => OpenrestyModuleOperate.update,
      ),
      enable: json['enable'] as bool?,
      packages: json['packages'] as String?,
      params: json['params'] as String?,
      script: json['script'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'operate': operate.value,
      if (enable != null) 'enable': enable,
      if (packages != null) 'packages': packages,
      if (params != null) 'params': params,
      if (script != null) 'script': script,
    };
  }

  @override
  List<Object?> get props => [name, operate, enable, packages, params, script];
}

class OpenrestyScopeRequest extends Equatable {
  final NginxKey scope;
  final int? websiteId;

  const OpenrestyScopeRequest({
    required this.scope,
    this.websiteId,
  });

  factory OpenrestyScopeRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyScopeRequest(
      scope: NginxKey.fromString(json['scope'] as String),
      websiteId: json['websiteId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scope': scope.value,
      if (websiteId != null) 'websiteId': websiteId,
    };
  }

  @override
  List<Object?> get props => [scope, websiteId];
}

enum OpenrestyConfigOperate {
  add('add'),
  update('update'),
  delete('delete');

  const OpenrestyConfigOperate(this.value);

  final String value;
}

class OpenrestyConfigUpdateRequest extends Equatable {
  final OpenrestyConfigOperate operate;
  final dynamic params;
  final NginxKey? scope;
  final int? websiteId;

  const OpenrestyConfigUpdateRequest({
    required this.operate,
    this.params,
    this.scope,
    this.websiteId,
  });

  factory OpenrestyConfigUpdateRequest.fromJson(Map<String, dynamic> json) {
    return OpenrestyConfigUpdateRequest(
      operate: OpenrestyConfigOperate.values.firstWhere(
        (e) => e.value == json['operate'],
        orElse: () => OpenrestyConfigOperate.update,
      ),
      params: json['params'],
      scope: json['scope'] is String ? NginxKey.fromString(json['scope'] as String) : null,
      websiteId: json['websiteId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operate': operate.value,
      if (params != null) 'params': params,
      if (scope != null) 'scope': scope!.value,
      if (websiteId != null) 'websiteId': websiteId,
    };
  }

  @override
  List<Object?> get props => [operate, params, scope, websiteId];
}

/// OpenResty configuration model
class OpenrestyConfig extends Equatable {
  final String? serverName;
  final int? listen;
  final bool? ssl;
  final int? sslListen;
  final String? certificate;
  final String? certificateKey;
  final String? root;
  final String? index;
  final List<String>? locations;
  final Map<String, dynamic>? upstreams;
  final bool? gzip;
  final Map<String, dynamic>? headers;

  const OpenrestyConfig({
    this.serverName,
    this.listen,
    this.ssl,
    this.sslListen,
    this.certificate,
    this.certificateKey,
    this.root,
    this.index,
    this.locations,
    this.upstreams,
    this.gzip,
    this.headers,
  });

  factory OpenrestyConfig.fromJson(Map<String, dynamic> json) {
    return OpenrestyConfig(
      serverName: json['serverName'] as String?,
      listen: json['listen'] as int?,
      ssl: json['ssl'] as bool?,
      sslListen: json['sslListen'] as int?,
      certificate: json['certificate'] as String?,
      certificateKey: json['certificateKey'] as String?,
      root: json['root'] as String?,
      index: json['index'] as String?,
      locations: (json['locations'] as List?)?.map((e) => e as String).toList(),
      upstreams: json['upstreams'] as Map<String, dynamic>?,
      gzip: json['gzip'] as bool?,
      headers: json['headers'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverName': serverName,
      'listen': listen,
      'ssl': ssl,
      'sslListen': sslListen,
      'certificate': certificate,
      'certificateKey': certificateKey,
      'root': root,
      'index': index,
      'locations': locations,
      'upstreams': upstreams,
      'gzip': gzip,
      'headers': headers,
    };
  }

  @override
  List<Object?> get props => [
        serverName,
        listen,
        ssl,
        sslListen,
        certificate,
        certificateKey,
        root,
        index,
        locations,
        upstreams,
        gzip,
        headers,
      ];
}

/// OpenResty operation request model
class OpenrestyOperation extends Equatable {
  final String operation;
  final Map<String, dynamic>? options;

  const OpenrestyOperation({
    required this.operation,
    this.options,
  });

  factory OpenrestyOperation.fromJson(Map<String, dynamic> json) {
    return OpenrestyOperation(
      operation: json['operation'] as String,
      options: json['options'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'options': options,
    };
  }

  @override
  List<Object?> get props => [operation, options];
}

/// OpenResty log search model
class OpenrestyLogSearch extends Equatable {
  final String? domain;
  final String? startTime;
  final String? endTime;
  final int? page;
  final int? pageSize;
  final String? keyword;

  const OpenrestyLogSearch({
    this.domain,
    this.startTime,
    this.endTime,
    this.page,
    this.pageSize,
    this.keyword,
  });

  factory OpenrestyLogSearch.fromJson(Map<String, dynamic> json) {
    return OpenrestyLogSearch(
      domain: json['domain'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      page: json['page'] as int?,
      pageSize: json['pageSize'] as int?,
      keyword: json['keyword'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'domain': domain,
      'startTime': startTime,
      'endTime': endTime,
      'page': page,
      'pageSize': pageSize,
      'keyword': keyword,
    };
  }

  @override
  List<Object?> get props => [domain, startTime, endTime, page, pageSize, keyword];
}

/// OpenResty error log model
class OpenrestyErrorLog extends Equatable {
  final String? time;
  final String? level;
  final String? message;
  final String? client;
  final String? server;
  final String? request;

  const OpenrestyErrorLog({
    this.time,
    this.level,
    this.message,
    this.client,
    this.server,
    this.request,
  });

  factory OpenrestyErrorLog.fromJson(Map<String, dynamic> json) {
    return OpenrestyErrorLog(
      time: json['time'] as String?,
      level: json['level'] as String?,
      message: json['message'] as String?,
      client: json['client'] as String?,
      server: json['server'] as String?,
      request: json['request'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'level': level,
      'message': message,
      'client': client,
      'server': server,
      'request': request,
    };
  }

  @override
  List<Object?> get props => [time, level, message, client, server, request];
}

/// OpenResty access log model
class OpenrestyAccessLog extends Equatable {
  final String? time;
  final String? remoteAddr;
  final String? request;
  final int? status;
  final int? bodyBytesSent;
  final String? httpReferer;
  final String? httpUserAgent;
  final double? requestTime;

  const OpenrestyAccessLog({
    this.time,
    this.remoteAddr,
    this.request,
    this.status,
    this.bodyBytesSent,
    this.httpReferer,
    this.httpUserAgent,
    this.requestTime,
  });

  factory OpenrestyAccessLog.fromJson(Map<String, dynamic> json) {
    return OpenrestyAccessLog(
      time: json['time'] as String?,
      remoteAddr: json['remoteAddr'] as String?,
      request: json['request'] as String?,
      status: json['status'] as int?,
      bodyBytesSent: json['bodyBytesSent'] as int?,
      httpReferer: json['httpReferer'] as String?,
      httpUserAgent: json['httpUserAgent'] as String?,
      requestTime: json['requestTime'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'remoteAddr': remoteAddr,
      'request': request,
      'status': status,
      'bodyBytesSent': bodyBytesSent,
      'httpReferer': httpReferer,
      'httpUserAgent': httpUserAgent,
      'requestTime': requestTime,
    };
  }

  @override
  List<Object?> get props => [
        time,
        remoteAddr,
        request,
        status,
        bodyBytesSent,
        httpReferer,
        httpUserAgent,
        requestTime,
      ];
}
