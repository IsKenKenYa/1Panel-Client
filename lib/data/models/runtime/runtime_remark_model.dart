part of '../runtime_models.dart';

class RuntimeRemarkUpdate extends Equatable {
  final int id;
  final String remark;

  const RuntimeRemarkUpdate({
    required this.id,
    required this.remark,
  });

  factory RuntimeRemarkUpdate.fromJson(Map<String, dynamic> json) {
    return RuntimeRemarkUpdate(
      id: json['id'] as int? ?? 0,
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'remark': remark,
      };

  @override
  List<Object?> get props => [id, remark];
}
