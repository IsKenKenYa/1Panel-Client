import 'package:equatable/equatable.dart';

import 'cronjob_form_request_models.dart';

class CronjobOperateResponse extends Equatable {
  const CronjobOperateResponse({
    this.id,
    this.name = '',
    this.type = '',
    this.groupID = 0,
    this.specCustom = false,
    this.spec = '',
    this.executor = '',
    this.scriptMode = 'input',
    this.script = '',
    this.command = '',
    this.containerName = '',
    this.user = '',
    this.scriptID = 0,
    this.appID = '',
    this.website = '',
    this.exclusionRules = '',
    this.dbType = '',
    this.dbName = '',
    this.url = '',
    this.isDir = false,
    this.sourceDir = '',
    this.snapshotRule = const CronjobSnapshotRule(),
    this.sourceAccounts = const <String>[],
    this.downloadAccount = '',
    this.sourceAccountIDs = '',
    this.downloadAccountID = 0,
    this.retainCopies = 1,
    this.retryTimes = 0,
    this.timeout = 3600,
    this.ignoreErr = false,
    this.status = '',
    this.secret = '',
    this.args = '',
    this.alertCount = 0,
    this.alertTitle = '',
    this.alertMethod = '',
    this.scopes = const <String>[],
  });

  final int? id;
  final String name;
  final String type;
  final int groupID;
  final bool specCustom;
  final String spec;
  final String executor;
  final String scriptMode;
  final String script;
  final String command;
  final String containerName;
  final String user;
  final int scriptID;
  final String appID;
  final String website;
  final String exclusionRules;
  final String dbType;
  final String dbName;
  final String url;
  final bool isDir;
  final String sourceDir;
  final CronjobSnapshotRule snapshotRule;
  final List<String> sourceAccounts;
  final String downloadAccount;
  final String sourceAccountIDs;
  final int downloadAccountID;
  final int retainCopies;
  final int retryTimes;
  final int timeout;
  final bool ignoreErr;
  final String status;
  final String secret;
  final String args;
  final int alertCount;
  final String alertTitle;
  final String alertMethod;
  final List<String> scopes;

