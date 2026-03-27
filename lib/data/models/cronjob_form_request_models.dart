import 'package:equatable/equatable.dart';

class CronjobSnapshotRule extends Equatable {
  const CronjobSnapshotRule({
    this.withImage = false,
    this.ignoreAppIDs = const <int>[],
  });

  final bool withImage;
  final List<int> ignoreAppIDs;

  factory CronjobSnapshotRule.fromJson(Map<String, dynamic> json) {
    return CronjobSnapshotRule(
      withImage: json['withImage'] as bool? ?? false,
      ignoreAppIDs:
          (json['ignoreAppIDs'] as List<dynamic>? ?? const <dynamic>[])
              .map((dynamic item) => item as int)
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'withImage': withImage,
        'ignoreAppIDs': ignoreAppIDs,
      };

  @override
  List<Object?> get props => <Object?>[withImage, ignoreAppIDs];
}

class CronjobOperateRequest extends Equatable {
  const CronjobOperateRequest({
    this.id,
    required this.name,
    required this.groupID,
    required this.type,
    required this.specCustom,
    required this.spec,
    this.executor = '',
    this.scriptMode = 'input',
    this.script = '',
    this.command = '',
    this.containerName = '',
    this.user = '',
    this.scriptID,
    this.appID = '',
    this.website = '',
    this.exclusionRules = '',
    this.dbType = '',
    this.dbName = '',
    this.url = '',
    this.isDir = false,
    this.sourceDir = '',
    this.snapshotRule = const CronjobSnapshotRule(),
    this.sourceAccountIDs = '',
    this.downloadAccountID,
    this.retainCopies = 1,
    this.retryTimes = 0,
    this.timeout = 3600,
    this.ignoreErr = false,
    this.secret = '',
    this.args = '',
    this.alertCount = 0,
    this.alertTitle = '',
    this.alertMethod = '',
    this.scopes = const <String>[],
  });

  final int? id;
  final String name;
  final int groupID;
  final String type;
  final bool specCustom;
  final String spec;
  final String executor;
  final String scriptMode;
  final String script;
  final String command;
  final String containerName;
  final String user;
  final int? scriptID;
  final String appID;
  final String website;
  final String exclusionRules;
  final String dbType;
  final String dbName;
  final String url;
  final bool isDir;
  final String sourceDir;
  final CronjobSnapshotRule snapshotRule;
  final String sourceAccountIDs;
  final int? downloadAccountID;
  final int retainCopies;
  final int retryTimes;
  final int timeout;
  final bool ignoreErr;
  final String secret;
  final String args;
  final int alertCount;
  final String alertTitle;
  final String alertMethod;
  final List<String> scopes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'name': name,
        'groupID': groupID,
        'type': type,
        'specCustom': specCustom,
        'spec': spec,
        'executor': executor,
        'scriptMode': scriptMode,
        'script': script,
        'command': command,
        'containerName': containerName,
        'user': user,
        'scriptID': scriptID ?? 0,
        'appID': appID,
        'website': website,
        'exclusionRules': exclusionRules,
        'dbType': dbType,
        'dbName': dbName,
        'url': url,
        'isDir': isDir,
        'sourceDir': sourceDir,
        'snapshotRule': snapshotRule.toJson(),
        'sourceAccountIDs': sourceAccountIDs,
        'downloadAccountID': downloadAccountID ?? 0,
        'retainCopies': retainCopies,
        'retryTimes': retryTimes,
        'timeout': timeout,
        'ignoreErr': ignoreErr,
        'secret': secret,
        'args': args,
        'alertCount': alertCount,
        'alertTitle': alertTitle,
        'alertMethod': alertMethod,
        'scopes': scopes,
      };

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        groupID,
        type,
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
        sourceAccountIDs,
        downloadAccountID,
        retainCopies,
        retryTimes,
        timeout,
        ignoreErr,
        secret,
        args,
        alertCount,
        alertTitle,
        alertMethod,
        scopes,
      ];
}

class CronjobBatchDeleteRequest extends Equatable {
  const CronjobBatchDeleteRequest({
    required this.ids,
    this.cleanData = false,
    this.cleanRemoteData = false,
  });

  final List<int> ids;
  final bool cleanData;
  final bool cleanRemoteData;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ids': ids,
        'cleanData': cleanData,
        'cleanRemoteData': cleanRemoteData,
      };

  @override
  List<Object?> get props => <Object?>[ids, cleanData, cleanRemoteData];
}

class CronjobNextPreviewRequest extends Equatable {
  const CronjobNextPreviewRequest({required this.spec});

  final String spec;

  Map<String, dynamic> toJson() => <String, dynamic>{'spec': spec};

  @override
  List<Object?> get props => <Object?>[spec];
}

class CronjobTransHelper extends Equatable {
  const CronjobTransHelper({
    required this.name,
    this.detailName = '',
  });

  final String name;
  final String detailName;

  factory CronjobTransHelper.fromJson(Map<String, dynamic> json) {
    return CronjobTransHelper(
      name: json['name'] as String? ?? '',
      detailName: json['detailName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'detailName': detailName,
      };

  @override
  List<Object?> get props => <Object?>[name, detailName];
}

class CronjobSnapshotTransHelper extends Equatable {
  const CronjobSnapshotTransHelper({
    this.withImage = false,
    this.ignoreApps = const <CronjobTransHelper>[],
  });

  final bool withImage;
  final List<CronjobTransHelper> ignoreApps;

  factory CronjobSnapshotTransHelper.fromJson(Map<String, dynamic> json) {
    return CronjobSnapshotTransHelper(
      withImage: json['withImage'] as bool? ?? false,
      ignoreApps: (json['ignoreApps'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(CronjobTransHelper.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'withImage': withImage,
        'ignoreApps': ignoreApps.map((item) => item.toJson()).toList(),
      };

  @override
  List<Object?> get props => <Object?>[withImage, ignoreApps];
}
