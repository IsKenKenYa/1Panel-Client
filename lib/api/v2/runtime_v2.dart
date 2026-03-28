import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/common_models.dart';
import '../../data/models/runtime_models.dart';

class RuntimeV2Api {
  RuntimeV2Api(this._client);

  final DioClient _client;

  Future<Response<RuntimeInfo>> createRuntime(RuntimeCreate request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes'),
      data: request.toJson(),
    );
    return Response<RuntimeInfo>(
      data: RuntimeInfo.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<RuntimeInfo>> getRuntime(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/$id'),
    );
    return Response<RuntimeInfo>(
      data: RuntimeInfo.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> deleteRuntime(RuntimeDelete request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/del'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> operateRuntime(RuntimeOperate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<PageResult<RuntimeInfo>>> getRuntimes(
    RuntimeSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/search'),
      data: request.toJson(),
    );
    return Response<PageResult<RuntimeInfo>>(
      data: PageResult.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
        (dynamic item) => RuntimeInfo.fromJson(item as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> syncRuntimeStatus() {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/sync'),
      data: const <String, dynamic>{},
    );
  }

  Future<Response<void>> updateRuntime(RuntimeUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/update'),
      data: request.toJson(),
    );
  }

  Future<Response<PHPExtensionsRes>> getPhpExtensions(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/php/$id/extensions'),
    );
    return Response<PHPExtensionsRes>(
      data: PHPExtensionsRes.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> installPhpExtension(
    PHPExtensionInstallRequest request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/php/extensions/install'),
      data: request.toJson(),
    );
  }

  Future<Response<void>> uninstallPhpExtension(
    PHPExtensionInstallRequest request,
  ) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/php/extensions/uninstall'),
      data: request.toJson(),
    );
  }

  Future<Response<PHPConfig>> loadPhpConfig(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/php/config/$id'),
    );
    return Response<PHPConfig>(
      data: PHPConfig.fromJson(
        response.data?['data'] as Map<String, dynamic>? ?? const {},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updatePhpConfig(PHPConfigUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/php/config'),
      data: request.toJson(),
    );
  }

  Future<Response<List<NodeModuleInfo>>> getNodeModules(
    NodeModuleRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/node/modules'),
      data: request.toJson(),
    );
    final rawData = response.data?['data'];
    final items = (rawData is List<dynamic> ? rawData : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(NodeModuleInfo.fromJson)
        .toList(growable: false);
    return Response<List<NodeModuleInfo>>(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> operateNodeModule(NodeModuleRequest request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/node/modules/operate'),
      data: request.toJson(),
    );
  }

  Future<Response<List<NodeScriptInfo>>> getNodePackageScripts(
    NodePackageRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/node/package'),
      data: request.toJson(),
    );
    final rawData = response.data?['data'];
    final items = (rawData is List<dynamic> ? rawData : const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(NodeScriptInfo.fromJson)
        .toList(growable: false);
    return Response<List<NodeScriptInfo>>(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<List<FpmStatusItem>>> getPhpStatus(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/php/fpm/status/$id'),
    );
    final rawData = response.data?['data'];

    final items = switch (rawData) {
      List<dynamic> _ => rawData
          .whereType<Map<String, dynamic>>()
          .map(FpmStatusItem.fromJson)
          .toList(growable: false),
      Map<String, dynamic> _ => rawData.entries
          .map(
            (entry) => FpmStatusItem(
              key: entry.key,
              value: entry.value,
            ),
          )
          .toList(growable: false),
      _ => const <FpmStatusItem>[],
    };

    return Response<List<FpmStatusItem>>(
      data: items,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<void>> updateRuntimeRemark(RuntimeRemarkUpdate request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/remark'),
      data: request.toJson(),
    );
  }
}
