import 'package:dio/dio.dart';

import '../../core/config/api_constants.dart';
import '../../core/network/dio_client.dart';
import 'api_response_parser.dart';

/// 1Panel health check API client.
///
/// 覆盖 swagger `GET /health/check`；返回体为自由形态（信封包裹的
/// data 字段或纯文本），原样透传给调用方判定连通性。
class HealthV2Api {
  HealthV2Api(this._client);

  final DioClient _client;

  Future<Response<dynamic>> checkHealth() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/health/check'),
    );
    return ApiResponseParser.withData(
      response,
      ApiResponseParser.unwrap(response.data),
    );
  }
}
