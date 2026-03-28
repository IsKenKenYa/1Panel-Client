part of '../runtime_models.dart';

class PHPFpmConfig extends Equatable {
  final int id;
  final Map<String, String> params;

  const PHPFpmConfig({
    required this.id,
    this.params = const <String, String>{},
  });

  factory PHPFpmConfig.fromJson(Map<String, dynamic> json) {
    return PHPFpmConfig(
      id: json['id'] as int? ?? 0,
      params: (json['params'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const <String, String>{},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'params': params,
      };

  PHPFpmConfig copyWith({
    int? id,
    Map<String, String>? params,
  }) {
    return PHPFpmConfig(
      id: id ?? this.id,
      params: params ?? this.params,
    );
  }

  @override
  List<Object?> get props => [id, params];
}
