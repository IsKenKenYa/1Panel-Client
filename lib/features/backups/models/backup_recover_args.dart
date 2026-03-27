import 'package:onepanel_client/data/models/backup_account_models.dart';

class BackupRecoverArgs {
  const BackupRecoverArgs({
    this.initialRecord,
    this.type,
    this.name,
    this.detailName,
  });

  final BackupRecord? initialRecord;
  final String? type;
  final String? name;
  final String? detailName;
}
