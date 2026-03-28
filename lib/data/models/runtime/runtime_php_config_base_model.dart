part of '../runtime_models.dart';

class PHPConfig extends Equatable {
  final Map<String, String>? params;
  final List<String> disableFunctions;
  final String? uploadMaxSize;
  final String? maxExecutionTime;

  const PHPConfig({
    this.params,
    this.disableFunctions = const <String>[],
    this.uploadMaxSize,
    this.maxExecutionTime,
  });

  factory PHPConfig.fromJson(Map<String, dynamic> json) {
    return PHPConfig(
      params: (json['params'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      disableFunctions:
          (json['disableFunctions'] as List<dynamic>?)?.cast<String>() ??
              const <String>[],
      uploadMaxSize: json['uploadMaxSize'] as String?,
      maxExecutionTime: json['maxExecutionTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'params': params,
        'disableFunctions': disableFunctions,
        'uploadMaxSize': uploadMaxSize,
        'maxExecutionTime': maxExecutionTime,
      };

  @override
  List<Object?> get props => [
        params,
        disableFunctions,
        uploadMaxSize,
        maxExecutionTime,
      ];
}

class PHPConfigUpdate extends Equatable {
  final int id;
  final String scope;
  final Map<String, String>? params;
  final List<String>? disableFunctions;
  final String? uploadMaxSize;
  final String? maxExecutionTime;

  const PHPConfigUpdate({
    required this.id,
    required this.scope,
    this.params,
    this.disableFunctions,
    this.uploadMaxSize,
    this.maxExecutionTime,
  });

  factory PHPConfigUpdate.fromJson(Map<String, dynamic> json) {
    return PHPConfigUpdate(
      id: json['id'] as int? ?? 0,
      scope: json['scope'] as String? ?? '',
      params: (json['params'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      disableFunctions:
          (json['disableFunctions'] as List<dynamic>?)?.cast<String>(),
      uploadMaxSize: json['uploadMaxSize'] as String?,
      maxExecutionTime: json['maxExecutionTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scope': scope,
        'params': params,
        'disableFunctions': disableFunctions,
        'uploadMaxSize': uploadMaxSize,
        'maxExecutionTime': maxExecutionTime,
      };

  @override
  List<Object?> get props => [
        id,
        scope,
        params,
        disableFunctions,
        uploadMaxSize,
        maxExecutionTime,
      ];
}

