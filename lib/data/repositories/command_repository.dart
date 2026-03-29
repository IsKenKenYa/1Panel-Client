import 'package:onepanel_client/api/v2/command_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/core/services/logger/logger_service.dart';
import 'package:onepanel_client/data/models/command_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';

class CommandRepository {
  CommandRepository({
    ApiClientManager? clientManager,
    CommandV2Api? api,
  })  : _clientManager = clientManager ?? ApiClientManager.instance,
        _api = api;

  final ApiClientManager _clientManager;
  CommandV2Api? _api;

  Future<CommandV2Api> _ensureApi() async {
    return _api ??= await _clientManager.getCommandApi();
  }

  Future<PageResult<CommandInfo>> searchCommands(
    CommandSearchRequest request,
  ) async {
    appLogger.dWithPackage(
      'data.repositories.command',
      'searchCommands: ${request.toJson()}',
    );
    final api = await _ensureApi();
    final response = await api.searchCommands(request);
    return response.data ??
        const PageResult<CommandInfo>(
          items: <CommandInfo>[],
          total: 0,
        );
  }

  Future<void> importCommands(List<CommandOperate> items) async {
    final api = await _ensureApi();
    await api.importCommand(items);
  }

  Future<String> exportCommandsPath() async {
    final api = await _ensureApi();
    final response = await api.exportCommand();
    return response.data ?? '';
  }

  Future<void> createCommand(CommandOperate request) async {
    final api = await _ensureApi();
    await api.createCommand(request);
  }

  Future<void> updateCommand(CommandOperate request) async {
    final api = await _ensureApi();
    await api.updateCommand(request);
  }

  Future<void> deleteCommands(List<int> ids) async {
    final api = await _ensureApi();
    await api.deleteCommand(OperateByIDs(ids: ids));
  }
}
