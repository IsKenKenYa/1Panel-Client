import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum TransferType { upload }

enum TransferStatus {
  pending,
  running,
  paused,
  completed,
  failed,
  cancelled,
}

class TransferTask extends Equatable {
  final String id;
  final String path;
  final String? fileName;
  final int totalSize;
  final int transferredSize;
  final TransferType type;
  final TransferStatus status;
  final int totalChunks;
  final int completedChunks;
  final Set<int> uploadedChunks;
  final String? error;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final double? speed;
  final int? eta;
  final String? localPath;

  const TransferTask({
    required this.id,
    required this.path,
    this.fileName,
    required this.totalSize,
    this.transferredSize = 0,
    required this.type,
    this.status = TransferStatus.pending,
    this.totalChunks = 0,
    this.completedChunks = 0,
    this.uploadedChunks = const {},
    this.error,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.speed,
    this.eta,
    this.localPath,
  });

  double get progress => totalSize > 0 ? transferredSize / totalSize : 0;

  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  bool get isResumable =>
      status == TransferStatus.paused || status == TransferStatus.failed;

  bool get isActive =>
      status == TransferStatus.running || status == TransferStatus.pending;

  TransferTask copyWith({
    String? id,
    String? path,
    String? fileName,
    int? totalSize,
    int? transferredSize,
    TransferType? type,
    TransferStatus? status,
    int? totalChunks,
    int? completedChunks,
    Set<int>? uploadedChunks,
    String? error,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    double? speed,
    int? eta,
    String? localPath,
  }) {
    return TransferTask(
      id: id ?? this.id,
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      totalSize: totalSize ?? this.totalSize,
      transferredSize: transferredSize ?? this.transferredSize,
      type: type ?? this.type,
      status: status ?? this.status,
      totalChunks: totalChunks ?? this.totalChunks,
      completedChunks: completedChunks ?? this.completedChunks,
      uploadedChunks: uploadedChunks ?? this.uploadedChunks,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      localPath: localPath ?? this.localPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'fileName': fileName,
      'totalSize': totalSize,
      'transferredSize': transferredSize,
      'type': type.index,
      'status': status.index,
      'totalChunks': totalChunks,
      'completedChunks': completedChunks,
      'uploadedChunks': uploadedChunks.toList(),
      'error': error,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'localPath': localPath,
    };
  }

  factory TransferTask.fromJson(Map<String, dynamic> json) {
    return TransferTask(
      id: json['id'] as String,
      path: json['path'] as String,
      fileName: json['fileName'] as String?,
      totalSize: json['totalSize'] as int,
      transferredSize: json['transferredSize'] as int? ?? 0,
      type: TransferType.values[json['type'] as int],
      status: TransferStatus.values[json['status'] as int],
      totalChunks: json['totalChunks'] as int? ?? 0,
      completedChunks: json['completedChunks'] as int? ?? 0,
      uploadedChunks: Set<int>.from(json['uploadedChunks'] as List? ?? []),
      error: json['error'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      localPath: json['localPath'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        path,
        fileName,
        totalSize,
        transferredSize,
        type,
        status,
        totalChunks,
        completedChunks,
        uploadedChunks,
        error,
        createdAt,
        startedAt,
        completedAt,
        speed,
        eta,
        localPath,
      ];
}

class ChunkInfo extends Equatable {
  final int index;
  final int start;
  final int end;
  final int size;
  final Uint8List? data;
  final String? checksum;
  final bool isUploaded;

  const ChunkInfo({
    required this.index,
    required this.start,
    required this.end,
    required this.size,
    this.data,
    this.checksum,
    this.isUploaded = false,
  });

  ChunkInfo copyWith({
    int? index,
    int? start,
    int? end,
    int? size,
    Uint8List? data,
    String? checksum,
    bool? isUploaded,
  }) {
    return ChunkInfo(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      size: size ?? this.size,
      data: data ?? this.data,
      checksum: checksum ?? this.checksum,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }

  @override
  List<Object?> get props =>
      [index, start, end, size, data, checksum, isUploaded];
}
