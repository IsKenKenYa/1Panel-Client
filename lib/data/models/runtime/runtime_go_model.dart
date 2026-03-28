part of '../runtime_models.dart';

class GoRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? goHome;
  final String? gopath;
  final String? gocache;
  final Map<String, String>? environmentVariables;
  final String? status;

  const GoRuntime({
    this.id,
    this.name,
    this.version,
    this.goHome,
    this.gopath,
    this.gocache,
    this.environmentVariables,
    this.status,
  });

  factory GoRuntime.fromJson(Map<String, dynamic> json) {
    return GoRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      goHome: json['goHome'] as String?,
      gopath: json['gopath'] as String?,
      gocache: json['gocache'] as String?,
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
      'goHome': goHome,
      'gopath': gopath,
      'gocache': gocache,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        goHome,
        gopath,
        gocache,
        environmentVariables,
        status
      ];
}

/// PHP runtime specific model
