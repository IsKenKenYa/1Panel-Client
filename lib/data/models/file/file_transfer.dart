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
