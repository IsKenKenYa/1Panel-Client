import 'package:equatable/equatable.dart';

class BackupAccountDraft extends Equatable {
  const BackupAccountDraft({
    this.id,
    this.name = '',
    this.type = 'LOCAL',
    this.isPublic = false,
    this.accessKey = '',
    this.credential = '',
    this.bucket = '',
    this.backupPath = '',
    this.rememberAuth = false,
    this.manualBucketInput = true,
    this.vars = const <String, dynamic>{},
  });

  final int? id;
  final String name;
  final String type;
  final bool isPublic;
  final String accessKey;
  final String credential;
  final String bucket;
  final String backupPath;
  final bool rememberAuth;
  final bool manualBucketInput;
  final Map<String, dynamic> vars;

  bool get isEditing => id != null;

  BackupAccountDraft copyWith({
    int? id,
    String? name,
    String? type,
    bool? isPublic,
    String? accessKey,
    String? credential,
    String? bucket,
    String? backupPath,
    bool? rememberAuth,
    bool? manualBucketInput,
    Map<String, dynamic>? vars,
  }) {
    return BackupAccountDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isPublic: isPublic ?? this.isPublic,
      accessKey: accessKey ?? this.accessKey,
      credential: credential ?? this.credential,
      bucket: bucket ?? this.bucket,
      backupPath: backupPath ?? this.backupPath,
      rememberAuth: rememberAuth ?? this.rememberAuth,
      manualBucketInput: manualBucketInput ?? this.manualBucketInput,
      vars: vars ?? this.vars,
    );
  }

  String stringVar(String key) => vars[key]?.toString() ?? '';

  bool boolVar(String key, {bool defaultValue = false}) {
    final value = vars[key];
    return value is bool ? value : defaultValue;
  }

  int intVar(String key, {int defaultValue = 0}) {
    final value = vars[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        isPublic,
        accessKey,
        credential,
        bucket,
        backupPath,
        rememberAuth,
        manualBucketInput,
        vars,
      ];
}
