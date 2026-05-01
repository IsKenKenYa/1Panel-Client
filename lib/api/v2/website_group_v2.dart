import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';

class WebsiteGroupV2Api {
  final DioClient _client;

  WebsiteGroupV2Api(this._client);

  Future<Response<void>> getGroups({String name = '', String type = ''}) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/groups'),
      data: <String, dynamic>{'name': name, 'type': type},
    );
  }

  /// 获取网站分组列表
  Future<Response<Map<String, dynamic>>> searchGroups(Map<String, dynamic> data) async {
    return await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/groups/search'),
      data: data,
    );
  }

  Future<Response<void>> updateGroup(Map<String, dynamic> data) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/groups/update'),
      data: data,
    );
  }

  Future<Response<void>> deleteGroup(Map<String, dynamic> data) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/groups/del'),
      data: data,
    );
  }
}
