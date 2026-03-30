import 'package:equatable/equatable.dart';

class FileMediaConvertItem extends Equatable {
  final String path;
  final String type;
  final String inputFile;
  final String extension;
  final String outputFormat;

  const FileMediaConvertItem({
    required this.path,
    required this.type,
    required this.inputFile,
    required this.extension,
    required this.outputFormat,
  });

  factory FileMediaConvertItem.fromJson(Map<String, dynamic> json) {
    return FileMediaConvertItem(
      path: json['path'] as String,
      type: json['type'] as String,
      inputFile: json['inputFile'] as String,
      extension: json['extension'] as String,
      outputFormat: json['outputFormat'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'type': type,
      'inputFile': inputFile,
      'extension': extension,
      'outputFormat': outputFormat,
    };
  }

  @override
  List<Object?> get props => [path, type, inputFile, extension, outputFormat];
}

class FileMediaConvertRequest extends Equatable {
  final List<FileMediaConvertItem> files;
  final String outputPath;
  final bool deleteSource;
  final String? taskID;

  const FileMediaConvertRequest({
    required this.files,
    required this.outputPath,
    this.deleteSource = false,
    this.taskID,
  });

  factory FileMediaConvertRequest.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    return FileMediaConvertRequest(
      files: rawFiles is List
          ? rawFiles
              .map((item) =>
                  FileMediaConvertItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : const <FileMediaConvertItem>[],
      outputPath: json['outputPath'] as String,
      deleteSource: json['deleteSource'] as bool? ?? false,
      taskID: json['taskID'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'files': files.map((file) => file.toJson()).toList(),
      'outputPath': outputPath,
      'deleteSource': deleteSource,
      if (taskID != null && taskID!.isNotEmpty) 'taskID': taskID,
    };
  }

  @override
  List<Object?> get props => [files, outputPath, deleteSource, taskID];
}
