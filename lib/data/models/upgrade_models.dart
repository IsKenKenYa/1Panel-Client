import 'package:equatable/equatable.dart';

/// Version information model
class VersionInfo extends Equatable {
  final String? version;
  final String? buildDate;
  final String? gitCommit;
  final String? goVersion;
  final bool? isLatest;
  final String? latestVersion;
  final String? releaseNotes;

  const VersionInfo({
    this.version,
    this.buildDate,
    this.gitCommit,
    this.goVersion,
    this.isLatest,
    this.latestVersion,
    this.releaseNotes,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] as String?,
      buildDate: json['buildDate'] as String?,
      gitCommit: json['gitCommit'] as String?,
      goVersion: json['goVersion'] as String?,
      isLatest: json['isLatest'] as bool?,
      latestVersion: json['latestVersion'] as String?,
      releaseNotes: json['releaseNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildDate': buildDate,
      'gitCommit': gitCommit,
      'goVersion': goVersion,
      'isLatest': isLatest,
      'latestVersion': latestVersion,
      'releaseNotes': releaseNotes,
    };
  }

  @override
  List<Object?> get props => [
        version,
        buildDate,
        gitCommit,
        goVersion,
        isLatest,
        latestVersion,
        releaseNotes
      ];
}

/// Upgrade operation model
class UpgradeOperation extends Equatable {
  final String? targetVersion;
  final bool? force;
  final bool? backup;
  final String? operationId;

  const UpgradeOperation({
    this.targetVersion,
    this.force,
    this.backup,
    this.operationId,
  });

  factory UpgradeOperation.fromJson(Map<String, dynamic> json) {
    return UpgradeOperation(
      targetVersion: json['targetVersion'] as String?,
      force: json['force'] as bool?,
      backup: json['backup'] as bool?,
      operationId: json['operationId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'targetVersion': targetVersion,
      'force': force,
      'backup': backup,
      'operationId': operationId,
    };
  }

  @override
  List<Object?> get props => [targetVersion, force, backup, operationId];
}
