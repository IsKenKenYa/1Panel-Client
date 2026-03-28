part of '../runtime_models.dart';

class PythonRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? pythonHome;
  final String? pipHome;
  final String? virtualenvPath;
  final Map<String, String>? environmentVariables;
  final String? status;

  const PythonRuntime({
    this.id,
    this.name,
    this.version,
    this.pythonHome,
    this.pipHome,
    this.virtualenvPath,
    this.environmentVariables,
    this.status,
  });

  factory PythonRuntime.fromJson(Map<String, dynamic> json) {
    return PythonRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      pythonHome: json['pythonHome'] as String?,
      pipHome: json['pipHome'] as String?,
      virtualenvPath: json['virtualenvPath'] as String?,
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
      'pythonHome': pythonHome,
      'pipHome': pipHome,
      'virtualenvPath': virtualenvPath,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        pythonHome,
        pipHome,
        virtualenvPath,
        environmentVariables,
        status
      ];
}

/// Go runtime specific model
