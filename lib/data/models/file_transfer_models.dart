import 'package:equatable/equatable.dart';

/// Upload type enumeration
enum UploadType {
  file('file'),
  chunk('chunk'),
  multipart('multipart');

  const UploadType(this.value);
  final String value;

  static UploadType fromString(String value) {
    return UploadType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UploadType.file,
    );
  }
}

/// Upload status enumeration
enum UploadStatus {
  pending('pending'),
  uploading('uploading'),
  paused('paused'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const UploadStatus(this.value);
  final String value;

  static UploadStatus fromString(String value) {
    return UploadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UploadStatus.pending,
    );
  }
}

/// File upload request model
class FileUploadRequest extends Equatable {
  final String fileName;
  final String filePath;
  final int fileSize;
  final String? checksum;
  final UploadType? uploadType;
  final int? chunkSize;
  final String? overwrite;
  final Map<String, dynamic>? metadata;

  const FileUploadRequest({
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.checksum,
    this.uploadType,
    this.chunkSize,
    this.overwrite,
    this.metadata,
  });

  factory FileUploadRequest.fromJson(Map<String, dynamic> json) {
    return FileUploadRequest(
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      fileSize: json['fileSize'] as int,
      checksum: json['checksum'] as String?,
      uploadType: json['uploadType'] != null
          ? UploadType.fromString(json['uploadType'] as String)
          : null,
      chunkSize: json['chunkSize'] as int?,
      overwrite: json['overwrite'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'checksum': checksum,
      'uploadType': uploadType?.value,
      'chunkSize': chunkSize,
      'overwrite': overwrite,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        fileName,
        filePath,
        fileSize,
        checksum,
        uploadType,
        chunkSize,
        overwrite,
        metadata
      ];
}

/// File upload info model
class FileUploadInfo extends Equatable {
  final String? uploadId;
  final String? fileName;
  final String? filePath;
  final int? fileSize;
  final int? uploadedSize;
  final double? progress;
  final UploadStatus? status;
  final String? checksum;
  final int? chunkSize;
  final int? totalChunks;
  final int? uploadedChunks;
  final String? startTime;
  final String? endTime;
  final int? speed;
  final String? error;
  final Map<String, dynamic>? metadata;

  const FileUploadInfo({
    this.uploadId,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.uploadedSize,
    this.progress,
    this.status,
    this.checksum,
    this.chunkSize,
    this.totalChunks,
    this.uploadedChunks,
    this.startTime,
    this.endTime,
    this.speed,
    this.error,
    this.metadata,
  });

  factory FileUploadInfo.fromJson(Map<String, dynamic> json) {
    return FileUploadInfo(
      uploadId: json['uploadId'] as String?,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      fileSize: json['fileSize'] as int?,
      uploadedSize: json['uploadedSize'] as int?,
      progress: (json['progress'] as num?)?.toDouble(),
      status: json['status'] != null
          ? UploadStatus.fromString(json['status'] as String)
          : null,
      checksum: json['checksum'] as String?,
      chunkSize: json['chunkSize'] as int?,
      totalChunks: json['totalChunks'] as int?,
      uploadedChunks: json['uploadedChunks'] as int?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      speed: json['speed'] as int?,
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'fileName': fileName,
      'filePath': filePath,
      'fileSize': fileSize,
      'uploadedSize': uploadedSize,
      'progress': progress,
      'status': status?.value,
      'checksum': checksum,
      'chunkSize': chunkSize,
      'totalChunks': totalChunks,
      'uploadedChunks': uploadedChunks,
      'startTime': startTime,
      'endTime': endTime,
      'speed': speed,
      'error': error,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        uploadId,
        fileName,
        filePath,
        fileSize,
        uploadedSize,
        progress,
        status,
        checksum,
        chunkSize,
        totalChunks,
        uploadedChunks,
        startTime,
        endTime,
        speed,
        error,
        metadata
      ];
}

/// Chunk upload request model
class ChunkUploadRequest extends Equatable {
  final String uploadId;
  final int chunkIndex;
  final String chunkData;
  final String? chunkChecksum;
  final int? chunkSize;

  const ChunkUploadRequest({
    required this.uploadId,
    required this.chunkIndex,
    required this.chunkData,
    this.chunkChecksum,
    this.chunkSize,
  });

  factory ChunkUploadRequest.fromJson(Map<String, dynamic> json) {
    return ChunkUploadRequest(
      uploadId: json['uploadId'] as String,
      chunkIndex: json['chunkIndex'] as int,
      chunkData: json['chunkData'] as String,
      chunkChecksum: json['chunkChecksum'] as String?,
      chunkSize: json['chunkSize'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uploadId': uploadId,
      'chunkIndex': chunkIndex,
      'chunkData': chunkData,
      'chunkChecksum': chunkChecksum,
      'chunkSize': chunkSize,
    };
  }

  @override
  List<Object?> get props =>
      [uploadId, chunkIndex, chunkData, chunkChecksum, chunkSize];
}

/// File download request model
class FileDownloadRequest extends Equatable {
  final String filePath;
  final String? savePath;
  final bool? forceDownload;
  final bool? checkIntegrity;
  final Map<String, dynamic>? metadata;

  const FileDownloadRequest({
    required this.filePath,
    this.savePath,
    this.forceDownload,
    this.checkIntegrity,
    this.metadata,
  });

  factory FileDownloadRequest.fromJson(Map<String, dynamic> json) {
    return FileDownloadRequest(
      filePath: json['filePath'] as String,
      savePath: json['savePath'] as String?,
      forceDownload: json['forceDownload'] as bool?,
      checkIntegrity: json['checkIntegrity'] as bool?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'savePath': savePath,
      'forceDownload': forceDownload,
      'checkIntegrity': checkIntegrity,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props =>
      [filePath, savePath, forceDownload, checkIntegrity, metadata];
}

/// File download info model
class FileDownloadInfo extends Equatable {
  final String? downloadId;
  final String? filePath;
  final String? savePath;
  final int? fileSize;
  final int? downloadedSize;
  final double? progress;
  final String? status;
  final String? checksum;
  final String? startTime;
  final String? endTime;
  final int? speed;
  final String? error;
  final Map<String, dynamic>? metadata;

  const FileDownloadInfo({
    this.downloadId,
    this.filePath,
    this.savePath,
    this.fileSize,
    this.downloadedSize,
    this.progress,
    this.status,
    this.checksum,
    this.startTime,
    this.endTime,
    this.speed,
    this.error,
    this.metadata,
  });

  factory FileDownloadInfo.fromJson(Map<String, dynamic> json) {
    return FileDownloadInfo(
      downloadId: json['downloadId'] as String?,
      filePath: json['filePath'] as String?,
      savePath: json['savePath'] as String?,
      fileSize: json['fileSize'] as int?,
      downloadedSize: json['downloadedSize'] as int?,
      progress: (json['progress'] as num?)?.toDouble(),
      status: json['status'] as String?,
      checksum: json['checksum'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      speed: json['speed'] as int?,
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'downloadId': downloadId,
      'filePath': filePath,
      'savePath': savePath,
      'fileSize': fileSize,
      'downloadedSize': downloadedSize,
      'progress': progress,
      'status': status,
      'checksum': checksum,
      'startTime': startTime,
      'endTime': endTime,
      'speed': speed,
      'error': error,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        downloadId,
        filePath,
        savePath,
        fileSize,
        downloadedSize,
        progress,
        status,
        checksum,
        startTime,
        endTime,
        speed,
        error,
        metadata
      ];
}

/// Transfer operation model
class TransferOperation extends Equatable {
  final List<String> transferIds;
  final String operation;

  const TransferOperation({
    required this.transferIds,
    required this.operation,
  });

  factory TransferOperation.fromJson(Map<String, dynamic> json) {
    return TransferOperation(
      transferIds:
          (json['transferIds'] as List?)?.map((e) => e as String).toList() ??
              [],
      operation: json['operation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transferIds': transferIds,
      'operation': operation,
    };
  }

  @override
  List<Object?> get props => [transferIds, operation];
}

/// Transfer statistics model
class TransferStats extends Equatable {
  final int? activeUploads;
  final int? activeDownloads;
  final int? completedUploads;
  final int? completedDownloads;
  final int? failedTransfers;
  final int? totalUploadSpeed;
  final int? totalDownloadSpeed;
  final int? totalUploaded;
  final int? totalDownloaded;

  const TransferStats({
    this.activeUploads,
    this.activeDownloads,
    this.completedUploads,
    this.completedDownloads,
    this.failedTransfers,
    this.totalUploadSpeed,
    this.totalDownloadSpeed,
    this.totalUploaded,
    this.totalDownloaded,
  });

  factory TransferStats.fromJson(Map<String, dynamic> json) {
    return TransferStats(
      activeUploads: json['activeUploads'] as int?,
      activeDownloads: json['activeDownloads'] as int?,
      completedUploads: json['completedUploads'] as int?,
      completedDownloads: json['completedDownloads'] as int?,
      failedTransfers: json['failedTransfers'] as int?,
      totalUploadSpeed: json['totalUploadSpeed'] as int?,
      totalDownloadSpeed: json['totalDownloadSpeed'] as int?,
      totalUploaded: json['totalUploaded'] as int?,
      totalDownloaded: json['totalDownloaded'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activeUploads': activeUploads,
      'activeDownloads': activeDownloads,
      'completedUploads': completedUploads,
      'completedDownloads': completedDownloads,
      'failedTransfers': failedTransfers,
      'totalUploadSpeed': totalUploadSpeed,
      'totalDownloadSpeed': totalDownloadSpeed,
      'totalUploaded': totalUploaded,
      'totalDownloaded': totalDownloaded,
    };
  }

  @override
  List<Object?> get props => [
        activeUploads,
        activeDownloads,
        completedUploads,
        completedDownloads,
        failedTransfers,
        totalUploadSpeed,
        totalDownloadSpeed,
        totalUploaded,
        totalDownloaded
      ];
}
