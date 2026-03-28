import 'package:equatable/equatable.dart';

class FileTreeRequest extends Equatable {
  final String path;
  final int? maxDepth;
  final bool? includeFiles;
  final bool? includeHidden;
  final List<String>? excludePatterns;

  const FileTreeRequest({
    required this.path,
    this.maxDepth,
    this.includeFiles,
    this.includeHidden,
    this.excludePatterns,
  });

  factory FileTreeRequest.fromJson(Map<String, dynamic> json) {
    return FileTreeRequest(
      path: json['path'] as String,
      maxDepth: json['maxDepth'] as int?,
      includeFiles: json['includeFiles'] as bool?,
      includeHidden: json['includeHidden'] as bool?,
      excludePatterns: (json['excludePatterns'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'maxDepth': maxDepth,
      'includeFiles': includeFiles,
      'includeHidden': includeHidden,
      'excludePatterns': excludePatterns,
    };
  }

  @override
  List<Object?> get props =>
      [path, maxDepth, includeFiles, includeHidden, excludePatterns];
}

class FileTree extends Equatable {
  final String path;
  final String name;
  final String type;
  final int size;
  final List<FileTree>? children;
  final int depth;

  const FileTree({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    this.children,
    required this.depth,
  });

  factory FileTree.fromJson(Map<String, dynamic> json) {
    final path = _resolvePath(json);
    final childrenJson = json['children'] as List?;
    return FileTree(
      path: path,
      name: _resolveName(json, path),
      type: _resolveType(json, childrenJson),
      size: json['size'] as int? ?? 0,
      children: childrenJson
          ?.map((item) => FileTree.fromJson(item as Map<String, dynamic>))
          .toList(),
      depth: json['depth'] as int? ?? 0,
    );
  }

  static String _resolvePath(Map<String, dynamic> json) {
    final pathValue = json['path'];
    if (pathValue is String) {
      return pathValue;
    }
    final nameValue = json['name'];
    if (nameValue is String) {
      return nameValue;
    }
    return '';
  }

  static String _resolveName(Map<String, dynamic> json, String path) {
    final nameValue = json['name'];
    if (nameValue is String && nameValue.isNotEmpty) {
      return nameValue;
    }
    if (path.isEmpty) {
      return '';
    }
    final segments = path.split('/');
    for (var i = segments.length - 1; i >= 0; i--) {
      final segment = segments[i];
      if (segment.isNotEmpty) {
        return segment;
      }
    }
    return path;
  }

  static String _resolveType(Map<String, dynamic> json, List? childrenJson) {
    final typeValue = json['type'];
    if (typeValue is String && typeValue.isNotEmpty) {
      return typeValue;
    }
    if (childrenJson != null && childrenJson.isNotEmpty) {
      return 'dir';
    }
    return 'file';
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'type': type,
      'size': size,
      'children': children?.map((item) => item.toJson()).toList(),
      'depth': depth,
    };
  }

  @override
  List<Object?> get props => [path, name, type, size, children, depth];
}
