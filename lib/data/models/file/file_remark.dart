import 'package:equatable/equatable.dart';

class FileRemarkBatch extends Equatable {
  final List<String> paths;

  const FileRemarkBatch({required this.paths});

  factory FileRemarkBatch.fromJson(Map<String, dynamic> json) {
    final rawPaths = json['paths'];
    return FileRemarkBatch(
      paths: rawPaths is List
          ? rawPaths.map((item) => item.toString()).toList()
          : const <String>[],
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

class FileRemarkUpdate extends Equatable {
  final String path;
  final String remark;

  const FileRemarkUpdate({
    required this.path,
    required this.remark,
  });

  factory FileRemarkUpdate.fromJson(Map<String, dynamic> json) {
    return FileRemarkUpdate(
      path: json['path'] as String,
      remark: json['remark'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'remark': remark,
    };
  }

  @override
  List<Object?> get props => [path, remark];
}

class FileRemarksResponse extends Equatable {
  final Map<String, String> remarks;

  const FileRemarksResponse({required this.remarks});

  factory FileRemarksResponse.fromJson(Map<String, dynamic> json) {
    final rawRemarks = json['remarks'];
    final remarks = <String, String>{};
    if (rawRemarks is Map) {
      rawRemarks.forEach((key, value) {
        if (key != null && value != null) {
          remarks[key.toString()] = value.toString();
        }
      });
    }

    return FileRemarksResponse(remarks: remarks);
  }

  Map<String, dynamic> toJson() {
    return {
      'remarks': remarks,
    };
  }

  @override
  List<Object?> get props => [remarks];
}
