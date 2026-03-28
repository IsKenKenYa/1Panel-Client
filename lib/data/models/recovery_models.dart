import 'package:equatable/equatable.dart';

/// Recovery point model
class RecoveryPoint extends Equatable {
  final String? id;
  final String? name;
  final String? description;
  final String? createTime;
  final int? size;
  final String? type;
  final bool? automatic;

  const RecoveryPoint({
    this.id,
    this.name,
    this.description,
    this.createTime,
    this.size,
    this.type,
    this.automatic,
  });

  factory RecoveryPoint.fromJson(Map<String, dynamic> json) {
    return RecoveryPoint(
      id: json['id'] as String?,
      name: json['name'] as String?,
      description: json['description'] as String?,
      createTime: json['createTime'] as String?,
      size: json['size'] as int?,
      type: json['type'] as String?,
      automatic: json['automatic'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createTime': createTime,
      'size': size,
      'type': type,
      'automatic': automatic,
    };
  }

  @override
  List<Object?> get props =>
      [id, name, description, createTime, size, type, automatic];
}