  factory CronjobOperateResponse.fromJson(Map<String, dynamic> json) {
    return CronjobOperateResponse(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      groupID: json['groupID'] as int? ?? 0,
      specCustom: json['specCustom'] as bool? ?? false,
      spec: json['spec'] as String? ?? '',
      executor: json['executor'] as String? ?? '',
      scriptMode: json['scriptMode'] as String? ?? 'input',
      script: json['script'] as String? ?? '',
      command: json['command'] as String? ?? '',
      containerName: json['containerName'] as String? ?? '',
      user: json['user'] as String? ?? '',
      scriptID: json['scriptID'] as int? ?? 0,
      appID: json['appID'] as String? ?? '',
      website: json['website'] as String? ?? '',
      exclusionRules: json['exclusionRules'] as String? ?? '',
      dbType: json['dbType'] as String? ?? '',
      dbName: json['dbName'] as String? ?? '',
      url: json['url'] as String? ?? '',
      isDir: json['isDir'] as bool? ?? false,
      sourceDir: json['sourceDir'] as String? ?? '',
      snapshotRule: CronjobSnapshotRule.fromJson(
        json['snapshotRule'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      sourceAccounts:
          (json['sourceAccounts'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(growable: false),
      downloadAccount: json['downloadAccount'] as String? ?? '',
      sourceAccountIDs: json['sourceAccountIDs'] as String? ?? '',
      downloadAccountID: json['downloadAccountID'] as int? ?? 0,
      retainCopies: json['retainCopies'] as int? ?? 1,
      retryTimes: json['retryTimes'] as int? ?? 0,
      timeout: json['timeout'] as int? ?? 3600,
      ignoreErr: json['ignoreErr'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      secret: json['secret'] as String? ?? '',
      args: json['args'] as String? ?? '',
      alertCount: json['alertCount'] as int? ?? 0,
      alertTitle: json['alertTitle'] as String? ?? '',
      alertMethod: json['alertMethod'] as String? ?? '',
      scopes: (json['scopes'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        groupID,
        specCustom,
        spec,
        executor,
        scriptMode,
        script,
        command,
        containerName,
        user,
        scriptID,
        appID,
        website,
        exclusionRules,
        dbType,
        dbName,
        url,
        isDir,
        sourceDir,
        snapshotRule,
        sourceAccounts,
        downloadAccount,
        sourceAccountIDs,
        downloadAccountID,
        retainCopies,
        retryTimes,
        timeout,
        ignoreErr,
        status,
        secret,
        args,
        alertCount,
        alertTitle,
        alertMethod,
        scopes,
      ];
}

class CronjobTransItem extends Equatable {
  const CronjobTransItem({
    required this.name,
    required this.type,
    required this.groupID,
    required this.specCustom,
    required this.spec,
    this.executor = '',
    this.scriptMode = '',
    this.script = '',
    this.command = '',
    this.containerName = '',
    this.user = '',
    this.url = '',
    this.scriptName = '',
    this.apps = const <CronjobTransHelper>[],
    this.websites = const <String>[],
    this.dbType = '',
    this.dbName = const <CronjobTransHelper>[],
    this.exclusionRules = '',
    this.isDir = false,
    this.sourceDir = '',
    this.retainCopies = 1,
    this.retryTimes = 0,
    this.timeout = 3600,
    this.ignoreErr = false,
    this.snapshotRule = const CronjobSnapshotTransHelper(),
    this.secret = '',
    this.args = '',
    this.sourceAccounts = const <String>[],
    this.downloadAccount = '',
    this.alertCount = 0,
    this.alertTitle = '',
    this.alertMethod = '',
  });

  final String name;
  final String type;
  final int groupID;
  final bool specCustom;
  final String spec;
  final String executor;
  final String scriptMode;
  final String script;
  final String command;
  final String containerName;
  final String user;
  final String url;
  final String scriptName;
  final List<CronjobTransHelper> apps;
  final List<String> websites;
  final String dbType;
  final List<CronjobTransHelper> dbName;
  final String exclusionRules;
  final bool isDir;
  final String sourceDir;
  final int retainCopies;
  final int retryTimes;
  final int timeout;
  final bool ignoreErr;
  final CronjobSnapshotTransHelper snapshotRule;
  final String secret;
  final String args;
  final List<String> sourceAccounts;
  final String downloadAccount;
  final int alertCount;
  final String alertTitle;
  final String alertMethod;

  factory CronjobTransItem.fromJson(Map<String, dynamic> json) {
    return CronjobTransItem(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      groupID: json['groupID'] as int? ?? 0,
      specCustom: json['specCustom'] as bool? ?? false,
      spec: json['spec'] as String? ?? '',
      executor: json['executor'] as String? ?? '',
      scriptMode: json['scriptMode'] as String? ?? '',
      script: json['script'] as String? ?? '',
      command: json['command'] as String? ?? '',
      containerName: json['containerName'] as String? ?? '',
      user: json['user'] as String? ?? '',
      url: json['url'] as String? ?? '',
      scriptName: json['scriptName'] as String? ?? '',
      apps: (json['apps'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CronjobTransHelper.fromJson)
          .toList(growable: false),
      websites: (json['websites'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(growable: false),
      dbType: json['dbType'] as String? ?? '',
      dbName: (json['dbName'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CronjobTransHelper.fromJson)
          .toList(growable: false),
      exclusionRules: json['exclusionRules'] as String? ?? '',
      isDir: json['isDir'] as bool? ?? false,
      sourceDir: json['sourceDir'] as String? ?? '',
      retainCopies: (json['retainCopies'] as num?)?.toInt() ?? 1,
      retryTimes: json['retryTimes'] as int? ?? 0,
      timeout: json['timeout'] as int? ?? 3600,
      ignoreErr: json['ignoreErr'] as bool? ?? false,
      snapshotRule: CronjobSnapshotTransHelper.fromJson(
        json['snapshotRule'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      secret: json['secret'] as String? ?? '',
      args: json['args'] as String? ?? '',
      sourceAccounts:
          (json['sourceAccounts'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item.toString())
              .toList(growable: false),
      downloadAccount: json['downloadAccount'] as String? ?? '',
      alertCount: json['alertCount'] as int? ?? 0,
      alertTitle: json['alertTitle'] as String? ?? '',
      alertMethod: json['alertMethod'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'type': type,
        'groupID': groupID,
        'specCustom': specCustom,
        'spec': spec,
        'executor': executor,
        'scriptMode': scriptMode,
        'script': script,
        'command': command,
        'containerName': containerName,
        'user': user,
        'url': url,
        'scriptName': scriptName,
        'apps': apps.map((item) => item.toJson()).toList(),
        'websites': websites,
        'dbType': dbType,
        'dbName': dbName.map((item) => item.toJson()).toList(),
        'exclusionRules': exclusionRules,
        'isDir': isDir,
        'sourceDir': sourceDir,
        'retainCopies': retainCopies,
        'retryTimes': retryTimes,
        'timeout': timeout,
        'ignoreErr': ignoreErr,
        'snapshotRule': snapshotRule.toJson(),
        'secret': secret,
        'args': args,
        'sourceAccounts': sourceAccounts,
        'downloadAccount': downloadAccount,
        'alertCount': alertCount,
        'alertTitle': alertTitle,
        'alertMethod': alertMethod,
      };

  @override
  List<Object?> get props => <Object?>[
        name,
        type,
        groupID,
        specCustom,
        spec,
        executor,
        scriptMode,
        script,
        command,
        containerName,
        user,
        url,
        scriptName,
        apps,
        websites,
        dbType,
        dbName,
        exclusionRules,
        isDir,
        sourceDir,
        retainCopies,
        retryTimes,
        timeout,
        ignoreErr,
        snapshotRule,
        secret,
        args,
        sourceAccounts,
        downloadAccount,
        alertCount,
        alertTitle,
        alertMethod,
      ];
}

class CronjobImportRequest extends Equatable {
  const CronjobImportRequest({required this.cronjobs});

  final List<CronjobTransItem> cronjobs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cronjobs': cronjobs.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[cronjobs];
}

class CronjobExportRequest extends Equatable {
  const CronjobExportRequest({required this.ids});

  final List<int> ids;

  Map<String, dynamic> toJson() => <String, dynamic>{'ids': ids};

  @override
  List<Object?> get props => <Object?>[ids];
}
