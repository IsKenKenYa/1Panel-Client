part of '../runtime_models.dart';

class RuntimePackage extends Equatable {
  final int? id;
  final String? name;
  final String? version;
  final String? type;
  final int? runtimeId;
  final String? description;
  final String? status;

  const RuntimePackage({
    this.id,
    this.name,
    this.version,
    this.type,
    this.runtimeId,
    this.description,
    this.status,
  });

  factory RuntimePackage.fromJson(Map<String, dynamic> json) {
    return RuntimePackage(
      id: json['id'] as int?,
      name: json['name'] as String?,
      version: json['version'] as String?,
      type: json['type'] as String? ?? json['runtimeType'] as String?,
      runtimeId: json['runtimeId'] as int?,
      description: json['description'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'type': type,
      'runtimeId': runtimeId,
      'description': description,
      'status': status,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, version, type, runtimeId, description, status];
}
