part of '../runtime_models.dart';

class SupervisorProcessOperateRequest extends Equatable {
  final String operate;
  final String name;
  final int id;

  const SupervisorProcessOperateRequest({
    required this.operate,
    required this.name,
    required this.id,
  });

  factory SupervisorProcessOperateRequest.fromJson(Map<String, dynamic> json) {
    return SupervisorProcessOperateRequest(
      operate: json['operate'] as String? ?? '',
      name: json['name'] as String? ?? '',
      id: json['id'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'operate': operate,
        'name': name,
        'id': id,
      };

  @override
  List<Object?> get props => [operate, name, id];
}

class SupervisorProcessUpsertRequest extends Equatable {
  final String operate;
  final String name;
  final String command;
  final String user;
  final String dir;
  final String numprocs;
  final int id;
  final String environment;

  const SupervisorProcessUpsertRequest({
    required this.operate,
    required this.name,
    required this.command,
    required this.user,
    required this.dir,
    required this.numprocs,
    required this.id,
    required this.environment,
  });

  factory SupervisorProcessUpsertRequest.fromJson(Map<String, dynamic> json) {
    return SupervisorProcessUpsertRequest(
      operate: json['operate'] as String? ?? '',
      name: json['name'] as String? ?? '',
      command: json['command'] as String? ?? '',
      user: json['user'] as String? ?? '',
      dir: json['dir'] as String? ?? '',
      numprocs: json['numprocs']?.toString() ?? '',
      id: json['id'] as int? ?? 0,
      environment: json['environment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'operate': operate,
        'name': name,
        'command': command,
        'user': user,
        'dir': dir,
        'numprocs': numprocs,
        'id': id,
        'environment': environment,
      };

  @override
  List<Object?> get props => [
        operate,
        name,
        command,
        user,
        dir,
        numprocs,
        id,
        environment,
      ];
}

class SupervisorProcessFileRequest extends Equatable {
  final String operate;
  final String name;
  final String file;
  final int id;
  final String? content;

  const SupervisorProcessFileRequest({
    required this.operate,
    required this.name,
    required this.file,
    required this.id,
    this.content,
  });

  factory SupervisorProcessFileRequest.fromJson(Map<String, dynamic> json) {
    return SupervisorProcessFileRequest(
      operate: json['operate'] as String? ?? '',
      name: json['name'] as String? ?? '',
      file: json['file'] as String? ?? '',
      id: json['id'] as int? ?? 0,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'operate': operate,
        'name': name,
        'file': file,
        'id': id,
        if (content != null) 'content': content,
      };

  @override
  List<Object?> get props => [operate, name, file, id, content];
}

/// Java runtime specific model
