import 'package:equatable/equatable.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';

class BackupRecordListItem extends Equatable {
  const BackupRecordListItem({
    required this.record,
    this.size,
  });

  final BackupRecord record;
  final int? size;

  BackupRecordListItem copyWith({
    BackupRecord? record,
    int? size,
  }) {
    return BackupRecordListItem(
      record: record ?? this.record,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => <Object?>[record, size];
}
