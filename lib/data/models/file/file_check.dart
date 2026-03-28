import 'package:equatable/equatable.dart';

class FileCheck extends Equatable {
  final String path;
  final bool? checkExists;
  final bool? checkReadable;
  final bool? checkWritable;

  const FileCheck({
    required this.path,
    this.checkExists,
    this.checkReadable,
    this.checkWritable,
  });

  factory FileCheck.fromJson(Map<String, dynamic> json) {
    return FileCheck(
      path: json['path'] as String,
      checkExists: json['checkExists'] as bool?,
      checkReadable: json['checkReadable'] as bool?,
      checkWritable: json['checkWritable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'checkExists': checkExists,
      'checkReadable': checkReadable,
      'checkWritable': checkWritable,
    };
  }

  @override
  List<Object?> get props => [path, checkExists, checkReadable, checkWritable];
}

class FileCheckResult extends Equatable {
  final String? path;
  final bool exists;
  final bool readable;
  final bool writable;
  final bool isDirectory;
  final bool isFile;
  final int? size;
  final String? lastModified;

  const FileCheckResult({
    this.path,
    required this.exists,
    required this.readable,
    required this.writable,
    required this.isDirectory,
    required this.isFile,
    this.size,
    this.lastModified,
  });

  factory FileCheckResult.fromJson(Map<String, dynamic> json) {
    return FileCheckResult(
      path: json['path'] as String?,
      exists: json['exists'] as bool? ?? false,
      readable: json['readable'] as bool? ?? false,
      writable: json['writable'] as bool? ?? false,
      isDirectory:
          json['isDir'] as bool? ?? json['isDirectory'] as bool? ?? false,
      isFile: json['isFile'] as bool? ?? false,
      size: json['size'] as int?,
      lastModified: json['lastModified'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'exists': exists,
      'readable': readable,
      'writable': writable,
      'isDirectory': isDirectory,
      'isFile': isFile,
      'size': size,
      'lastModified': lastModified,
    };
  }

  @override
  List<Object?> get props => [
        path,
        exists,
        readable,
        writable,
        isDirectory,
        isFile,
        size,
        lastModified
      ];
}

class FileBatchCheckRequest extends Equatable {
  final List<String> paths;

  const FileBatchCheckRequest({
    required this.paths,
  });

  factory FileBatchCheckRequest.fromJson(Map<String, dynamic> json) {
    return FileBatchCheckRequest(
      paths: (json['paths'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paths': paths,
    };
  }

  @override
  List<Object?> get props => [paths];
}

class FileBatchCheckResult extends Equatable {
  final Map<String, FileCheckResult> results;

  const FileBatchCheckResult({
    required this.results,
  });

  factory FileBatchCheckResult.fromJson(Map<String, dynamic> json) {
    final resultsMap = <String, FileCheckResult>{};
    if (json['results'] is Map) {
      (json['results'] as Map).forEach((key, value) {
        if (value is Map<String, dynamic>) {
          resultsMap[key.toString()] = FileCheckResult.fromJson(value);
        }
      });
    }
    return FileBatchCheckResult(results: resultsMap);
  }

  Map<String, dynamic> toJson() {
    return {
      'results': results.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  @override
  List<Object?> get props => [results];
}
