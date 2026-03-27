import 'dart:typed_data';

import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/data/models/backup_account_models.dart';
import 'package:onepanel_client/data/models/backup_request_models.dart';
import 'package:onepanel_client/data/repositories/backup_repository.dart';
import 'package:onepanel_client/features/backups/models/backup_record_list_item.dart';
import 'package:onepanel_client/features/backups/models/backup_records_args.dart';

class BackupRecordService {
  BackupRecordService({
    BackupRepository? repository,
    FileSaveService? fileSaveService,
  })  : _repository = repository ?? BackupRepository(),
        _fileSaveService = fileSaveService ?? FileSaveService();

  final BackupRepository _repository;
  final FileSaveService _fileSaveService;

  Future<List<BackupRecordListItem>> loadRecords({
    BackupRecordsArgs? args,
    String type = 'app',
    String name = '',
    String detailName = '',
  }) async {
    final records = args?.cronjobId != null
        ? await _repository.searchRecordsByCronjob(
            BackupRecordByCronjobQuery(cronjobID: args!.cronjobId!),
          )
        : await _repository.searchRecords(
            BackupRecordQuery(
              type: type,
              name: name,
              detailName: detailName,
            ),
          );
    final sizeQuery = args?.cronjobId != null
        ? BackupRecordSizeQuery(type: 'cronjob', cronjobID: args!.cronjobId)
        : BackupRecordSizeQuery(type: type, name: name, detailName: detailName);
    final sizes = await _repository.loadRecordSizes(sizeQuery);
    final sizeMap = <int, int>{};
    for (final item in sizes) {
      sizeMap[item.id] = item.size;
    }
    return records.items
        .map(
          (record) => BackupRecordListItem(
            record: record,
            size: record.id == null ? null : sizeMap[record.id!],
          ),
        )
        .toList(growable: false);
  }

  Future<FileSaveResult> downloadRecord(BackupRecord record) async {
    final path = await _repository.requestDownloadPath(
      DownloadRecord(
        downloadAccountID: record.downloadAccountID ?? 0,
        fileDir: record.fileDir ?? '',
        fileName: record.fileName ?? '',
      ),
    );
    if (path.trim().isEmpty) {
      throw Exception('Backup record path is empty');
    }
    final bytes = await _repository.downloadFile(path);
    if (bytes.isEmpty) {
      throw Exception('Downloaded backup record is empty');
    }
    return _fileSaveService.saveFile(
      fileName: record.fileName ?? 'backup-record',
      bytes: Uint8List.fromList(bytes),
    );
  }

  Future<void> deleteRecord(BackupRecord record) {
    return _repository.deleteRecords(<int>[record.id ?? 0]);
  }

  Future<List<String>> listFiles(int accountId) {
    return _repository.listFiles(accountId);
  }
}
