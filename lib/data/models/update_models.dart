import 'package:equatable/equatable.dart';

/// Update info model
class UpdateInfo extends Equatable {
  final String? currentVersion;
  final String? latestVersion;
  final String? releaseNotes;
  final bool? isUpdateAvailable;
  final String? downloadUrl;
  final String? releaseDate;
  final String? updateType;

  const UpdateInfo({
    this.currentVersion,
    this.latestVersion,
    this.releaseNotes,
    this.isUpdateAvailable,
    this.downloadUrl,
    this.releaseDate,
    this.updateType,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      currentVersion: json['currentVersion'] as String?,
      latestVersion: json['latestVersion'] as String?,
      releaseNotes: json['releaseNotes'] as String?,
      isUpdateAvailable: json['isUpdateAvailable'] as bool?,
      downloadUrl: json['downloadUrl'] as String?,
      releaseDate: json['releaseDate'] as String?,
      updateType: json['updateType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentVersion': currentVersion,
      'latestVersion': latestVersion,
      'releaseNotes': releaseNotes,
      'isUpdateAvailable': isUpdateAvailable,
      'downloadUrl': downloadUrl,
      'releaseDate': releaseDate,
      'updateType': updateType,
    };
  }

  @override
  List<Object?> get props => [
        currentVersion,
        latestVersion,
        releaseNotes,
        isUpdateAvailable,
        downloadUrl,
        releaseDate,
        updateType
      ];
}

/// Update check request model
class UpdateCheckRequest extends Equatable {
  final String? channel;
  final bool? force;

  const UpdateCheckRequest({
    this.channel,
    this.force,
  });

  factory UpdateCheckRequest.fromJson(Map<String, dynamic> json) {
    return UpdateCheckRequest(
      channel: json['channel'] as String?,
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'force': force,
    };
  }

  @override
  List<Object?> get props => [channel, force];
}

/// Update download request model
class UpdateDownloadRequest extends Equatable {
  final String? version;
  final String? downloadUrl;

  const UpdateDownloadRequest({
    this.version,
    this.downloadUrl,
  });

  factory UpdateDownloadRequest.fromJson(Map<String, dynamic> json) {
    return UpdateDownloadRequest(
      version: json['version'] as String?,
      downloadUrl: json['downloadUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'downloadUrl': downloadUrl,
    };
  }

  @override
  List<Object?> get props => [version, downloadUrl];
}

/// Update apply request model
class UpdateApplyRequest extends Equatable {
  final String? version;
  final bool? backup;

  const UpdateApplyRequest({
    this.version,
    this.backup,
  });

  factory UpdateApplyRequest.fromJson(Map<String, dynamic> json) {
    return UpdateApplyRequest(
      version: json['version'] as String?,
      backup: json['backup'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'backup': backup,
    };
  }

  @override
  List<Object?> get props => [version, backup];
}

/// Update progress model
class UpdateProgress extends Equatable {
  final String? status;
  final int? progress;
  final String? message;
  final String? currentStep;
  final int? totalSteps;

  const UpdateProgress({
    this.status,
    this.progress,
    this.message,
    this.currentStep,
    this.totalSteps,
  });

  factory UpdateProgress.fromJson(Map<String, dynamic> json) {
    return UpdateProgress(
      status: json['status'] as String?,
      progress: json['progress'] as int?,
      message: json['message'] as String?,
      currentStep: json['currentStep'] as String?,
      totalSteps: json['totalSteps'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'progress': progress,
      'message': message,
      'currentStep': currentStep,
      'totalSteps': totalSteps,
    };
  }

  @override
  List<Object?> get props =>
      [status, progress, message, currentStep, totalSteps];
}
