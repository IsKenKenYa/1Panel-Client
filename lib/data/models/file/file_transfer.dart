import 'package:equatable/equatable.dart';

class FileUpload extends Equatable {
  final String path;
  final String? fileName;
  final bool? overrideExisting;

  const FileUpload({
    required this.path,
    this.fileName,
    this.overrideExisting,
  });

  factory FileUpload.fromJson(Map<String, dynamic> json) {
    return FileUpload(
      path: json['path'] as String,
      fileName: json['fileName'] as String?,
      overrideExisting: json['override'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'fileName': fileName,
      'override': overrideExisting,
    };
  }

  @override
  List<Object?> get props => [path, fileName, overrideExisting];
}

class FileDownload extends Equatable {
  final String path;
  final bool? isDownload;

  const FileDownload({
    required this.path,
    this.isDownload,
  });

  factory FileDownload.fromJson(Map<String, dynamic> json) {
    return FileDownload(
      path: json['path'] as String,
      isDownload: json['isDownload'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'isDownload': isDownload,
    };
  }

  @override
  List<Object?> get props => [path, isDownload];
}

class FileContent extends Equatable {
  final String path;
  final String? content;

  const FileContent({
    required this.path,
    this.content,
  });

  factory FileContent.fromJson(Map<String, dynamic> json) {
    return FileContent(
      path: json['path'] as String,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'content': content,
    };
  }

  @override
  List<Object?> get props => [path, content];
}

class FileChunkDownload extends Equatable {
  final String path;
  final int chunkSize;
  final int chunkNumber;
  final String? filePath;

  const FileChunkDownload({
    required this.path,
    required this.chunkSize,
    required this.chunkNumber,
    this.filePath,
  });

  factory FileChunkDownload.fromJson(Map<String, dynamic> json) {
    return FileChunkDownload(
      path: json['path'] as String,
      chunkSize: json['chunkSize'] as int,
      chunkNumber: json['chunkNumber'] as int,
      filePath: json['filePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'chunkSize': chunkSize,
      'chunkNumber': chunkNumber,
      'filePath': filePath,
    };
  }

  @override
  List<Object?> get props => [path, chunkSize, chunkNumber, filePath];
}

class FileChunkData extends Equatable {
  final String? data;
  final int chunkNumber;
  final bool isLastChunk;
  final String? checksum;

  const FileChunkData({
    this.data,
    required this.chunkNumber,
    required this.isLastChunk,
    this.checksum,
  });

  factory FileChunkData.fromJson(Map<String, dynamic> json) {
    return FileChunkData(
      data: json['data'] as String?,
      chunkNumber: json['chunkNumber'] as int,
      isLastChunk: json['isLastChunk'] as bool? ?? false,
      checksum: json['checksum'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'chunkNumber': chunkNumber,
      'isLastChunk': isLastChunk,
      'checksum': checksum,
    };
  }

  @override
  List<Object?> get props => [data, chunkNumber, isLastChunk, checksum];
}

class FileChunkUpload extends Equatable {
  final String uploadID;
  final String filename;
  final String path;
  final List<int> chunkBytes;
  final int chunkIndex;
  final int chunkCount;
  final int offset;
  final int fileSize;
  final bool overwrite;

  const FileChunkUpload({
    required this.uploadID,
    required this.filename,
    required this.path,
    required this.chunkBytes,
    required this.chunkIndex,
    required this.chunkCount,
    required this.offset,
    required this.fileSize,
    this.overwrite = true,
  });

  @override
  List<Object?> get props => [
        uploadID,
        filename,
        path,
        chunkBytes,
        chunkIndex,
        chunkCount,
        offset,
        fileSize,
        overwrite,
      ];
}

class FileChunkResult extends Equatable {
  final bool success;
  final int? totalChunks;
  final int? uploadedChunks;
  final String? message;

  const FileChunkResult({
    required this.success,
    this.totalChunks,
    this.uploadedChunks,
    this.message,
  });

  factory FileChunkResult.fromJson(Map<String, dynamic> json) {
    return FileChunkResult(
      success: json['success'] as bool? ?? false,
      totalChunks: json['totalChunks'] as int?,
      uploadedChunks: json['uploadedChunks'] as int?,
      message: json['message'] as String?,
    );
  }

  /// 解析 `/files/chunkupload` 的原始响应。
  ///
  /// 服务端成功时返回 `{code: 200, message: 'success', data: true}`，`data`
  /// 是布尔值；失败时由拦截器抛出，因此这里只按信封判定成功与否。
  factory FileChunkResult.fromPayload(dynamic payload) {
    if (payload is bool) {
      return FileChunkResult(success: payload);
    }
    if (payload is! Map) {
      return const FileChunkResult(success: false);
    }
    final map = Map<String, dynamic>.from(payload);
    final data = map['data'];
    if (data is bool) {
      return FileChunkResult(
        success: data,
        message: map['message'] as String?,
      );
    }
    if (data is Map) {
      return FileChunkResult.fromJson(Map<String, dynamic>.from(data));
    }
    return FileChunkResult.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'totalChunks': totalChunks,
      'uploadedChunks': uploadedChunks,
      'message': message,
    };
  }

  @override
  List<Object?> get props => [success, totalChunks, uploadedChunks, message];
}
