import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/openresty_models.dart';
import 'api_response_parser.dart';

class _Parser {
  static Map<String, dynamic> extractMapData(
      Response<Map<String, dynamic>> response) {
    return ApiResponseParser.extractMapData(response);
  }

  static List<Map<String, dynamic>> extractListData(
      Response<Map<String, dynamic>> response) {
    return ApiResponseParser.extractListData(response)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
}

class OpenRestyV2Api {
  final DioClient _client;

  OpenRestyV2Api(this._client);

  Future<Response<OpenrestyFile>> getOpenRestyConfig() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/openresty'),
    );
    return Response(
      data: OpenrestyFile.fromJson(_Parser.extractMapData(response)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> buildOpenResty(OpenrestyBuildRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/openresty/build'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> updateOpenRestyConfigByFile(
      OpenrestyConfigFileUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/openresty/file'),
      data: request.toJson(),
    );
  }

  Future<Response<OpenrestyHttpsConfig>> getOpenRestyHttps() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/openresty/https'),
    );
    return Response(
      data: OpenrestyHttpsConfig.fromJson(_Parser.extractMapData(response)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateOpenRestyHttps(
      OpenrestyDefaultHttpsUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/openresty/https'),
      data: request.toJson(),
    );
  }

  Future<Response<OpenrestyBuildConfig>> getOpenRestyModules() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/openresty/modules'),
    );
    return Response(
      data: OpenrestyBuildConfig.fromJson(_Parser.extractMapData(response)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateOpenRestyModules(
      OpenrestyModuleUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/openresty/modules/update'),
      data: request.toJson(),
    );
  }

  Future<Response<List<OpenrestyParam>>> getOpenRestyScope(
      OpenrestyScopeRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/openresty/scope'),
      data: request.toJson(),
    );
    final items =
        _Parser.extractListData(response).map(OpenrestyParam.fromJson).toList();
    return Response(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<OpenrestyStatus>> getOpenRestyStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/openresty/status'),
    );
    return Response(
      data: OpenrestyStatus.fromJson(_Parser.extractMapData(response)),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateOpenResty(
      OpenrestyConfigUpdateRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/openresty/update'),
      data: request.toJson(),
    );
  }
}
