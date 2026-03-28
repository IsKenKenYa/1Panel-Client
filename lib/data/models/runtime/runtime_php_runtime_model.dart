part of '../runtime_models.dart';

class PHPRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? phpHome;
  final String? phpIniPath;
  final String? extensionDir;
  final Map<String, String>? environmentVariables;
  final String? status;

  const PHPRuntime({
    this.id,
    this.name,
    this.version,
    this.phpHome,
    this.phpIniPath,
    this.extensionDir,
    this.environmentVariables,
    this.status,
  });

  factory PHPRuntime.fromJson(Map<String, dynamic> json) {
    return PHPRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      phpHome: json['phpHome'] as String?,
      phpIniPath: json['phpIniPath'] as String?,
      extensionDir: json['extensionDir'] as String?,
      environmentVariables:
          (json['environmentVariables'] as Map<String, dynamic>?)
              ?.cast<String, String>(),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'phpHome': phpHome,
      'phpIniPath': phpIniPath,
      'extensionDir': extensionDir,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        phpHome,
        phpIniPath,
        extensionDir,
        environmentVariables,
        status
      ];
}

/// PHP 容器配置模型（runtime/php/container）
