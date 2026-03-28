import 'dart:typed_data';

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

  Future<List<CommandInfo>> uploadCommandsCsv({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _repository.uploadCommandsCsv(
      bytes: bytes,
      fileName: fileName,
    );
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
}
