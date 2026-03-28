import 'package:equatable/equatable.dart';

class FileBatchResult extends Equatable {
  final bool success;
  final int successCount;
  final int failureCount;
  final List<String>? errors;
  final List<String>? processedPaths;

  const FileBatchResult({
    required this.success,
    required this.successCount,
    required this.failureCount,
    this.errors,
    this.processedPaths,
  });

  factory FileBatchResult.fromJson(Map<String, dynamic> json) {
    return FileBatchResult(
      success: json['success'] as bool? ?? false,
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      errors: (json['errors'] as List?)?.cast<String>(),
      processedPaths: (json['processedPaths'] as List?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'successCount': successCount,
      'failureCount': failureCount,
      'errors': errors,
      'processedPaths': processedPaths,
    };
  }

  @override
  List<Object?> get props =>
      [success, successCount, failureCount, errors, processedPaths];
}
