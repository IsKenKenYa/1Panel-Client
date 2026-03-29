import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/container_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/docker_models.dart';

class ComposeV2Api {
  final DioClient _client;

  ComposeV2Api(this._client);

  /// List Compose projects
  Future<Response<PageResult<ComposeProject>>> listComposes({
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    final request = ContainerComposeSearch(
      page: page,
      pageSize: pageSize,
      search: search,
    );
    final response = await _client.post(
      ApiConstants.buildApiPath('/containers/compose/search'),
      data: request.toJson(),
    );
    final body = (response.data as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final payload = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    return Response(
      data: PageResult.fromJson(
        payload,
        (json) => ComposeProject.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Create Compose project
  Future<Response<ComposeProject>> createCompose(
      ContainerComposeCreate compose) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/containers/compose'),
      data: compose.toJson(),
    );
    final body = (response.data as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final payload = body['data'] is Map<String, dynamic>
        ? body['data'] as Map<String, dynamic>
        : body;
    return Response(
      data: ComposeProject.fromJson(payload),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Operate Compose project (up, down, start, stop, restart)
  Future<Response> _operateCompose(
    String name,
    String operation, {
    String? path,
    bool? withFile,
    bool force = false,
  }) async {
    final op = ContainerComposeOperate(
      name: name,
      operation: operation,
      path: path,
      withFile: withFile,
      force: force,
    );
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/operate'),
      data: op.toJson(),
    );
  }

  /// Up Compose project
  Future<Response> upCompose(ComposeProject compose) async {
    return _operateCompose(compose.name, 'up', path: compose.path);
  }

  /// Down Compose project
  Future<Response> downCompose(ComposeProject compose) async {
    return _operateCompose(compose.name, 'down', path: compose.path);
  }

  /// Start Compose project
  Future<Response> startCompose(ComposeProject compose) async {
    return _operateCompose(compose.name, 'start', path: compose.path);
  }

  /// Stop Compose project
  Future<Response> stopCompose(ComposeProject compose) async {
    return _operateCompose(compose.name, 'stop', path: compose.path);
  }

  /// Restart Compose project
  Future<Response> restartCompose(ComposeProject compose) async {
    return _operateCompose(compose.name, 'restart', path: compose.path);
  }

  /// Load Compose environment variables
  Future<Response<List<String>>> loadComposeEnv(FilePath request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/compose/env'),
      data: request.toJson(),
    );
    final data = response.data?['data'];
    final envs = <String>[];
    if (data is List) {
      envs.addAll(data.map((e) => e.toString()));
    }
    return Response(
      data: envs,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Update Compose project
  Future<Response> updateCompose(ContainerComposeUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/update'),
      data: request.toJson(),
    );
  }

  /// Test Compose project
  Future<Response> testCompose(ContainerComposeCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/test'),
      data: request.toJson(),
    );
  }

  /// Clean Compose logs
  Future<Response> cleanComposeLog(
      ContainerComposeLogCleanRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/clean/log'),
      data: request.toJson(),
    );
  }
}
