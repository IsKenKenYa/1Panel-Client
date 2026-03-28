import 'package:equatable/equatable.dart';

class RecycleBinItem extends Equatable {
  final String sourcePath;
  final String name;
  final bool isDir;
  final int size;
  final DateTime? deleteTime;
  final String rName;
  final String from;

  const RecycleBinItem({
    required this.sourcePath,
    required this.name,
    required this.isDir,
    required this.size,
    this.deleteTime,
    required this.rName,
    required this.from,
  });

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      sourcePath: json['sourcePath'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isDir: json['isDir'] as bool? ?? false,
      size: json['size'] as int? ?? 0,
      deleteTime: json['deleteTime'] != null
          ? DateTime.tryParse(json['deleteTime'] as String)
          : null,
      rName: json['rName'] as String? ?? '',
      from: json['from'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourcePath': sourcePath,
      'name': name,
      'isDir': isDir,
      'size': size,
      'deleteTime': deleteTime?.toIso8601String(),
      'rName': rName,
      'from': from,
    };
  }

  @override
  List<Object?> get props =>
      [sourcePath, name, isDir, size, deleteTime, rName, from];
}

class RecycleBinReduceRequest extends Equatable {
  final String rName;
  final String from;
  final String name;

  const RecycleBinReduceRequest({
    required this.rName,
    required this.from,
    required this.name,
  });

  factory RecycleBinReduceRequest.fromJson(Map<String, dynamic> json) {
    return RecycleBinReduceRequest(
      rName: json['rName'] as String? ?? '',
      from: json['from'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rName': rName,
      'from': from,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [rName, from, name];
}

class FileRecycleReduce extends Equatable {
  final int? days;
  final int? count;
  final bool? byDate;

  const FileRecycleReduce({
    this.days,
    this.count,
    this.byDate,
  });

  factory FileRecycleReduce.fromJson(Map<String, dynamic> json) {
    return FileRecycleReduce(
      days: json['days'] as int?,
      count: json['count'] as int?,
      byDate: json['byDate'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'count': count,
      'byDate': byDate,
    };
  }

  @override
  List<Object?> get props => [days, count, byDate];
}

class FileRecycleResult extends Equatable {
  final int deletedCount;
  final int totalSize;
  final String? message;

  const FileRecycleResult({
    required this.deletedCount,
    required this.totalSize,
    this.message,
  });

  factory FileRecycleResult.fromJson(Map<String, dynamic> json) {
    return FileRecycleResult(
      deletedCount: json['deletedCount'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deletedCount': deletedCount,
      'totalSize': totalSize,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [deletedCount, totalSize, message];
}

class FileRecycleStatus extends Equatable {
  final int fileCount;
  final int totalSize;
  final String? oldestFile;
  final String? newestFile;

  const FileRecycleStatus({
    required this.fileCount,
    required this.totalSize,
    this.oldestFile,
    this.newestFile,
  });

  factory FileRecycleStatus.fromJson(Map<String, dynamic> json) {
    return FileRecycleStatus(
      fileCount: json['fileCount'] as int? ?? 0,
      totalSize: json['totalSize'] as int? ?? 0,
      oldestFile: json['oldestFile'] as String?,
      newestFile: json['newestFile'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileCount': fileCount,
      'totalSize': totalSize,
      'oldestFile': oldestFile,
      'newestFile': newestFile,
    };
  }

  @override
  List<Object?> get props => [fileCount, totalSize, oldestFile, newestFile];
}
