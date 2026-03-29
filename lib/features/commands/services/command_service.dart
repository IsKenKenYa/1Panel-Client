import 'dart:typed_data';
import 'dart:convert';

import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/command_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/data/repositories/command_repository.dart';
import 'package:onepanel_client/features/group/services/group_service.dart';

class CommandService {
  CommandService({
    CommandRepository? repository,
    GroupService? groupService,
    ApiClientManager? clientManager,
    FileSaveService? fileSaveService,
  })  : _repository = repository ?? CommandRepository(),
        _groupService = groupService ?? GroupService(),
        _clientManager = clientManager ?? ApiClientManager.instance,
        _fileSaveService = fileSaveService ?? FileSaveService();

  final CommandRepository _repository;
  final GroupService _groupService;
  final ApiClientManager _clientManager;
  final FileSaveService _fileSaveService;

  Future<PageResult<CommandInfo>> searchCommands(
    CommandSearchRequest request,
  ) {
    return _repository.searchCommands(request);
  }

  Future<List<GroupInfo>> loadGroups({bool forceRefresh = false}) {
    return _groupService.listGroups('command', forceRefresh: forceRefresh);
  }

  Future<void> createCommand(CommandOperate request) {
    return _repository.createCommand(request);
  }

  Future<void> updateCommand(CommandOperate request) {
    return _repository.updateCommand(request);
  }

  Future<void> deleteCommands(List<int> ids) {
    return _repository.deleteCommands(ids);
  }

  Future<List<CommandInfo>> parseImportPreviewCsv({
    required Uint8List bytes,
    required String fileName,
  }) async {
    appLogger.dWithPackage(
      'features.commands.services.command',
      'parseImportPreviewCsv: fileName=$fileName, bytes=${bytes.length}',
    );

    if (bytes.isEmpty) {
      return const <CommandInfo>[];
    }

    final content = utf8.decode(bytes, allowMalformed: true).replaceFirst(
          '\uFEFF',
          '',
        );
    final rows = _parseCsvRows(content);
    if (rows.isEmpty) {
      return const <CommandInfo>[];
    }

    final headerIndex = _buildHeaderIndex(rows.first);
    final nameIndex = headerIndex['name'];
    final commandIndex = headerIndex['command'];
    if (nameIndex == null || commandIndex == null) {
      throw const FormatException('CSV must contain name and command columns');
    }

    final typeIndex = headerIndex['type'];
    final groupBelongIndex = headerIndex['groupbelong'];
    final groupIdIndex = headerIndex['groupid'];

    final previewItems = <CommandInfo>[];
    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final name = _readCell(row, nameIndex);
      final command = _readCell(row, commandIndex);
      if (name.isEmpty || command.isEmpty) {
        continue;
      }

      final type = _readCell(row, typeIndex);
      final groupBelong = _readCell(row, groupBelongIndex);
      final groupIdRaw = _readCell(row, groupIdIndex);
      previewItems.add(
        CommandInfo(
          name: name,
          command: command,
          type: type.isEmpty ? 'command' : type,
          groupBelong: groupBelong.isEmpty ? null : groupBelong,
          groupID: int.tryParse(groupIdRaw),
        ),
      );
    }

    return previewItems;
  }

  Future<void> importCommands(List<CommandOperate> items) {
    return _repository.importCommands(items);
  }

  Future<FileSaveResult> exportCommandsCsv() async {
    final path = await _repository.exportCommandsPath();
    if (path.trim().isEmpty) {
      throw Exception('Export file path is empty');
    }

    appLogger.dWithPackage(
      'features.commands.services.command',
      'exportCommandsCsv: path=$path',
    );
    final fileApi = await _clientManager.getFileApi();
    final response = await fileApi.downloadFile(path);
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Exported file is empty');
    }

    final fileName = path.split('/').lastWhere(
        (segment) => segment.trim().isNotEmpty,
        orElse: () => 'commands.csv');

    return _fileSaveService.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'text/csv',
    );
  }

  List<CommandInfo> applyGroupToPreview({
    required List<CommandInfo> previewItems,
    required GroupInfo group,
  }) {
    return previewItems
        .map(
          (item) => CommandInfo(
            id: item.id,
            name: item.name,
            type: item.type,
            command: item.command,
            groupID: group.id,
            groupBelong: group.name,
          ),
        )
        .toList(growable: false);
  }

  CommandOperate toOperate(CommandInfo info) {
    return CommandOperate(
      id: (info.id != null && info.id! > 0) ? info.id : null,
      name: info.name ?? '',
      type: info.type ?? 'command',
      command: info.command ?? '',
      groupID: info.groupID,
      groupBelong: info.groupBelong,
    );
  }

  List<List<String>> _parseCsvRows(String source) {
    final rows = <List<String>>[];
    final currentRow = <String>[];
    final currentField = StringBuffer();
    var inQuotes = false;

    void pushField() {
      currentRow.add(currentField.toString());
      currentField.clear();
    }

    void pushRow() {
      if (currentRow.length == 1 && currentRow.first.trim().isEmpty) {
        currentRow.clear();
        return;
      }
      rows.add(List<String>.from(currentRow, growable: false));
      currentRow.clear();
    }

    for (var i = 0; i < source.length; i++) {
      final ch = source[i];
      if (ch == '"') {
        final hasEscapedQuote =
            inQuotes && i + 1 < source.length && source[i + 1] == '"';
        if (hasEscapedQuote) {
          currentField.write('"');
          i++;
          continue;
        }
        inQuotes = !inQuotes;
        continue;
      }

      final isLineBreak = ch == '\n' || ch == '\r';
      if (!inQuotes && ch == ',') {
        pushField();
        continue;
      }
      if (!inQuotes && isLineBreak) {
        pushField();
        if (ch == '\r' && i + 1 < source.length && source[i + 1] == '\n') {
          i++;
        }
        pushRow();
        continue;
      }

      currentField.write(ch);
    }

    if (inQuotes) {
      throw const FormatException('CSV contains unterminated quoted field');
    }
    pushField();
    pushRow();
    return rows;
  }

  Map<String, int> _buildHeaderIndex(List<String> header) {
    final index = <String, int>{};
    for (var i = 0; i < header.length; i++) {
      final key = _normalizeHeader(header[i]);
      if (key.isNotEmpty && !index.containsKey(key)) {
        index[key] = i;
      }
    }
    return index;
  }

  String _normalizeHeader(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _readCell(List<String> row, int? index) {
    if (index == null || index < 0 || index >= row.length) {
      return '';
    }
    return row[index].trim();
  }
}
