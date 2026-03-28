part of '../runtime_models.dart';

class PHPConfigFileRequest extends Equatable {
  final int id;
  final String type;

  const PHPConfigFileRequest({
    required this.id,
    required this.type,
  });

  factory PHPConfigFileRequest.fromJson(Map<String, dynamic> json) {
    return PHPConfigFileRequest(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
      };

  @override
  List<Object?> get props => [id, type];
}

class PHPConfigFileUpdate extends Equatable {
  final int id;
  final String type;
  final String content;

  const PHPConfigFileUpdate({
    required this.id,
    required this.type,
    required this.content,
  });

  factory PHPConfigFileUpdate.fromJson(Map<String, dynamic> json) {
    return PHPConfigFileUpdate(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'content': content,
      };

  @override
  List<Object?> get props => [id, type, content];
}

class PHPConfigFileContent extends Equatable {
  final String path;
  final String content;

  const PHPConfigFileContent({
    this.path = '',
    this.content = '',
  });

  factory PHPConfigFileContent.fromJson(Map<String, dynamic> json) {
    return PHPConfigFileContent(
      path: json['path'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'content': content,
      };

  @override
  List<Object?> get props => [path, content];
}

