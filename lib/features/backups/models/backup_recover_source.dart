import 'package:equatable/equatable.dart';

class BackupRecoverSource extends Equatable {
  const BackupRecoverSource({
    required this.category,
    required this.recordType,
    required this.requestType,
    required this.name,
    required this.detailName,
    required this.databaseType,
    required this.supportsRecoverAction,
  });

  final String category;
  final String recordType;
  final String requestType;
  final String name;
  final String detailName;
  final String databaseType;
  final bool supportsRecoverAction;

  bool get hasSelection =>
      name.trim().isNotEmpty && detailName.trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[
        category,
        recordType,
        requestType,
        name,
        detailName,
        databaseType,
        supportsRecoverAction,
      ];
}
