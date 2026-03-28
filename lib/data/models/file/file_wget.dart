import 'package:equatable/equatable.dart';

class FileWgetRequest extends Equatable {
  final String url;
  final String path;
  final String name;
  final bool? ignoreCertificate;

  const FileWgetRequest({
    required this.url,
    required this.path,
    required this.name,
    this.ignoreCertificate,
  });

  factory FileWgetRequest.fromJson(Map<String, dynamic> json) {
    return FileWgetRequest(
      url: json['url'] as String,
      path: json['path'] as String,
      name: json['name'] as String,
      ignoreCertificate: json['ignoreCertificate'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'path': path,
      'name': name,
      if (ignoreCertificate != null) 'ignoreCertificate': ignoreCertificate,
    };
  }

  @override
  List<Object?> get props => [url, path, name, ignoreCertificate];
}

class FileWgetResult extends Equatable {
  final bool success;
  final String? filePath;
  final String? error;
  final int? downloadedSize;
  final String? checksum;
  final String? key;

  const FileWgetResult({
    required this.success,
    this.filePath,
    this.error,
    this.downloadedSize,
    this.checksum,
    this.key,
  });

  factory FileWgetResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final hasKey = data['key'] != null;
    return FileWgetResult(
      success: data['success'] as bool? ?? hasKey,
      filePath: data['filePath'] as String? ?? data['path'] as String?,
      error: data['error'] as String? ?? data['message'] as String?,
      downloadedSize: data['downloadedSize'] as int? ?? data['size'] as int?,
      checksum: data['checksum'] as String?,
      key: data['key'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'filePath': filePath,
      'error': error,
      'downloadedSize': downloadedSize,
      'checksum': checksum,
      'key': key,
    };
  }

  @override
  List<Object?> get props =>
      [success, filePath, error, downloadedSize, checksum, key];
}
