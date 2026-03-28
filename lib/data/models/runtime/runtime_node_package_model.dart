part of '../runtime_models.dart';

class NodeModuleRequest extends Equatable {
  final int id;
  final String operate;
  final String module;
  final String packageManager;

  const NodeModuleRequest({
    required this.id,
    this.operate = '',
    this.module = '',
    this.packageManager = '',
  });

  factory NodeModuleRequest.fromJson(Map<String, dynamic> json) {
    return NodeModuleRequest(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      operate: json['operate'] as String? ?? json['Operate'] as String? ?? '',
      module: json['module'] as String? ?? json['Module'] as String? ?? '',
      packageManager: json['pkgManager'] as String? ??
          json['PkgManager'] as String? ??
          json['packageManager'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ID': id,
        if (operate.isNotEmpty) 'Operate': operate,
        if (module.isNotEmpty) 'Module': module,
        if (packageManager.isNotEmpty) 'PkgManager': packageManager,
      };

  @override
  List<Object?> get props => [id, operate, module, packageManager];
}

class NodePackageRequest extends Equatable {
  final String codeDir;

  const NodePackageRequest({
    required this.codeDir,
  });

  factory NodePackageRequest.fromJson(Map<String, dynamic> json) {
    return NodePackageRequest(
      codeDir: json['codeDir'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'codeDir': codeDir,
      };

  @override
  List<Object?> get props => [codeDir];
}

class NodeModuleInfo extends Equatable {
  final String name;
  final String version;
  final String description;

  const NodeModuleInfo({
    required this.name,
    this.version = '',
    this.description = '',
  });

  factory NodeModuleInfo.fromJson(Map<String, dynamic> json) {
    return NodeModuleInfo(
      name: json['name'] as String? ?? '',
      version: json['version'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'description': description,
      };

  @override
  List<Object?> get props => [name, version, description];
}

class NodeScriptInfo extends Equatable {
  final String name;
  final String script;

  const NodeScriptInfo({
    required this.name,
    required this.script,
  });

  factory NodeScriptInfo.fromJson(Map<String, dynamic> json) {
    return NodeScriptInfo(
      name: json['name'] as String? ?? '',
      script: json['script'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'script': script,
      };

  @override
  List<Object?> get props => [name, script];
}
