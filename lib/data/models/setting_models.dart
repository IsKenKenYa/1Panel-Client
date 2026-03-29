import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'setting_models.g.dart';

/// Setting information model
class SettingInfo extends Equatable {
  final String? key;
  final String? value;
  final String? description;
  final String? type;
  final String? category;
  final bool? encrypted;
  final String? defaultValue;
  final String? updateTime;

  const SettingInfo({
    this.key,
    this.value,
    this.description,
    this.type,
    this.category,
    this.encrypted,
    this.defaultValue,
    this.updateTime,
  });

  factory SettingInfo.fromJson(Map<String, dynamic> json) {
    return SettingInfo(
      key: json['key'] as String?,
      value: json['value'] as String?,
      description: json['description'] as String?,
      type: json['type'] as String?,
      category: json['category'] as String?,
      encrypted: json['encrypted'] as bool?,
      defaultValue: json['defaultValue'] as String?,
      updateTime: json['updateTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'type': type,
      'category': category,
      'encrypted': encrypted,
      'defaultValue': defaultValue,
      'updateTime': updateTime,
    };
  }

  @override
  List<Object?> get props => [
        key,
        value,
        description,
        type,
        category,
        encrypted,
        defaultValue,
        updateTime
      ];
}

/// Setting update request model
class SettingUpdate extends Equatable {
  final String key;
  final String value;

  const SettingUpdate({
    required this.key,
    required this.value,
  });

