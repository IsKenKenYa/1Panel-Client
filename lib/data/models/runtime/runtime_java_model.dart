part of '../runtime_models.dart';

class JavaRuntime extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? jdkHome;
  final String? javaHome;
  final String? classpath;
  final Map<String, String>? environmentVariables;
  final String? status;

  const JavaRuntime({
    this.id,
    this.name,
    this.version,
    this.jdkHome,
    this.javaHome,
    this.classpath,
    this.environmentVariables,
    this.status,
  });

  factory JavaRuntime.fromJson(Map<String, dynamic> json) {
    return JavaRuntime(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      jdkHome: json['jdkHome'] as String?,
      javaHome: json['javaHome'] as String?,
      classpath: json['classpath'] as String?,
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
      'jdkHome': jdkHome,
      'javaHome': javaHome,
      'classpath': classpath,
      'environmentVariables': environmentVariables,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        version,
        jdkHome,
        javaHome,
        classpath,
        environmentVariables,
        status
      ];
}

/// Node.js runtime specific model
