import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/command_models.dart';

class CommandV2Api {
  CommandV2Api(this._client);

  final DioClient _client;

  Future<Response<void>> createCommand(CommandOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/commands'),
      data: request.toJson(),
    );
  }

  Future<Response<List<CommandInfo>>> listCommands({
    String type = 'command',
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/commands/list'),
      data: <String, dynamic>{'type': type},
    );
    final items = _parseCommandInfoList(response.data?['data']);
    return Response<List<CommandInfo>>(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  @Deprecated('Use listCommands for command list retrieval.')
  Future<Response<CommandInfo>> getCommand(OperateByType request) async {
    final payload = request.toJson()
      ..removeWhere(
        (String _, dynamic value) =>
            value == null || (value is String && value.trim().isEmpty),
      );
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/commands/list'),
      data: payload,
    );
    final items = _parseCommandInfoList(response.data?['data']);

    var command = const CommandInfo();
    var found = false;

    if (request.id != null) {
      for (final item in items) {
        if (item.id == request.id) {
          command = item;
          found = true;
          break;
        }
      }
    }

    if (!found && request.name.trim().isNotEmpty) {
      for (final item in items) {
        if ((item.name ?? '').trim() == request.name.trim()) {
          command = item;
          found = true;
          break;
        }
      }
    }

    if (!found && items.isNotEmpty) {
      command = items.first;
    }

    return Response<CommandInfo>(
      data: command,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> deleteCommand(OperateByIDs request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/commands/del'),
      data: request.toJson(),
    );
  }

  Future<Response<String>> exportCommand([OperateByIDs? request]) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/commands/export'),
      data: request?.toJson(),
    );
    return Response<String>(
      data: response.data?['data'] as String? ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> importCommand(List<CommandOperate> items) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/commands/import'),
      data: <String, dynamic>{
        'items': items.map((CommandOperate item) => item.toJson()).toList(),
      },
    );
  }

  Future<Response<PageResult<CommandInfo>>> searchCommands(
    CommandSearchRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/commands/search'),
      data: request.toJson(),
    );
    return Response<PageResult<CommandInfo>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => CommandInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<PageResult<CommandInfo>>> searchCommand(
    PageRequest request,
  ) async {
    return searchCommands(
      CommandSearchRequest(
        page: request.page,
        pageSize: request.pageSize,
      ),
    );
  }

  Future<Response> getCommandTreeByType({required String type}) async {
    return await _client.get(
      ApiConstants.buildApiPath('/core/commands/tree'),
      queryParameters: <String, dynamic>{'type': type},
    );
  }

  /// 获取命令信息
  Future<Response> getCommandByType({required String type}) async {
    return await _client.get(
      ApiConstants.buildApiPath('/core/commands/command'),
      queryParameters: <String, dynamic>{'type': type},
    );
  }

  Future<Response<void>> updateCommand(CommandOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/commands/update'),
      data: request.toJson(),
    );
  }

  List<CommandInfo> _parseCommandInfoList(dynamic rawData) {
    if (rawData is List) {
      return rawData
          .whereType<Map<String, dynamic>>()
          .map(CommandInfo.fromJson)
          .toList(growable: false);
    }
    if (rawData is Map<String, dynamic>) {
      return <CommandInfo>[CommandInfo.fromJson(rawData)];
    }
    return const <CommandInfo>[];
  }

  Future<Response<void>> createScript(ScriptOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteScript(OperateByIDs request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script/del'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<ScriptOperate>>> searchScript(
    PageRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/script/search'),
      data: request.toJson(),
    );
    return Response<PageResult<ScriptOperate>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => ScriptOperate.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> syncScript({String? taskId}) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script/sync'),
      data: <String, dynamic>{
        if (taskId != null && taskId.isNotEmpty) 'taskID': taskId,
      },
    );
  }

  Future<Response<void>> updateScript(ScriptOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script/update'),
      data: request.toJson(),
    );
  }

  Future<Response<List<ScriptOptions>>> getScriptOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/cronjobs/script/options'),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<ScriptOptions>>(
      data: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ScriptOptions.fromJson)
          .toList(growable: false),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}
