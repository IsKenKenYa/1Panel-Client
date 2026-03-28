import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/terminal_models.dart';

class TerminalV2Api {
  final DioClient _client;

  TerminalV2Api(this._client);

  Future<Response<TerminalSessionInfo>> createTerminalSession(
      TerminalSessionCreate request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions'),
      data: request.toJson(),
    );
    return Response(
      data: TerminalSessionInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<TerminalSessionInfo>>> getTerminalSessions() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/terminal/sessions'),
    );
    return Response(
      data: (response.data as List?)
              ?.map((item) =>
                  TerminalSessionInfo.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<TerminalSessionInfo>> getTerminalSessionDetail(
      String sessionId) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId'),
    );
    return Response(
      data: TerminalSessionInfo.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response> deleteTerminalSession(String sessionId) async {
    final operation = TerminalSessionOperate(
      sessionId: sessionId,
      operation: 'delete',
    );
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/delete'),
      data: operation.toJson(),
    );
  }

  Future<Response<TerminalCommandResult>> executeTerminalCommand(
      TerminalCommandExecute request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/terminal/command'),
      data: request.toJson(),
    );
    return Response(
      data:
          TerminalCommandResult.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response> searchTerminalSettings(Map<String, dynamic> data) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/terminal/search'),
      data: data,
    );
  }

  Future<Response> updateTerminalSettings(Map<String, dynamic> data) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/terminal/update'),
      data: data,
    );
  }

  Future<Response> getTerminalOutput(String sessionId,
      {int lines = 100}) async {
    final data = {
      'lines': lines,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/output'),
      data: data,
    );
  }

  Future<Response> sendTerminalInput({
    required String sessionId,
    required String input,
  }) async {
    final data = {
      'input': input,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/input'),
      data: data,
    );
  }

  Future<Response> resizeTerminal({
    required String sessionId,
    required int rows,
    required int columns,
  }) async {
    final data = {
      'rows': rows,
      'columns': columns,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/resize'),
      data: data,
    );
  }

  Future<Response> getTerminalHistory(String sessionId,
      {int limit = 100}) async {
    final data = {
      'limit': limit,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/history'),
      data: data,
    );
  }

  Future<Response> clearTerminalHistory(String sessionId) async {
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/history/clear'),
    );
  }

  Future<Response> getTerminalStatus(String sessionId) async {
    return await _client.get(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/status'),
    );
  }

  Future<Response> renameTerminalSession({
    required String sessionId,
    required String name,
  }) async {
    final data = {
      'name': name,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/rename'),
      data: data,
    );
  }

  Future<Response> getTerminalFiles(String sessionId, {String? path}) async {
    final data = {
      if (path != null) 'path': path,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/files'),
      data: data,
    );
  }

  Future<Response> uploadFileToTerminal({
    required String sessionId,
    required String filePath,
    String? targetPath,
  }) async {
    final data = {
      'filePath': filePath,
      if (targetPath != null) 'targetPath': targetPath,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/files/upload'),
      data: data,
    );
  }

  Future<Response> downloadFileFromTerminal({
    required String sessionId,
    required String filePath,
  }) async {
    final data = {
      'filePath': filePath,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/files/download'),
      data: data,
    );
  }

  Future<Response> getTerminalProcesses(String sessionId) async {
    return await _client.get(
      ApiConstants.buildApiPath('/terminal/sessions/$sessionId/processes'),
    );
  }

  Future<Response> terminateTerminalProcess({
    required String sessionId,
    required int processId,
  }) async {
    final data = {
      'processId': processId,
    };
    return await _client.post(
      ApiConstants.buildApiPath(
          '/terminal/sessions/$sessionId/processes/terminate'),
      data: data,
    );
  }

  Future<Response> getTerminalConfig() async {
    return await _client.get(
      ApiConstants.buildApiPath('/terminal/config'),
    );
  }

  Future<Response> updateTerminalConfig(Map<String, dynamic> config) async {
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/config'),
      data: config,
    );
  }

  Future<Response> getTerminalThemes() async {
    return await _client.get(
      ApiConstants.buildApiPath('/terminal/themes'),
    );
  }

  Future<Response> setTerminalTheme(String theme) async {
    final data = {
      'theme': theme,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/theme'),
      data: data,
    );
  }

  Future<Response> getTerminalFonts() async {
    return await _client.get(
      ApiConstants.buildApiPath('/terminal/fonts'),
    );
  }

  Future<Response> setTerminalFont({
    required String font,
    double? fontSize,
  }) async {
    final data = {
      'font': font,
      if (fontSize != null) 'fontSize': fontSize,
    };
    return await _client.post(
      ApiConstants.buildApiPath('/terminal/font'),
      data: data,
    );
  }
}
