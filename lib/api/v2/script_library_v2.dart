import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/script_library_models.dart';

class ScriptLibraryV2Api {
  ScriptLibraryV2Api(this._client);

  final DioClient _client;

  Future<Response<PageResult<ScriptLibraryInfo>>> searchScripts(
    ScriptLibraryQuery request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/script/search'),
      data: request.toJson(),
    );
    return Response<PageResult<ScriptLibraryInfo>>(
      data: PageResult<ScriptLibraryInfo>.fromJson(
        response.data?['data'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
        (dynamic item) =>
            ScriptLibraryInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> syncScripts(String taskId) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script/sync'),
      data: <String, dynamic>{'taskID': taskId},
    );
  }

  Future<Response<void>> deleteScripts(ScriptDeleteRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/script/del'),
      data: request.toJson(),
    );
  }
}