  factory SettingUpdate.fromJson(Map<String, dynamic> json) {
    return SettingUpdate(
      key: json['key'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [key, value];
}

/// Setting category model
class SettingCategory extends Equatable {
  final String? name;
  final String? description;
  final List<SettingInfo>? settings;

  const SettingCategory({
    this.name,
    this.description,
    this.settings,
  });

  factory SettingCategory.fromJson(Map<String, dynamic> json) {
    return SettingCategory(
      name: json['name'] as String?,
      description: json['description'] as String?,
      settings: (json['settings'] as List?)
          ?.map((item) => SettingInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'settings': settings?.map((setting) => setting.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [name, description, settings];
}

// ==================== 系统设置相关模型 ====================

/// 系统设置
@JsonSerializable()
class SystemSettings extends Equatable {
  final String? siteName;
  final String? language;
  final String? theme;
  final String? timeZone;
  final String? sessionTimeout;
  final String? defaultPassword;
  final bool? allowAccessKey;
  final String? complexity;
  final int? minPasswordLength;

  const SystemSettings({
    this.siteName,
    this.language,
    this.theme,
    this.timeZone,
    this.sessionTimeout,
    this.defaultPassword,
    this.allowAccessKey,
    this.complexity,
    this.minPasswordLength,
  });

  factory SystemSettings.fromJson(Map<String, dynamic> json) =>
      _$SystemSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SystemSettingsToJson(this);

  @override
  List<Object?> get props => [
        siteName,
        language,
        theme,
        timeZone,
        sessionTimeout,
        defaultPassword,
        allowAccessKey,
        complexity,
        minPasswordLength
      ];
}

/// 系统信息
@JsonSerializable()
class SystemInfo extends Equatable {
  final String? version;
  final String? build;
  final String? arch;
  final String? os;
  final String? goVersion;
  final String? dockerVersion;
  final String? uptime;
  final int? totalMemory;
  final int? usedMemory;
  final int? totalDisk;
  final int? usedDisk;

  const SystemInfo({
    this.version,
    this.build,
    this.arch,
    this.os,
    this.goVersion,
    this.dockerVersion,
    this.uptime,
    this.totalMemory,
    this.usedMemory,
    this.totalDisk,
    this.usedDisk,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) =>
      _$SystemInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SystemInfoToJson(this);

  @override
  List<Object?> get props => [
        version,
        build,
        arch,
        os,
        goVersion,
        dockerVersion,
        uptime,
        totalMemory,
        usedMemory,
        totalDisk,
        usedDisk
      ];
}

/// 系统时间
@JsonSerializable()
class SystemTime extends Equatable {
  final String? time;
  final String? timeZone;

  const SystemTime({
    this.time,
    this.timeZone,
  });

  factory SystemTime.fromJson(Map<String, dynamic> json) =>
      _$SystemTimeFromJson(json);
  Map<String, dynamic> toJson() => _$SystemTimeToJson(this);

  @override
  List<Object?> get props => [time, timeZone];
}

/// 系统时间设置
@JsonSerializable()
class SystemTimeSet extends Equatable {
  final String? time;
  final String? timeZone;

  const SystemTimeSet({
    this.time,
    this.timeZone,
  });

  factory SystemTimeSet.fromJson(Map<String, dynamic> json) =>
      _$SystemTimeSetFromJson(json);
  Map<String, dynamic> toJson() => _$SystemTimeSetToJson(this);

  @override
  List<Object?> get props => [time, timeZone];
}

// ==================== 安全设置相关模型 ====================

/// 安全设置
@JsonSerializable()
class SecuritySettings extends Equatable {
  final bool? allowIPs;
  final List<String>? allowedIPs;
  final String? authMethod;
  final int? failedAttempts;
  final int? lockTime;
  final String? passwordPolicy;

  const SecuritySettings({
    this.allowIPs,
    this.allowedIPs,
    this.authMethod,
    this.failedAttempts,
    this.lockTime,
    this.passwordPolicy,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      _$SecuritySettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SecuritySettingsToJson(this);

  @override
  List<Object?> get props => [
        allowIPs,
        allowedIPs,
        authMethod,
        failedAttempts,
        lockTime,
        passwordPolicy
      ];
}

/// 安全设置更新
@JsonSerializable()
class SecuritySettingsUpdate extends Equatable {
  final bool? allowIPs;
  final List<String>? allowedIPs;
  final String? authMethod;
  final int? failedAttempts;
  final int? lockTime;
  final String? passwordPolicy;

  const SecuritySettingsUpdate({
    this.allowIPs,
    this.allowedIPs,
    this.authMethod,
    this.failedAttempts,
    this.lockTime,
    this.passwordPolicy,
  });

  factory SecuritySettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$SecuritySettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$SecuritySettingsUpdateToJson(this);

  @override
  List<Object?> get props => [
        allowIPs,
        allowedIPs,
        authMethod,
        failedAttempts,
        lockTime,
        passwordPolicy
      ];
}

// ==================== 面板设置相关模型 ====================

/// 面板设置
@JsonSerializable()
class PanelSettings extends Equatable {
  final String? title;
  final String? logo;
  final String? theme;
  final String? language;
  final String? serverName;
  final String? serverAddr;
  final String? port;
  final String? ssl;
  final String? ipv6;
  final bool? bind;

  const PanelSettings({
    this.title,
    this.logo,
    this.theme,
    this.language,
    this.serverName,
    this.serverAddr,
    this.port,
    this.ssl,
    this.ipv6,
    this.bind,
  });

  factory PanelSettings.fromJson(Map<String, dynamic> json) =>
      _$PanelSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$PanelSettingsToJson(this);

  @override
  List<Object?> get props => [
        title,
        logo,
        theme,
        language,
        serverName,
        serverAddr,
        port,
        ssl,
        ipv6,
        bind
      ];
}

/// 面板设置更新
@JsonSerializable()
class PanelSettingsUpdate extends Equatable {
  final String? title;
  final String? logo;
  final String? theme;
  final String? language;
  final String? serverName;
  final String? serverAddr;
  final String? port;
  final String? ssl;
  final String? ipv6;
  final bool? bind;

  const PanelSettingsUpdate({
    this.title,
    this.logo,
    this.theme,
    this.language,
    this.serverName,
    this.serverAddr,
    this.port,
    this.ssl,
    this.ipv6,
    this.bind,
  });

  factory PanelSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$PanelSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$PanelSettingsUpdateToJson(this);

  @override
  List<Object?> get props => [
        title,
        logo,
        theme,
        language,
        serverName,
        serverAddr,
        port,
        ssl,
        ipv6,
        bind
      ];
}

// ==================== 用户设置相关模型 ====================

/// 用户设置
@JsonSerializable()
class UserSettings extends Equatable {
  final String? username;
  final String? email;
  final String? language;
  final String? theme;
  final String? timeZone;
  final int? failedLoginAttempts;
  final int? lockTime;

  const UserSettings({
    this.username,
    this.email,
    this.language,
    this.theme,
    this.timeZone,
    this.failedLoginAttempts,
    this.lockTime,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  @override
  List<Object?> get props => [
        username,
        email,
        language,
        theme,
        timeZone,
        failedLoginAttempts,
        lockTime
      ];
}

/// 用户设置更新
@JsonSerializable()
class UserSettingsUpdate extends Equatable {
  final String? username;
  final String? email;
  final String? language;
  final String? theme;
  final String? timeZone;
  final int? failedLoginAttempts;
  final int? lockTime;

  const UserSettingsUpdate({
    this.username,
    this.email,
    this.language,
    this.theme,
    this.timeZone,
    this.failedLoginAttempts,
    this.lockTime,
  });

  factory UserSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsUpdateToJson(this);

  @override
  List<Object?> get props => [
        username,
        email,
        language,
        theme,
        timeZone,
        failedLoginAttempts,
        lockTime
      ];
}

// ==================== 通知设置相关模型 ====================

/// 通知设置
@JsonSerializable()
class NotificationSettings extends Equatable {
  final bool? emailEnabled;
  final String? emailServer;
  final String? emailPort;
  final String? emailUsername;
  final String? emailPassword;
  final String? emailFrom;
  final bool? webhookEnabled;
  final String? webhookUrl;

  const NotificationSettings({
    this.emailEnabled,
    this.emailServer,
    this.emailPort,
    this.emailUsername,
    this.emailPassword,
    this.emailFrom,
    this.webhookEnabled,
    this.webhookUrl,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsToJson(this);

  @override
  List<Object?> get props => [
        emailEnabled,
        emailServer,
        emailPort,
        emailUsername,
        emailPassword,
        emailFrom,
        webhookEnabled,
        webhookUrl
      ];
}

/// 通知设置更新
@JsonSerializable()
class NotificationSettingsUpdate extends Equatable {
  final bool? emailEnabled;
  final String? emailServer;
  final String? emailPort;
  final String? emailUsername;
  final String? emailPassword;
  final String? emailFrom;
  final bool? webhookEnabled;
  final String? webhookUrl;

  const NotificationSettingsUpdate({
    this.emailEnabled,
    this.emailServer,
    this.emailPort,
    this.emailUsername,
    this.emailPassword,
    this.emailFrom,
    this.webhookEnabled,
    this.webhookUrl,
  });

  factory NotificationSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationSettingsUpdateToJson(this);

  @override
  List<Object?> get props => [
        emailEnabled,
        emailServer,
        emailPort,
        emailUsername,
        emailPassword,
        emailFrom,
        webhookEnabled,
        webhookUrl
      ];
}

// ==================== 备份设置相关模型 ====================

/// 备份设置
@JsonSerializable()
class BackupSettings extends Equatable {
  final String? backupDir;
  final String? backupType;
  final String? backupRetention;
  final bool? backupEnabled;
  final String? backupSchedule;

  const BackupSettings({
    this.backupDir,
    this.backupType,
    this.backupRetention,
    this.backupEnabled,
    this.backupSchedule,
  });

  factory BackupSettings.fromJson(Map<String, dynamic> json) =>
      _$BackupSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$BackupSettingsToJson(this);

  @override
  List<Object?> get props =>
      [backupDir, backupType, backupRetention, backupEnabled, backupSchedule];
}

/// 备份设置更新
@JsonSerializable()
class BackupSettingsUpdate extends Equatable {
  final String? backupDir;
  final String? backupType;
  final String? backupRetention;
  final bool? backupEnabled;
  final String? backupSchedule;

  const BackupSettingsUpdate({
    this.backupDir,
    this.backupType,
    this.backupRetention,
    this.backupEnabled,
    this.backupSchedule,
  });

  factory BackupSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$BackupSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$BackupSettingsUpdateToJson(this);

  @override
  List<Object?> get props =>
      [backupDir, backupType, backupRetention, backupEnabled, backupSchedule];
}

// ==================== 主题设置相关模型 ====================

/// 主题设置
@JsonSerializable()
class ThemeSettings extends Equatable {
  final String? theme;
  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;

  const ThemeSettings({
    this.theme,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
  });

  factory ThemeSettings.fromJson(Map<String, dynamic> json) =>
      _$ThemeSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeSettingsToJson(this);

  @override
  List<Object?> get props => [theme, primaryColor, backgroundColor, textColor];
}

/// 主题设置更新
@JsonSerializable()
class ThemeSettingsUpdate extends Equatable {
  final String? theme;
  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;

  const ThemeSettingsUpdate({
    this.theme,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
  });

  factory ThemeSettingsUpdate.fromJson(Map<String, dynamic> json) =>
      _$ThemeSettingsUpdateFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeSettingsUpdateToJson(this);

  @override
  List<Object?> get props => [theme, primaryColor, backgroundColor, textColor];
}

// ==================== 语言设置相关模型 ====================

/// 语言设置
@JsonSerializable()
class LanguageSettings extends Equatable {
  final String? language;
  final String? region;

  const LanguageSettings({
    this.language,
    this.region,
  });

  factory LanguageSettings.fromJson(Map<String, dynamic> json) =>
      _$LanguageSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSettingsToJson(this);

  @override
  List<Object?> get props => [language, region];
}

/// 语言设置
@JsonSerializable()
class LanguageSet extends Equatable {
  final String? language;
  final String? region;

  const LanguageSet({
    this.language,
    this.region,
  });

  factory LanguageSet.fromJson(Map<String, dynamic> json) =>
      _$LanguageSetFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageSetToJson(this);

  @override
  List<Object?> get props => [language, region];
}

// ==================== NTP同步相关模型 ====================

/// NTP同步设置
@JsonSerializable()
class NTPSync extends Equatable {
  final bool? enabled;
  final String? server;
  final String? interval;
  final String? timezone;

  const NTPSync({
    this.enabled,
    this.server,
    this.interval,
    this.timezone,
  });

  factory NTPSync.fromJson(Map<String, dynamic> json) =>
      _$NTPSyncFromJson(json);
  Map<String, dynamic> toJson() => _$NTPSyncToJson(this);

  @override
  List<Object?> get props => [enabled, server, interval, timezone];
}

// ==================== 时区信息相关模型 ====================

/// 时区信息
@JsonSerializable()
class TimezoneInfo extends Equatable {
  final String? zone;
  final String? offset;

  const TimezoneInfo({
    this.zone,
    this.offset,
  });

  factory TimezoneInfo.fromJson(Map<String, dynamic> json) =>
      _$TimezoneInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TimezoneInfoToJson(this);

  @override
  List<Object?> get props => [zone, offset];
}

/// 语言信息
@JsonSerializable()
class LanguageInfo extends Equatable {
  final String? code;
  final String? name;
  final String? nativeName;

  const LanguageInfo({
    this.code,
    this.name,
    this.nativeName,
  });

  factory LanguageInfo.fromJson(Map<String, dynamic> json) =>
      _$LanguageInfoFromJson(json);
  Map<String, dynamic> toJson() => _$LanguageInfoToJson(this);

  @override
  List<Object?> get props => [code, name, nativeName];
}

/// 主题信息
@JsonSerializable()
class ThemeInfo extends Equatable {
  final String? name;
  final String? displayName;
  final String? primaryColor;
  final String? backgroundColor;

  const ThemeInfo({
    this.name,
    this.displayName,
    this.primaryColor,
    this.backgroundColor,
  });

  factory ThemeInfo.fromJson(Map<String, dynamic> json) =>
      _$ThemeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeInfoToJson(this);

  @override
  List<Object?> get props => [name, displayName, primaryColor, backgroundColor];
}

// ==================== 设置导入导出相关模型 ====================

/// 设置导出
@JsonSerializable()
class SettingsExport extends Equatable {
  final String? data;
  final String? timestamp;
  final String? version;

  const SettingsExport({
    this.data,
    this.timestamp,
    this.version,
  });

  factory SettingsExport.fromJson(Map<String, dynamic> json) =>
      _$SettingsExportFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsExportToJson(this);

  @override
  List<Object?> get props => [data, timestamp, version];
}

/// 设置导入
@JsonSerializable()
class SettingsImport extends Equatable {
  final String? data;
  final bool? overwrite;

  const SettingsImport({
    this.data,
    this.overwrite,
  });

  factory SettingsImport.fromJson(Map<String, dynamic> json) =>
      _$SettingsImportFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsImportToJson(this);

  @override
  List<Object?> get props => [data, overwrite];
}

// ==================== MFA相关模型 ====================

/// MFA凭证
@JsonSerializable()
class MfaCredential extends Equatable {
  final String code;
  final String interval;
  final String secret;

  const MfaCredential({
    required this.code,
    required this.interval,
    required this.secret,
  });

  factory MfaCredential.fromJson(Map<String, dynamic> json) =>
      _$MfaCredentialFromJson(json);
  Map<String, dynamic> toJson() => _$MfaCredentialToJson(this);

  @override
  List<Object?> get props => [code, interval, secret];
}

/// MFA OTP响应
@JsonSerializable()
class MfaOtp extends Equatable {
  final String? qrImage;
  final String? secret;

  const MfaOtp({
    this.qrImage,
    this.secret,
  });

  factory MfaOtp.fromJson(Map<String, dynamic> json) => _$MfaOtpFromJson(json);
  Map<String, dynamic> toJson() => _$MfaOtpToJson(this);

  @override
  List<Object?> get props => [qrImage, secret];
}

/// MFA绑定请求
@JsonSerializable()
class MfaBindRequest extends Equatable {
  final String code;
  final String interval;
  final String secret;

  const MfaBindRequest({
    required this.code,
    required this.interval,
    required this.secret,
  });

  factory MfaBindRequest.fromJson(Map<String, dynamic> json) =>
      _$MfaBindRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MfaBindRequestToJson(this);

  @override
  List<Object?> get props => [code, interval, secret];
}

/// MFA状态
@JsonSerializable()
class MfaStatus extends Equatable {
  final bool enabled;
  final String? secret;

  const MfaStatus({
    required this.enabled,
    this.secret,
  });

  factory MfaStatus.fromJson(Map<String, dynamic> json) =>
      _$MfaStatusFromJson(json);
  Map<String, dynamic> toJson() => _$MfaStatusToJson(this);

  @override
  List<Object?> get props => [enabled, secret];
}

/// 终端设置信息
@JsonSerializable()
class TerminalInfo extends Equatable {
  final String? cursorBlink;
  final String? cursorStyle;
  final String? fontSize;
  final String? letterSpacing;
  final String? lineHeight;
  final String? scrollSensitivity;
  final String? scrollback;

  const TerminalInfo({
    this.cursorBlink,
    this.cursorStyle,
    this.fontSize,
    this.letterSpacing,
    this.lineHeight,
    this.scrollSensitivity,
    this.scrollback,
  });

  factory TerminalInfo.fromJson(Map<String, dynamic> json) =>
      _$TerminalInfoFromJson(json);
  Map<String, dynamic> toJson() => _$TerminalInfoToJson(this);

  @override
  List<Object?> get props => [
        cursorBlink,
        cursorStyle,
        fontSize,
        letterSpacing,
        lineHeight,
        scrollSensitivity,
        scrollback
      ];
}

/// 界面设置信息
@JsonSerializable()
class InterfaceInfo extends Equatable {
  final String? theme;
  final String? language;
  final String? menuCollapse;
  final String? entry;

  const InterfaceInfo({
    this.theme,
    this.language,
    this.menuCollapse,
    this.entry,
  });

  factory InterfaceInfo.fromJson(Map<String, dynamic> json) =>
      _$InterfaceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$InterfaceInfoToJson(this);

  @override
  List<Object?> get props => [theme, language, menuCollapse, entry];
}

/// 系统设置信息（实际API响应）
@JsonSerializable()
class SystemSettingInfo extends Equatable {
  final String? userName;
  final String? systemVersion;
  final String? developerMode;
  final String? upgradeBackupCopies;
  final String? sessionTimeout;
  final String? port;
  final String? ipv6;
  final String? bindAddress;
  final String? panelName;
  final String? theme;
  final String? menuTabs;
  final String? language;
  final String? serverPort;
  final String? ssl;
  final String? sslType;
  final String? bindDomain;
  final String? allowIPs;
  final String? securityEntrance;
  final String? dashboardMemoVisible;
  final String? dashboardSimpleNodeVisible;
  final String? expirationDays;
  final String? expirationTime;
  final String? complexityVerification;
  final String? mfaStatus;
  final String? mfaSecret;
  final String? mfaInterval;
  final String? appStoreVersion;
  final String? appStoreLastModified;
  final String? appStoreSyncStatus;
  final String? hideMenu;
  final String? noAuthSetting;
  final String? proxyUrl;
  final String? proxyType;
  final String? proxyPort;
  final String? proxyUser;
  final String? proxyPasswd;
  final String? proxyPasswdKeep;
  final String? apiInterfaceStatus;
  final String? apiKey;
  final String? ipWhiteList;
  final String? apiKeyValidityTime;

  const SystemSettingInfo({
    this.userName,
    this.systemVersion,
    this.developerMode,
    this.upgradeBackupCopies,
    this.sessionTimeout,
    this.port,
    this.ipv6,
    this.bindAddress,
    this.panelName,
    this.theme,
    this.menuTabs,
    this.language,
    this.serverPort,
    this.ssl,
    this.sslType,
    this.bindDomain,
    this.allowIPs,
    this.securityEntrance,
    this.dashboardMemoVisible,
    this.dashboardSimpleNodeVisible,
    this.expirationDays,
    this.expirationTime,
    this.complexityVerification,
    this.mfaStatus,
    this.mfaSecret,
    this.mfaInterval,
    this.appStoreVersion,
    this.appStoreLastModified,
    this.appStoreSyncStatus,
    this.hideMenu,
    this.noAuthSetting,
    this.proxyUrl,
    this.proxyType,
    this.proxyPort,
    this.proxyUser,
    this.proxyPasswd,
    this.proxyPasswdKeep,
    this.apiInterfaceStatus,
    this.apiKey,
    this.ipWhiteList,
    this.apiKeyValidityTime,
  });

  factory SystemSettingInfo.fromJson(Map<String, dynamic> json) =>
      _$SystemSettingInfoFromJson(json);
  Map<String, dynamic> toJson() => _$SystemSettingInfoToJson(this);

  @override
  List<Object?> get props => [
        userName,
        systemVersion,
        developerMode,
        upgradeBackupCopies,
        sessionTimeout,
        port,
        ipv6,
        bindAddress,
        panelName,
        theme,
        menuTabs,
        language,
        serverPort,
        ssl,
        sslType,
        bindDomain,
        allowIPs,
        securityEntrance,
        dashboardMemoVisible,
        dashboardSimpleNodeVisible,
        expirationDays,
        expirationTime,
        complexityVerification,
        mfaStatus,
        mfaSecret,
        mfaInterval,
        appStoreVersion,
        appStoreLastModified,
        appStoreSyncStatus,
        hideMenu,
        noAuthSetting,
        proxyUrl,
        proxyType,
        proxyPort,
        proxyUser,
        proxyPasswd,
        proxyPasswdKeep,
        apiInterfaceStatus,
        apiKey,
        ipWhiteList,
        apiKeyValidityTime,
      ];
}

class MemoUpdate extends Equatable {
  final String content;

  const MemoUpdate({required this.content});

  Map<String, dynamic> toJson() => <String, dynamic>{'content': content};

  @override
  List<Object?> get props => [content];
}

class PasskeyInfo extends Equatable {
  final String? id;
  final String? name;
  final String? createdAt;
  final String? lastUsedAt;

  const PasskeyInfo({
    this.id,
    this.name,
    this.createdAt,
    this.lastUsedAt,
  });

  factory PasskeyInfo.fromJson(Map<String, dynamic> json) {
    return PasskeyInfo(
      id: json['id'] as String?,
      name: json['name'] as String?,
      createdAt: json['createdAt'] as String?,
      lastUsedAt: json['lastUsedAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, lastUsedAt];
}

class PasskeyRegisterRequest extends Equatable {
  final String name;

  const PasskeyRegisterRequest({required this.name});

  Map<String, dynamic> toJson() => <String, dynamic>{'name': name};

  @override
  List<Object?> get props => [name];
}

class PasskeyBeginResponse extends Equatable {
  final String? sessionId;
  final dynamic publicKey;

  const PasskeyBeginResponse({
    this.sessionId,
    this.publicKey,
  });

  factory PasskeyBeginResponse.fromJson(Map<String, dynamic> json) {
    return PasskeyBeginResponse(
      sessionId: json['sessionId'] as String?,
      publicKey: json['publicKey'],
    );
  }

  @override
  List<Object?> get props => [sessionId, publicKey];
}
