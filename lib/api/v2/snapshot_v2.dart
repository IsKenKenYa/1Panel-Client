import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/snapshot_models.dart';
import '../../data/models/common_models.dart';

class SnapshotV2Api {
  final DioClient _client;

  SnapshotV2Api(this._client);

  Future<Response<void>> createSnapshot(SnapshotCreateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> deleteSnapshot(OperateByID request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/del'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateSnapshotDescription(
      SnapshotDescriptionUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/description/update'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> importSnapshot(SnapshotImport request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/import'),
      data: request.toJson(),
    );
  }

  Future<Response<Map<String, dynamic>>> loadSnapshot() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/snapshot/load'),
    );
    return Response(
      data: response.data?['data'] as Map<String, dynamic>? ?? {},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> recoverSnapshot(SnapshotRecoverRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/recover'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> recreateSnapshot({int id = 0}) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/recreate'),
      data: <String, dynamic>{'id': id},
    );
  }

  Future<Response<void>> rollbackSnapshot(SnapshotRollback request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/rollback'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<SnapshotInfo>>> searchSnapshots(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/snapshot/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? {},
        (dynamic item) => SnapshotInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}

class SnapshotDescriptionUpdate {
  final int id;
  final String description;

  const SnapshotDescriptionUpdate({
    required this.id,
    required this.description,
  });

  Map<String, dynamic> toJson() => {'id': id, 'description': description};
}

class SnapshotImport {
  final String path;

  const SnapshotImport({required this.path});

  Map<String, dynamic> toJson() => {'path': path};
}

class SnapshotRollback {
  final int id;

  const SnapshotRollback({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}
