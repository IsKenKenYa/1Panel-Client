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
    return Response(
      data: PageResult.fromJson(
        response.data as Map<String, dynamic>,
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
    return Response(
      data: ComposeProject.fromJson(response.data as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Operate Compose project (up, down, start, stop, restart)
  Future<Response> _operateCompose(
      List<int> ids, String operation, {bool force = false}) async {
    final op = ContainerComposeOperate(
        ids: ids, operation: operation, force: force);
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/operate'),
      data: op.toJson(),
    );
  }

  /// Up Compose project
  Future<Response> upCompose(int id) async {
    return _operateCompose([id], 'up');
  }

  /// Down Compose project
  Future<Response> downCompose(int id) async {
    return _operateCompose([id], 'down');
  }

  /// Start Compose project
  Future<Response> startCompose(int id) async {
    return _operateCompose([id], 'start');
  }

  /// Stop Compose project
  Future<Response> stopCompose(int id) async {
    return _operateCompose([id], 'stop');
  }

  /// Restart Compose project
  Future<Response> restartCompose(int id) async {
    return _operateCompose([id], 'restart');
  }

  /// Update Compose project
  Future<Response> updateCompose(ContainerComposeUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/update'),
      data: request.toJson(),
    );
  }

  /// Test Compose project
  Future<Response> testCompose(ContainerComposeUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/test'),
      data: request.toJson(),
    );
  }

  /// Clean Compose logs
  Future<Response> cleanComposeLog(ContainerComposeLogCleanRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/containers/compose/clean/log'),
      data: request.toJson(),
    );
  }
}
