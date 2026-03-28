import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/disk_management_models.dart';

class DiskManagementV2Api {
  DiskManagementV2Api(this._client);

  final DioClient _client;

  Future<Response<CompleteDiskInfo>> getCompleteDiskInfo() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/disks'),
    );
    final rawData = response.data?['data'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return Response<CompleteDiskInfo>(
      data: CompleteDiskInfo.fromJson(rawData),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> mountDisk(DiskMountRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/disks/mount'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> partitionDisk(DiskPartitionRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/disks/partition'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String>> unmountDisk(DiskUnmountRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/hosts/disks/unmount'),
      data: request.toJson(),
    );
    return Response<String>(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }
}
