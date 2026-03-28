part of '../runtime_models.dart';

class NodeRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? nodeHome;
  final String? npmHome;
  final String? packageManager;
  final Map<String, String>? environmentVariables;
  final String? status;

  const NodeRuntime({
    this.id,
    this.name,
    this.version,
    this.nodeHome,
    this.npmHome,
    this.packageManager,
    this.environmentVariables,
    this.status,
  });

  factory NodeRuntime.fromJson(Map<String, dynamic> json) {
    return NodeRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      nodeHome: json['nodeHome'] as String?,
      npmHome: json['npmHome'] as String?,
      packageManager: json['packageManager'] as String?,
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
      'nodeHome': nodeHome,
      'npmHome': npmHome,
      'packageManager': packageManager,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        nodeHome,
        npmHome,
        packageManager,
        environmentVariables,
        status
      ];
}

/// Python runtime specific model
