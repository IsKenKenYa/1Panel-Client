part of '../runtime_models.dart';

class PHPExtensionInstallRequest extends Equatable {
  final int id;
  final String name;
  final String taskId;

  const PHPExtensionInstallRequest({
    required this.id,
    required this.name,
    this.taskId = '',
  });

  factory PHPExtensionInstallRequest.fromJson(Map<String, dynamic> json) {
    return PHPExtensionInstallRequest(
      id: json['id'] as int? ?? json['ID'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      taskId: json['taskId'] as String? ?? json['taskID'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (taskId.isNotEmpty) 'taskID': taskId,
      };

  @override
  List<Object?> get props => [id, name, taskId];
}
