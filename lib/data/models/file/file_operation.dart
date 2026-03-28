import 'package:equatable/equatable.dart';

class FileDelete extends Equatable {
  final String path;
  final bool? isDir;
  final bool? forceDelete;

  const FileDelete({
    required this.path,
    this.isDir,
    this.forceDelete,
  });

  factory FileDelete.fromJson(Map<String, dynamic> json) {
    return FileDelete(
      path: json['path'] as String? ?? '',
      isDir: json['isDir'] as bool?,
      forceDelete: json['forceDelete'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'path': path};
    if (isDir != null) json['isDir'] = isDir;
    if (forceDelete != null) json['forceDelete'] = forceDelete;
    return json;
  }

  @override
  List<Object?> get props => [path, isDir, forceDelete];
}

class FileBatchDelete extends Equatable {
  final List<String> paths;
  final bool? isDir;

  const FileBatchDelete({
    required this.paths,
    this.isDir,
  });

  factory FileBatchDelete.fromJson(Map<String, dynamic> json) {
    return FileBatchDelete(
      paths: (json['paths'] as List?)?.cast<String>() ?? [],
      isDir: json['isDir'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'paths': paths};
    if (isDir != null) json['isDir'] = isDir;
    return json;
  }

  @override
  List<Object?> get props => [paths, isDir];
}

class FileOperate extends Equatable {
  final List<String> paths;
  final bool? force;

  const FileOperate({
    required this.paths,
    this.force,
  });

  factory FileOperate.fromJson(Map<String, dynamic> json) {
    return FileOperate(
      paths: (json['paths'] as List?)?.cast<String>() ?? [],
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'paths': paths};
    if (force != null) json['force'] = force;
    return json;
  }

  @override
  List<Object?> get props => [paths, force];
}

class FileRename extends Equatable {
  final String oldPath;
  final String newPath;

  const FileRename({
    required this.oldPath,
    required this.newPath,
  });

  factory FileRename.fromJson(Map<String, dynamic> json) {
    return FileRename(
      oldPath: json['oldName'] as String? ?? json['oldPath'] as String? ?? '',
      newPath: json['newName'] as String? ?? json['newPath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oldName': oldPath,
      'newName': newPath,
    };
  }

  @override
  List<Object?> get props => [oldPath, newPath];
}

class FileMove extends Equatable {
  final List<String> paths;
  final String targetPath;
  final String? type;
  final String? name;
  final bool? cover;

  const FileMove({
    required this.paths,
    required this.targetPath,
    this.type,
    this.name,
    this.cover,
  });

  factory FileMove.fromJson(Map<String, dynamic> json) {
    return FileMove(
      paths: (json['oldPaths'] as List?)?.cast<String>() ??
          (json['paths'] as List?)?.cast<String>() ??
          [],
      targetPath:
          json['newPath'] as String? ?? json['targetPath'] as String? ?? '',
      type: json['type'] as String?,
      name: json['name'] as String?,
      cover: json['cover'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'oldPaths': paths,
      'newPath': targetPath,
    };
    json['type'] = type ?? 'cut';
    if (name != null) json['name'] = name;
    if (cover != null) json['cover'] = cover;
    return json;
  }

  @override
  List<Object?> get props => [paths, targetPath, type, name, cover];
}

class FileCopy extends Equatable {
  final List<String> paths;
  final String targetPath;

  const FileCopy({
    required this.paths,
    required this.targetPath,
  });

  factory FileCopy.fromJson(Map<String, dynamic> json) {
    return FileCopy(
      paths: (json['paths'] as List?)?.cast<String>() ?? [],
      targetPath: json['targetPath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paths': paths,
      'targetPath': targetPath,
    };
  }

  @override
  List<Object?> get props => [paths, targetPath];
}

class FileBatchOperate extends Equatable {
  final List<String> paths;
  final String operation;
  final bool? force;

  const FileBatchOperate({
    required this.paths,
    required this.operation,
    this.force,
  });

  factory FileBatchOperate.fromJson(Map<String, dynamic> json) {
    return FileBatchOperate(
      paths: (json['paths'] as List?)?.cast<String>() ?? [],
      operation: json['operation'] as String,
      force: json['force'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paths': paths,
      'operation': operation,
      'force': force,
    };
  }

  @override
  List<Object?> get props => [paths, operation, force];
}
