import 'package:equatable/equatable.dart';

class CronjobScheduleBuilder extends Equatable {
  const CronjobScheduleBuilder({
    this.mode = 'daily',
    this.minute = 0,
    this.hour = 0,
    this.dayOfWeek = 1,
    this.dayOfMonth = 1,
    this.interval = 1,
  });

  final String mode;
  final int minute;
  final int hour;
  final int dayOfWeek;
  final int dayOfMonth;
  final int interval;

  CronjobScheduleBuilder copyWith({
    String? mode,
    int? minute,
    int? hour,
    int? dayOfWeek,
    int? dayOfMonth,
    int? interval,
  }) {
    return CronjobScheduleBuilder(
      mode: mode ?? this.mode,
      minute: minute ?? this.minute,
      hour: hour ?? this.hour,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      interval: interval ?? this.interval,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        mode,
        minute,
        hour,
        dayOfWeek,
        dayOfMonth,
        interval,
      ];
}

class CronjobFormDraft extends Equatable {
  const CronjobFormDraft({
    this.id,
    this.name = '',
    this.groupID,
    this.primaryType = 'shell',
    this.backupType = 'website',
    this.useRawSpec = false,
    this.rawSpecs = const <String>['0 0 * * *'],
    this.schedule = const CronjobScheduleBuilder(),
    this.executor = 'bash',
    this.scriptMode = 'input',
    this.script = '',
    this.scriptID,
    this.user = 'root',
    this.urlItems = const <String>[''],
    this.appIdList = const <String>[],
    this.websiteList = const <String>[],
    this.dbType = 'mysql',
    this.dbNameList = const <String>[],
    this.ignoreFiles = const <String>[],
    this.isDir = true,
    this.sourceDir = '',
    this.files = const <String>[],
    this.withImage = false,
    this.ignoreAppIDs = const <int>[],
    this.scopes = const <String>[],
    this.sourceAccountItems = const <int>[],
    this.downloadAccountID,
    this.retainCopies = 1,
    this.retryTimes = 0,
    this.timeoutValue = 3600,
    this.timeoutUnit = 's',
    this.ignoreErr = false,
    this.secret = '',
    this.argItems = const <String>[],
    this.alertEnabled = false,
    this.alertCount = 3,
    this.alertMethods = const <String>[],
  });

  final int? id;
  final String name;
  final int? groupID;
  final String primaryType;
  final String backupType;
  final bool useRawSpec;
  final List<String> rawSpecs;
  final CronjobScheduleBuilder schedule;
  final String executor;
  final String scriptMode;
  final String script;
  final int? scriptID;
  final String user;
  final List<String> urlItems;
  final List<String> appIdList;
  final List<String> websiteList;
  final String dbType;
  final List<String> dbNameList;
  final List<String> ignoreFiles;
  final bool isDir;
  final String sourceDir;
  final List<String> files;
  final bool withImage;
  final List<int> ignoreAppIDs;
  final List<String> scopes;
  final List<int> sourceAccountItems;
  final int? downloadAccountID;
  final int retainCopies;
  final int retryTimes;
  final int timeoutValue;
  final String timeoutUnit;
  final bool ignoreErr;
  final String secret;
  final List<String> argItems;
  final bool alertEnabled;
  final int alertCount;
  final List<String> alertMethods;

  bool get isEditing => id != null;
  String get resolvedType => primaryType == 'backup' ? backupType : primaryType;

  CronjobFormDraft copyWith({
    int? id,
    String? name,
    int? groupID,
    String? primaryType,
    String? backupType,
    bool? useRawSpec,
    List<String>? rawSpecs,
    CronjobScheduleBuilder? schedule,
    String? executor,
    String? scriptMode,
    String? script,
    int? scriptID,
    String? user,
    List<String>? urlItems,
    List<String>? appIdList,
    List<String>? websiteList,
    String? dbType,
    List<String>? dbNameList,
    List<String>? ignoreFiles,
    bool? isDir,
    String? sourceDir,
    List<String>? files,
    bool? withImage,
    List<int>? ignoreAppIDs,
    List<String>? scopes,
    List<int>? sourceAccountItems,
    int? downloadAccountID,
    bool clearDownloadAccount = false,
    int? retainCopies,
    int? retryTimes,
    int? timeoutValue,
    String? timeoutUnit,
    bool? ignoreErr,
    String? secret,
    List<String>? argItems,
    bool? alertEnabled,
    int? alertCount,
    List<String>? alertMethods,
  }) {
    return CronjobFormDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      groupID: groupID ?? this.groupID,
      primaryType: primaryType ?? this.primaryType,
      backupType: backupType ?? this.backupType,
      useRawSpec: useRawSpec ?? this.useRawSpec,
      rawSpecs: rawSpecs ?? this.rawSpecs,
      schedule: schedule ?? this.schedule,
      executor: executor ?? this.executor,
      scriptMode: scriptMode ?? this.scriptMode,
      script: script ?? this.script,
      scriptID: scriptID ?? this.scriptID,
      user: user ?? this.user,
      urlItems: urlItems ?? this.urlItems,
      appIdList: appIdList ?? this.appIdList,
      websiteList: websiteList ?? this.websiteList,
      dbType: dbType ?? this.dbType,
      dbNameList: dbNameList ?? this.dbNameList,
      ignoreFiles: ignoreFiles ?? this.ignoreFiles,
      isDir: isDir ?? this.isDir,
      sourceDir: sourceDir ?? this.sourceDir,
      files: files ?? this.files,
      withImage: withImage ?? this.withImage,
      ignoreAppIDs: ignoreAppIDs ?? this.ignoreAppIDs,
      scopes: scopes ?? this.scopes,
      sourceAccountItems: sourceAccountItems ?? this.sourceAccountItems,
      downloadAccountID: clearDownloadAccount
          ? null
          : downloadAccountID ?? this.downloadAccountID,
      retainCopies: retainCopies ?? this.retainCopies,
      retryTimes: retryTimes ?? this.retryTimes,
      timeoutValue: timeoutValue ?? this.timeoutValue,
      timeoutUnit: timeoutUnit ?? this.timeoutUnit,
      ignoreErr: ignoreErr ?? this.ignoreErr,
      secret: secret ?? this.secret,
      argItems: argItems ?? this.argItems,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertCount: alertCount ?? this.alertCount,
      alertMethods: alertMethods ?? this.alertMethods,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        groupID,
        primaryType,
        backupType,
        useRawSpec,
        rawSpecs,
        schedule,
        executor,
        scriptMode,
        script,
        scriptID,
        user,
        urlItems,
        appIdList,
        websiteList,
        dbType,
        dbNameList,
        ignoreFiles,
        isDir,
        sourceDir,
        files,
        withImage,
        ignoreAppIDs,
        scopes,
        sourceAccountItems,
        downloadAccountID,
        retainCopies,
        retryTimes,
        timeoutValue,
        timeoutUnit,
        ignoreErr,
        secret,
        argItems,
        alertEnabled,
        alertCount,
        alertMethods,
      ];
}
