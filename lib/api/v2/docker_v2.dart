import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/docker_models.dart';
import '../../data/models/container_models.dart';
import '../../data/models/common_models.dart';

class DockerV2Api {
  final DioClient _client;

  DockerV2Api(this._client);

  // --- Images ---

  List<T> _parseList<T>(
      dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data is List) {
      return data.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return (data['data'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data['items'] is List) {
        return (data['items'] as List)
            .map((e) => fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  List<T> _parsePageItems<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'];
      if (payload is Map<String, dynamic>) {
        final items = payload['items'];
        if (items is List) {
          return items
              .whereType<Map<String, dynamic>>()
              .map(fromJson)
              .toList();
        }
      }
    }
    return _parseList(data, fromJson);
  }

  /// List all images
  Future<Response<List<DockerImage>>> listImages() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/containers/image/all'),
    );
    return Response(
      data: _parseList(response.data, DockerImage.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Pull image
  Future<Response<void>> pullImage(ImagePull request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/pull'),
      data: request.toJson(),
    );
  }

  /// Build image
  Future<Response<String>> buildImage(ImageBuild request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/build'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Load image
  Future<Response<void>> loadImage(ImageLoad request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/load'),
      data: request.toJson(),
    );
  }

  /// Save image
  Future<Response<void>> saveImage(ImageSave request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/save'),
      data: request.toJson(),
    );
  }

  /// Tag image
  Future<Response<void>> tagImage(ImageTag request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/tag'),
      data: request.toJson(),
    );
  }

  /// Push image
  Future<Response<void>> pushImage(ImagePush request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/push'),
      data: request.toJson(),
    );
  }

  /// Search images
  Future<Response<PageResult<Map<String, dynamic>>>> searchImages(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
          response.data?['data'] ?? {}, (json) => json as Map<String, dynamic>),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Remove image
  Future<Response<void>> removeImage(String imageId, {bool force = false}) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/remove'),
      data: {
        'names': [imageId],
        'force': force
      },
    );
  }

  // --- Networks ---

  /// List networks
  Future<Response<List<DockerNetwork>>> listNetworks() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/containers/network/search'),
      data: const SearchWithPage(page: 1, pageSize: 100).toJson(),
    );
    return Response(
      data: _parsePageItems(response.data, DockerNetwork.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Create network
  Future<Response<void>> createNetwork(NetworkCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/network'),
      data: request.toJson(),
    );
  }

  /// Remove network
  Future<Response<void>> removeNetwork(String networkId) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/network/del'),
      data: {
        'names': [networkId]
      },
    );
  }

  // --- Volumes ---

  /// List volumes
  Future<Response<List<DockerVolume>>> listVolumes() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/containers/volume/search'),
      data: const SearchWithPage(page: 1, pageSize: 100).toJson(),
    );
    return Response(
      data: _parsePageItems(response.data, DockerVolume.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Create volume
  Future<Response<void>> createVolume(VolumeCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/volume'),
      data: request.toJson(),
    );
  }

  /// Remove volume
  Future<Response<void>> removeVolume(String volumeName) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/volume/del'),
      data: {
        'names': [volumeName]
      },
    );
  }
}
