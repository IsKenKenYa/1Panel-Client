// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SystemSettings _$SystemSettingsFromJson(Map<String, dynamic> json) =>
    SystemSettings(
      siteName: json['siteName'] as String?,
      language: json['language'] as String?,
      theme: json['theme'] as String?,
      timeZone: json['timeZone'] as String?,
      sessionTimeout: json['sessionTimeout'] as String?,
      defaultPassword: json['defaultPassword'] as String?,
      allowAccessKey: json['allowAccessKey'] as bool?,
      complexity: json['complexity'] as String?,
      minPasswordLength: (json['minPasswordLength'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SystemSettingsToJson(SystemSettings instance) =>
    <String, dynamic>{
      'siteName': instance.siteName,
      'language': instance.language,
      'theme': instance.theme,
      'timeZone': instance.timeZone,
      'sessionTimeout': instance.sessionTimeout,
      'defaultPassword': instance.defaultPassword,
      'allowAccessKey': instance.allowAccessKey,
      'complexity': instance.complexity,
      'minPasswordLength': instance.minPasswordLength,
    };

SystemInfo _$SystemInfoFromJson(Map<String, dynamic> json) => SystemInfo(
      version: json['version'] as String?,
      build: json['build'] as String?,
      arch: json['arch'] as String?,
      os: json['os'] as String?,
      goVersion: json['goVersion'] as String?,
      dockerVersion: json['dockerVersion'] as String?,
      uptime: json['uptime'] as String?,
      totalMemory: (json['totalMemory'] as num?)?.toInt(),
      usedMemory: (json['usedMemory'] as num?)?.toInt(),
      totalDisk: (json['totalDisk'] as num?)?.toInt(),
      usedDisk: (json['usedDisk'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SystemInfoToJson(SystemInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'build': instance.build,
      'arch': instance.arch,
      'os': instance.os,
      'goVersion': instance.goVersion,
      'dockerVersion': instance.dockerVersion,
      'uptime': instance.uptime,
      'totalMemory': instance.totalMemory,
      'usedMemory': instance.usedMemory,
      'totalDisk': instance.totalDisk,
      'usedDisk': instance.usedDisk,
    };

SystemTime _$SystemTimeFromJson(Map<String, dynamic> json) => SystemTime(
      time: json['time'] as String?,
      timeZone: json['timeZone'] as String?,
    );

Map<String, dynamic> _$SystemTimeToJson(SystemTime instance) =>
    <String, dynamic>{
      'time': instance.time,
      'timeZone': instance.timeZone,
    };

SystemTimeSet _$SystemTimeSetFromJson(Map<String, dynamic> json) =>
    SystemTimeSet(
      time: json['time'] as String?,
      timeZone: json['timeZone'] as String?,
    );

Map<String, dynamic> _$SystemTimeSetToJson(SystemTimeSet instance) =>
    <String, dynamic>{
      'time': instance.time,
      'timeZone': instance.timeZone,
    };

SecuritySettings _$SecuritySettingsFromJson(Map<String, dynamic> json) =>
    SecuritySettings(
      allowIPs: json['allowIPs'] as bool?,
      allowedIPs: (json['allowedIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      authMethod: json['authMethod'] as String?,
      failedAttempts: (json['failedAttempts'] as num?)?.toInt(),
      lockTime: (json['lockTime'] as num?)?.toInt(),
      passwordPolicy: json['passwordPolicy'] as String?,
    );

Map<String, dynamic> _$SecuritySettingsToJson(SecuritySettings instance) =>
    <String, dynamic>{
      'allowIPs': instance.allowIPs,
      'allowedIPs': instance.allowedIPs,
      'authMethod': instance.authMethod,
      'failedAttempts': instance.failedAttempts,
      'lockTime': instance.lockTime,
      'passwordPolicy': instance.passwordPolicy,
    };

SecuritySettingsUpdate _$SecuritySettingsUpdateFromJson(
        Map<String, dynamic> json) =>
    SecuritySettingsUpdate(
      allowIPs: json['allowIPs'] as bool?,
      allowedIPs: (json['allowedIPs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      authMethod: json['authMethod'] as String?,
      failedAttempts: (json['failedAttempts'] as num?)?.toInt(),
      lockTime: (json['lockTime'] as num?)?.toInt(),
      passwordPolicy: json['passwordPolicy'] as String?,
    );

Map<String, dynamic> _$SecuritySettingsUpdateToJson(
        SecuritySettingsUpdate instance) =>
    <String, dynamic>{
      'allowIPs': instance.allowIPs,
      'allowedIPs': instance.allowedIPs,
      'authMethod': instance.authMethod,
      'failedAttempts': instance.failedAttempts,
      'lockTime': instance.lockTime,
      'passwordPolicy': instance.passwordPolicy,
    };

PanelSettings _$PanelSettingsFromJson(Map<String, dynamic> json) =>
    PanelSettings(
      title: json['title'] as String?,
      logo: json['logo'] as String?,
      theme: json['theme'] as String?,
      language: json['language'] as String?,
      serverName: json['serverName'] as String?,
      serverAddr: json['serverAddr'] as String?,
      port: json['port'] as String?,
      ssl: json['ssl'] as String?,
      ipv6: json['ipv6'] as String?,
      bind: json['bind'] as bool?,
    );

Map<String, dynamic> _$PanelSettingsToJson(PanelSettings instance) =>
    <String, dynamic>{
      'title': instance.title,
      'logo': instance.logo,
      'theme': instance.theme,
      'language': instance.language,
      'serverName': instance.serverName,
      'serverAddr': instance.serverAddr,
      'port': instance.port,
      'ssl': instance.ssl,
      'ipv6': instance.ipv6,
      'bind': instance.bind,
    };

PanelSettingsUpdate _$PanelSettingsUpdateFromJson(Map<String, dynamic> json) =>
    PanelSettingsUpdate(
      title: json['title'] as String?,
      logo: json['logo'] as String?,
      theme: json['theme'] as String?,
      language: json['language'] as String?,
      serverName: json['serverName'] as String?,
      serverAddr: json['serverAddr'] as String?,
      port: json['port'] as String?,
      ssl: json['ssl'] as String?,
      ipv6: json['ipv6'] as String?,
      bind: json['bind'] as bool?,
    );

Map<String, dynamic> _$PanelSettingsUpdateToJson(
        PanelSettingsUpdate instance) =>
    <String, dynamic>{
      'title': instance.title,
      'logo': instance.logo,
      'theme': instance.theme,
      'language': instance.language,
      'serverName': instance.serverName,
      'serverAddr': instance.serverAddr,
      'port': instance.port,
      'ssl': instance.ssl,
      'ipv6': instance.ipv6,
      'bind': instance.bind,
    };

UserSettings _$UserSettingsFromJson(Map<String, dynamic> json) => UserSettings(
      username: json['username'] as String?,
      email: json['email'] as String?,
      language: json['language'] as String?,
      theme: json['theme'] as String?,
      timeZone: json['timeZone'] as String?,
      failedLoginAttempts: (json['failedLoginAttempts'] as num?)?.toInt(),
      lockTime: (json['lockTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserSettingsToJson(UserSettings instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'language': instance.language,
      'theme': instance.theme,
      'timeZone': instance.timeZone,
      'failedLoginAttempts': instance.failedLoginAttempts,
      'lockTime': instance.lockTime,
    };

UserSettingsUpdate _$UserSettingsUpdateFromJson(Map<String, dynamic> json) =>
    UserSettingsUpdate(
      username: json['username'] as String?,
      email: json['email'] as String?,
      language: json['language'] as String?,
      theme: json['theme'] as String?,
      timeZone: json['timeZone'] as String?,
      failedLoginAttempts: (json['failedLoginAttempts'] as num?)?.toInt(),
      lockTime: (json['lockTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserSettingsUpdateToJson(UserSettingsUpdate instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'language': instance.language,
      'theme': instance.theme,
      'timeZone': instance.timeZone,
      'failedLoginAttempts': instance.failedLoginAttempts,
      'lockTime': instance.lockTime,
    };

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    NotificationSettings(
      emailEnabled: json['emailEnabled'] as bool?,
      emailServer: json['emailServer'] as String?,
      emailPort: json['emailPort'] as String?,
      emailUsername: json['emailUsername'] as String?,
      emailPassword: json['emailPassword'] as String?,
      emailFrom: json['emailFrom'] as String?,
      webhookEnabled: json['webhookEnabled'] as bool?,
      webhookUrl: json['webhookUrl'] as String?,
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'emailEnabled': instance.emailEnabled,
      'emailServer': instance.emailServer,
      'emailPort': instance.emailPort,
      'emailUsername': instance.emailUsername,
      'emailPassword': instance.emailPassword,
      'emailFrom': instance.emailFrom,
      'webhookEnabled': instance.webhookEnabled,
      'webhookUrl': instance.webhookUrl,
    };

NotificationSettingsUpdate _$NotificationSettingsUpdateFromJson(
        Map<String, dynamic> json) =>
    NotificationSettingsUpdate(
      emailEnabled: json['emailEnabled'] as bool?,
      emailServer: json['emailServer'] as String?,
      emailPort: json['emailPort'] as String?,
      emailUsername: json['emailUsername'] as String?,
      emailPassword: json['emailPassword'] as String?,
      emailFrom: json['emailFrom'] as String?,
      webhookEnabled: json['webhookEnabled'] as bool?,
      webhookUrl: json['webhookUrl'] as String?,
    );

Map<String, dynamic> _$NotificationSettingsUpdateToJson(
        NotificationSettingsUpdate instance) =>
    <String, dynamic>{
      'emailEnabled': instance.emailEnabled,
      'emailServer': instance.emailServer,
      'emailPort': instance.emailPort,
      'emailUsername': instance.emailUsername,
      'emailPassword': instance.emailPassword,
      'emailFrom': instance.emailFrom,
      'webhookEnabled': instance.webhookEnabled,
      'webhookUrl': instance.webhookUrl,
    };

BackupSettings _$BackupSettingsFromJson(Map<String, dynamic> json) =>
    BackupSettings(
      backupDir: json['backupDir'] as String?,
      backupType: json['backupType'] as String?,
      backupRetention: json['backupRetention'] as String?,
      backupEnabled: json['backupEnabled'] as bool?,
      backupSchedule: json['backupSchedule'] as String?,
    );

Map<String, dynamic> _$BackupSettingsToJson(BackupSettings instance) =>
    <String, dynamic>{
      'backupDir': instance.backupDir,
      'backupType': instance.backupType,
      'backupRetention': instance.backupRetention,
      'backupEnabled': instance.backupEnabled,
      'backupSchedule': instance.backupSchedule,
    };

BackupSettingsUpdate _$BackupSettingsUpdateFromJson(
        Map<String, dynamic> json) =>
    BackupSettingsUpdate(
      backupDir: json['backupDir'] as String?,
      backupType: json['backupType'] as String?,
      backupRetention: json['backupRetention'] as String?,
      backupEnabled: json['backupEnabled'] as bool?,
      backupSchedule: json['backupSchedule'] as String?,
    );

Map<String, dynamic> _$BackupSettingsUpdateToJson(
        BackupSettingsUpdate instance) =>
    <String, dynamic>{
      'backupDir': instance.backupDir,
      'backupType': instance.backupType,
      'backupRetention': instance.backupRetention,
      'backupEnabled': instance.backupEnabled,
      'backupSchedule': instance.backupSchedule,
    };

ThemeSettings _$ThemeSettingsFromJson(Map<String, dynamic> json) =>
    ThemeSettings(
      theme: json['theme'] as String?,
      primaryColor: json['primaryColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
    );

Map<String, dynamic> _$ThemeSettingsToJson(ThemeSettings instance) =>
    <String, dynamic>{
      'theme': instance.theme,
      'primaryColor': instance.primaryColor,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
    };

ThemeSettingsUpdate _$ThemeSettingsUpdateFromJson(Map<String, dynamic> json) =>
    ThemeSettingsUpdate(
      theme: json['theme'] as String?,
      primaryColor: json['primaryColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
      textColor: json['textColor'] as String?,
    );

Map<String, dynamic> _$ThemeSettingsUpdateToJson(
        ThemeSettingsUpdate instance) =>
    <String, dynamic>{
      'theme': instance.theme,
      'primaryColor': instance.primaryColor,
      'backgroundColor': instance.backgroundColor,
      'textColor': instance.textColor,
    };

LanguageSettings _$LanguageSettingsFromJson(Map<String, dynamic> json) =>
    LanguageSettings(
      language: json['language'] as String?,
      region: json['region'] as String?,
    );

Map<String, dynamic> _$LanguageSettingsToJson(LanguageSettings instance) =>
    <String, dynamic>{
      'language': instance.language,
      'region': instance.region,
    };

LanguageSet _$LanguageSetFromJson(Map<String, dynamic> json) => LanguageSet(
      language: json['language'] as String?,
      region: json['region'] as String?,
    );

Map<String, dynamic> _$LanguageSetToJson(LanguageSet instance) =>
    <String, dynamic>{
      'language': instance.language,
      'region': instance.region,
    };

NTPSync _$NTPSyncFromJson(Map<String, dynamic> json) => NTPSync(
      enabled: json['enabled'] as bool?,
      server: json['server'] as String?,
      interval: json['interval'] as String?,
      timezone: json['timezone'] as String?,
    );

Map<String, dynamic> _$NTPSyncToJson(NTPSync instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'server': instance.server,
      'interval': instance.interval,
      'timezone': instance.timezone,
    };

TimezoneInfo _$TimezoneInfoFromJson(Map<String, dynamic> json) => TimezoneInfo(
      zone: json['zone'] as String?,
      offset: json['offset'] as String?,
    );

Map<String, dynamic> _$TimezoneInfoToJson(TimezoneInfo instance) =>
    <String, dynamic>{
      'zone': instance.zone,
      'offset': instance.offset,
    };

LanguageInfo _$LanguageInfoFromJson(Map<String, dynamic> json) => LanguageInfo(
      code: json['code'] as String?,
      name: json['name'] as String?,
      nativeName: json['nativeName'] as String?,
    );

Map<String, dynamic> _$LanguageInfoToJson(LanguageInfo instance) =>
    <String, dynamic>{
      'code': instance.code,
      'name': instance.name,
      'nativeName': instance.nativeName,
    };

ThemeInfo _$ThemeInfoFromJson(Map<String, dynamic> json) => ThemeInfo(
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      primaryColor: json['primaryColor'] as String?,
      backgroundColor: json['backgroundColor'] as String?,
    );

Map<String, dynamic> _$ThemeInfoToJson(ThemeInfo instance) => <String, dynamic>{
      'name': instance.name,
      'displayName': instance.displayName,
      'primaryColor': instance.primaryColor,
      'backgroundColor': instance.backgroundColor,
    };

SettingsExport _$SettingsExportFromJson(Map<String, dynamic> json) =>
    SettingsExport(
      data: json['data'] as String?,
      timestamp: json['timestamp'] as String?,
      version: json['version'] as String?,
    );

Map<String, dynamic> _$SettingsExportToJson(SettingsExport instance) =>
    <String, dynamic>{
      'data': instance.data,
      'timestamp': instance.timestamp,
      'version': instance.version,
    };

SettingsImport _$SettingsImportFromJson(Map<String, dynamic> json) =>
    SettingsImport(
      data: json['data'] as String?,
      overwrite: json['overwrite'] as bool?,
    );

Map<String, dynamic> _$SettingsImportToJson(SettingsImport instance) =>
    <String, dynamic>{
      'data': instance.data,
      'overwrite': instance.overwrite,
    };

MfaCredential _$MfaCredentialFromJson(Map<String, dynamic> json) =>
    MfaCredential(
      code: json['code'] as String,
      interval: (json['interval'] as num?)?.toInt() ?? 30,
      secret: json['secret'] as String,
    );

Map<String, dynamic> _$MfaCredentialToJson(MfaCredential instance) =>
    <String, dynamic>{
      'code': instance.code,
      'interval': instance.interval,
      'secret': instance.secret,
    };

MfaLoadRequest _$MfaLoadRequestFromJson(Map<String, dynamic> json) =>
    MfaLoadRequest(
      title: json['title'] as String,
      interval: (json['interval'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$MfaLoadRequestToJson(MfaLoadRequest instance) =>
    <String, dynamic>{
      'title': instance.title,
      'interval': instance.interval,
    };

MfaOtp _$MfaOtpFromJson(Map<String, dynamic> json) => MfaOtp(
      qrImage: json['qrImage'] as String?,
      secret: json['secret'] as String?,
    );

Map<String, dynamic> _$MfaOtpToJson(MfaOtp instance) => <String, dynamic>{
      'qrImage': instance.qrImage,
      'secret': instance.secret,
    };

MfaBindRequest _$MfaBindRequestFromJson(Map<String, dynamic> json) =>
    MfaBindRequest(
      code: json['code'] as String,
      interval: json['interval'] as String? ?? '30',
      secret: json['secret'] as String,
    );

Map<String, dynamic> _$MfaBindRequestToJson(MfaBindRequest instance) =>
    <String, dynamic>{
      'code': instance.code,
      'interval': instance.interval,
      'secret': instance.secret,
    };

MfaStatus _$MfaStatusFromJson(Map<String, dynamic> json) => MfaStatus(
      enabled: json['enabled'] as bool,
      secret: json['secret'] as String?,
    );

Map<String, dynamic> _$MfaStatusToJson(MfaStatus instance) => <String, dynamic>{
      'enabled': instance.enabled,
      'secret': instance.secret,
    };

TerminalInfo _$TerminalInfoFromJson(Map<String, dynamic> json) => TerminalInfo(
      cursorBlink: json['cursorBlink'] as String?,
      cursorStyle: json['cursorStyle'] as String?,
      fontSize: json['fontSize'] as String?,
      letterSpacing: json['letterSpacing'] as String?,
      lineHeight: json['lineHeight'] as String?,
      scrollSensitivity: json['scrollSensitivity'] as String?,
      scrollback: json['scrollback'] as String?,
    );

Map<String, dynamic> _$TerminalInfoToJson(TerminalInfo instance) =>
    <String, dynamic>{
      'cursorBlink': instance.cursorBlink,
      'cursorStyle': instance.cursorStyle,
      'fontSize': instance.fontSize,
      'letterSpacing': instance.letterSpacing,
      'lineHeight': instance.lineHeight,
      'scrollSensitivity': instance.scrollSensitivity,
      'scrollback': instance.scrollback,
    };

InterfaceInfo _$InterfaceInfoFromJson(Map<String, dynamic> json) =>
    InterfaceInfo(
      theme: json['theme'] as String?,
      language: json['language'] as String?,
      menuCollapse: json['menuCollapse'] as String?,
      entry: json['entry'] as String?,
    );

Map<String, dynamic> _$InterfaceInfoToJson(InterfaceInfo instance) =>
    <String, dynamic>{
      'theme': instance.theme,
      'language': instance.language,
      'menuCollapse': instance.menuCollapse,
      'entry': instance.entry,
    };

SystemSettingInfo _$SystemSettingInfoFromJson(Map<String, dynamic> json) =>
    SystemSettingInfo(
      userName: json['userName'] as String?,
      systemVersion: json['systemVersion'] as String?,
      developerMode: json['developerMode'] as String?,
      upgradeBackupCopies: json['upgradeBackupCopies'] as String?,
      sessionTimeout: json['sessionTimeout'] as String?,
      port: json['port'] as String?,
      ipv6: json['ipv6'] as String?,
      bindAddress: json['bindAddress'] as String?,
      panelName: json['panelName'] as String?,
      theme: json['theme'] as String?,
      menuTabs: json['menuTabs'] as String?,
      language: json['language'] as String?,
      serverPort: json['serverPort'] as String?,
      ssl: json['ssl'] as String?,
      sslType: json['sslType'] as String?,
      bindDomain: json['bindDomain'] as String?,
      allowIPs: json['allowIPs'] as String?,
      securityEntrance: json['securityEntrance'] as String?,
      dashboardMemoVisible: json['dashboardMemoVisible'] as String?,
      dashboardSimpleNodeVisible: json['dashboardSimpleNodeVisible'] as String?,
      expirationDays: json['expirationDays'] as String?,
      expirationTime: json['expirationTime'] as String?,
      complexityVerification: json['complexityVerification'] as String?,
      mfaStatus: json['mfaStatus'] as String?,
      mfaSecret: json['mfaSecret'] as String?,
      mfaInterval: json['mfaInterval'] as String?,
      appStoreVersion: json['appStoreVersion'] as String?,
      appStoreLastModified: json['appStoreLastModified'] as String?,
      appStoreSyncStatus: json['appStoreSyncStatus'] as String?,
      hideMenu: json['hideMenu'] as String?,
      noAuthSetting: json['noAuthSetting'] as String?,
      proxyUrl: json['proxyUrl'] as String?,
      proxyType: json['proxyType'] as String?,
      proxyPort: json['proxyPort'] as String?,
      proxyUser: json['proxyUser'] as String?,
      proxyPasswd: json['proxyPasswd'] as String?,
      proxyPasswdKeep: json['proxyPasswdKeep'] as String?,
      apiInterfaceStatus: json['apiInterfaceStatus'] as String?,
      apiKey: json['apiKey'] as String?,
      ipWhiteList: json['ipWhiteList'] as String?,
      apiKeyValidityTime: json['apiKeyValidityTime'] as String?,
    );

Map<String, dynamic> _$SystemSettingInfoToJson(SystemSettingInfo instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'systemVersion': instance.systemVersion,
      'developerMode': instance.developerMode,
      'upgradeBackupCopies': instance.upgradeBackupCopies,
      'sessionTimeout': instance.sessionTimeout,
      'port': instance.port,
      'ipv6': instance.ipv6,
      'bindAddress': instance.bindAddress,
      'panelName': instance.panelName,
      'theme': instance.theme,
      'menuTabs': instance.menuTabs,
      'language': instance.language,
      'serverPort': instance.serverPort,
      'ssl': instance.ssl,
      'sslType': instance.sslType,
      'bindDomain': instance.bindDomain,
      'allowIPs': instance.allowIPs,
      'securityEntrance': instance.securityEntrance,
      'dashboardMemoVisible': instance.dashboardMemoVisible,
      'dashboardSimpleNodeVisible': instance.dashboardSimpleNodeVisible,
      'expirationDays': instance.expirationDays,
      'expirationTime': instance.expirationTime,
      'complexityVerification': instance.complexityVerification,
      'mfaStatus': instance.mfaStatus,
      'mfaSecret': instance.mfaSecret,
      'mfaInterval': instance.mfaInterval,
      'appStoreVersion': instance.appStoreVersion,
      'appStoreLastModified': instance.appStoreLastModified,
      'appStoreSyncStatus': instance.appStoreSyncStatus,
      'hideMenu': instance.hideMenu,
      'noAuthSetting': instance.noAuthSetting,
      'proxyUrl': instance.proxyUrl,
      'proxyType': instance.proxyType,
      'proxyPort': instance.proxyPort,
      'proxyUser': instance.proxyUser,
      'proxyPasswd': instance.proxyPasswd,
      'proxyPasswdKeep': instance.proxyPasswdKeep,
      'apiInterfaceStatus': instance.apiInterfaceStatus,
      'apiKey': instance.apiKey,
      'ipWhiteList': instance.ipWhiteList,
      'apiKeyValidityTime': instance.apiKeyValidityTime,
    };
