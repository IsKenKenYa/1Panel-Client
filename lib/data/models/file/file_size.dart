import 'package:equatable/equatable.dart';

class FileSizeRequest extends Equatable {
  final String path;
  final bool? recursive;
  final bool? includeHidden;

  const FileSizeRequest({
    required this.path,
    this.recursive,
    this.includeHidden,
  });

  factory FileSizeRequest.fromJson(Map<String, dynamic> json) {
    return FileSizeRequest(
      path: json['path'] as String,
      recursive: json['recursive'] as bool?,
      includeHidden: json['includeHidden'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'recursive': recursive,
      'includeHidden': includeHidden,
    };
  }

  @override
  List<Object?> get props => [path, recursive, includeHidden];
}

class FileSizeInfo extends Equatable {
  final String? path;
  final int totalSize;
  final int fileCount;
  final int directoryCount;
  final Map<String, int>? sizeByType;

  const FileSizeInfo({
    this.path,
    required this.totalSize,
    required this.fileCount,
    required this.directoryCount,
    this.sizeByType,
  });

  factory FileSizeInfo.fromJson(Map<String, dynamic> json) {
    return FileSizeInfo(
      path: json['path'] as String?,
      totalSize: json['totalSize'] as int? ?? json['size'] as int? ?? 0,
      fileCount: json['fileCount'] as int? ?? 0,
      directoryCount:
          json['directoryCount'] as int? ?? json['dirCount'] as int? ?? 0,
      sizeByType: (json['sizeByType'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, value as int),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'totalSize': totalSize,
      'fileCount': fileCount,
      'directoryCount': directoryCount,
      'sizeByType': sizeByType,
    };
  }

  @override
  List<Object?> get props =>
      [path, totalSize, fileCount, directoryCount, sizeByType];
}

class FileDepthSizeRequest extends Equatable {
  final List<String> paths;

  const FileDepthSizeRequest({
    required this.paths,
  });

  factory FileDepthSizeRequest.fromJson(Map<String, dynamic> json) {
    return FileDepthSizeRequest(
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

class FileDepthSizeInfo extends Equatable {
  final Map<String, int> sizes;
  final int totalSize;

  const FileDepthSizeInfo({
    required this.sizes,
    required this.totalSize,
  });

  factory FileDepthSizeInfo.fromJson(Map<String, dynamic> json) {
    final sizesMap = <String, int>{};
    if (json['sizes'] is Map) {
      (json['sizes'] as Map).forEach((key, value) {
        sizesMap[key.toString()] =
            (value is int) ? value : int.tryParse(value.toString()) ?? 0;
      });
    }
    return FileDepthSizeInfo(
      sizes: sizesMap,
      totalSize: json['totalSize'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sizes': sizes,
      'totalSize': totalSize,
    };
  }

  @override
  List<Object?> get props => [sizes, totalSize];
}
