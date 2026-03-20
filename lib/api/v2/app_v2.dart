import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/app_models.dart';
import '../../core/config/api_constants.dart';

import '../../data/models/app_config_models.dart';

/// 1Panel V2 API - 应用管理接口
class AppV2Api {
  final DioClient _client;

  AppV2Api(this._client);

  List<T> _parseListData<T>(dynamic dataField, T Function(Map<String, dynamic>) fromJson) {
    if (dataField == null) return [];
    if (dataField is List) {
      return dataField.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    }
    if (dataField is Map<String, dynamic>) {
      final items = dataField['items'];
      if (items is List) {
        return items.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
      // Handle potential nested data structure
      final innerData = dataField['data'];
      if (innerData is List) {
        return innerData.map((e) => fromJson(e as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  AppSearchResponse _parseAppSearchResponse(dynamic dataField) {
    if (dataField is Map<String, dynamic>) {
      // Ensure we extract total correctly
      if (dataField.containsKey('items') || dataField.containsKey('total')) {
        final itemsData = dataField['items'];
        final List<AppItem> items = (itemsData is List) 
            ? itemsData.map((e) => AppItem.fromJson(e as Map<String, dynamic>)).toList()
            : [];
        
        final totalData = dataField['total'];
        final int total = (totalData is int) ? totalData : items.length;
        
        return AppSearchResponse(items: items, total: total);
      }
      // Try nested 'data' structure if present
      if (dataField.containsKey('data')) {
        return _parseAppSearchResponse(dataField['data']);
      }
      // Try 'apps' key instead of 'items'
      if (dataField.containsKey('apps')) {
        final itemsData = dataField['apps'];
        final List<AppItem> items = (itemsData is List) 
            ? itemsData.map((e) => AppItem.fromJson(e as Map<String, dynamic>)).toList()
            : [];
        final totalData = dataField['total'];
        final int total = (totalData is int) ? totalData : items.length;
        return AppSearchResponse(items: items, total: total);
      }
      
      return AppSearchResponse.fromJson(dataField);
    }
    if (dataField is List) {
      final items = dataField.map((e) => AppItem.fromJson(e as Map<String, dynamic>)).toList();
      return AppSearchResponse(items: items, total: items.length);
    }
    return AppSearchResponse(items: [], total: 0);
  }

  AppUpdateResponse _parseAppUpdateResponse(dynamic dataField) {
    if (dataField is Map<String, dynamic>) {
      if (dataField.containsKey('updates')) {
        return AppUpdateResponse.fromJson(dataField);
      }
      final items = _parseListData(dataField, AppInstallInfo.fromJson);
      final total = dataField['total'];
      return AppUpdateResponse(updates: items, total: total is num ? total.toInt() : items.length);
    }
    if (dataField is List) {
      final items = dataField.map((e) => AppInstallInfo.fromJson(e as Map<String, dynamic>)).toList();
      return AppUpdateResponse(updates: items, total: items.length);
    }
    return AppUpdateResponse(updates: [], total: 0);
  }

  /// 安装应用
  Future<AppInstallInfo> installApp(AppInstallCreateRequest request) async {
    try {
      final response = await _client.post<dynamic>(
        ApiConstants.buildApiPath('/apps/install'),
        data: request.toJson(),
      );
      
      final data = response.data;
      if (data == null || (data is String && data.isEmpty)) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Install failed: Empty response from server',
          type: DioExceptionType.badResponse,
        );
      }

      if (data is! Map<String, dynamic>) {
         throw DioException(
          requestOptions: response.requestOptions,
          error: 'Install failed: Invalid response format',
          type: DioExceptionType.badResponse,
        );
      }

      final innerData = data['data'];
      
      if (innerData is Map<String, dynamic>) {
        return AppInstallInfo.fromJson(innerData);
      }
      
      // Handle case where it returns just an ID (int or String)
      if (innerData is int || innerData is String) {
        return AppInstallInfo(
          id: int.tryParse(innerData.toString()),
          name: request.name,
          status: 'Installing',
          createdAt: DateTime.now().toIso8601String(),
          version: 'latest',
          appDetailId: request.appDetailId,
          appId: 0,
          appKey: request.name,
          appType: request.type ?? 'unknown',
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Install failed: Unexpected response data format: $innerData',
        type: DioExceptionType.badResponse,
      );
    } catch (e) {
      if (e is DioException) {
         rethrow;
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/apps/install'),
        error: 'Install failed: $e',
      );
    }
  }

  /// 卸载应用
  Future<void> uninstallApp(String appInstallId) async {
    await operateApp(
      AppInstalledOperateRequest(
        installId: int.tryParse(appInstallId) ?? 0,
        operate: 'delete',
        deleteDB: true,
        deleteImage: true,
        deleteBackup: true,
        forceDelete: true,
      ),
    );
  }

  /// 更新应用
  Future<void> updateApp(String appInstallId) async {
    await operateApp(
      AppInstalledOperateRequest(
        installId: int.tryParse(appInstallId) ?? 0,
        operate: 'upgrade',
      ),
    );
  }

  /// 搜索应用
  Future<AppSearchResponse> searchApps(AppSearchRequest request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/search'),
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      // Return empty result instead of crashing
      return AppSearchResponse(items: [], total: 0);
    }
    return _parseAppSearchResponse(data['data']);
  }


  /// 获取应用详情
  Future<AppItem> getAppDetail(String appId, String version, String type) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/detail/$appId/$version/$type'),
    );
    final data = response.data;
    
    if (data == null) {
       throw DioException(
         requestOptions: response.requestOptions, 
         error: 'App detail response is empty',
         type: DioExceptionType.badResponse,
       );
    }

    if (data is! Map<String, dynamic>) {
       throw DioException(
         requestOptions: response.requestOptions, 
         error: 'Invalid response format: Expected Map, got ${data.runtimeType}',
         type: DioExceptionType.badResponse,
       );
    }
    final innerData = data['data'];
    if (innerData is! Map<String, dynamic>) {
       throw DioException(
         requestOptions: response.requestOptions, 
         error: 'App detail not found or invalid format',
         type: DioExceptionType.badResponse,
       );
    }
    return AppItem.fromJson(innerData);
  }

  /// 获取应用详情（通过ID）
  Future<AppItem> getAppDetails(String id) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/details/$id'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 获取应用详情（通过Key）
  Future<AppItem> getAppByKey(String key) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/$key'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppItem.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 获取应用详情（节点专用）
  Future<AppDetailSimple> getAppDetailNode(String appKey, String version) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/detail/node/$appKey/$version'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppDetailSimple.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 获取应用图标
  Future<Response<List<int>>> getAppIcon(String appKey) async {
    return _client.get<List<int>>(
      ApiConstants.buildApiPath('/apps/icon/$appKey'),
      options: Options(responseType: ResponseType.bytes),
    );
  }

  /// 检查应用更新
  Future<AppUpdateResponse> checkAppUpdate() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/checkupdate'),
    );
    final data = response.data as Map<String, dynamic>;
    return _parseAppUpdateResponse(data['data']);
  }

  /// 获取忽略更新的应用详情列表
  Future<List<AppInstallInfo>> getIgnoredAppDetails() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/ignored/detail'),
    );
    final data = response.data as Map<String, dynamic>;
    return _parseListData(data['data'], AppInstallInfo.fromJson);
  }

  /// 取消忽略应用更新
  Future<void> cancelIgnoreAppUpdate(AppInstalledIgnoreUpgradeRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/ignored/cancel'),
      data: {'id': request.appInstallId},
    );
  }

  /// 检查应用安装
  Future<AppInstalledCheckResponse> checkAppInstall(AppInstalledCheckRequest request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/check'),
      data: request.toJson(),
    );
    final data = response.data as Map<String, dynamic>;
    final innerData = Map<String, dynamic>.from(data['data'] as Map<String, dynamic>);
    
    // Ensure exist is boolean, default to false if null
    if (innerData['exist'] == null) {
      innerData['exist'] = false;
    }
    
    return AppInstalledCheckResponse.fromJson(innerData);
  }

  /// 获取应用安装配置（旧版/默认配置）
  Future<Map<String, dynamic>> getAppInstallConfig(String name, String key) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/conf'),
      data: {'name': name, 'type': key},
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  /// 更新应用安装配置
  Future<void> updateAppInstallConfig(AppConfigUpdateRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/config/update'),
      data: request.toJson(),
    );
  }

  /// 获取应用连接信息
  Future<Map<String, dynamic>> getAppConnInfo(String name, String key) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/conninfo'),
      data: {'name': name, 'type': key},
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as Map<String, dynamic>;
  }

  /// 检查应用卸载
  Future<Map<String, dynamic>> checkAppUninstall(String appInstallId) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/delete/check/$appInstallId'),
    );
    final data = response.data as Map<String, dynamic>;
    final innerData = data['data'];
    if (innerData == null) {
      return {};
    }
    return innerData as Map<String, dynamic>;
  }

  /// 忽略应用更新
  Future<void> ignoreAppUpdate(AppInstalledIgnoreUpgradeRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/ignore'),
      data: request.toJson(),
    );
  }

  /// 获取已安装应用列表
  Future<List<AppInstallInfo>> getInstalledApps() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/list'),
    );
    final data = response.data as Map<String, dynamic>;
    return _parseListData(data['data'], AppInstallInfo.fromJson);
  }

  /// 加载应用端口
  Future<int> loadAppPort(Map<String, dynamic> request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/loadport'),
      data: request,
    );
    final data = response.data as Map<String, dynamic>;
    return data['data'] as int;
  }

  /// 应用操作（启动、停止、重启）
  Future<void> operateApp(AppInstalledOperateRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/op'),
      data: request.toJson(),
    );
  }

  /// 获取应用安装配置（通过ID）
  Future<AppConfig> getAppInstallParams(int appInstallId) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/params/$appInstallId'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppConfig.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 搜索已安装应用
  Future<PageResult<AppInstallInfo>> searchInstalledApps(AppInstalledSearchRequest request) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/search'),
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
       // Return empty result instead of crashing
       return PageResult(items: [], total: 0);
    }
    final innerData = data['data'];
    if (innerData is! Map<String, dynamic>) {
       return PageResult(items: [], total: 0);
    }
    return PageResult.fromJson(
      innerData,
      (dynamic item) => AppInstallInfo.fromJson(item as Map<String, dynamic>),
    );
  }

  /// 同步应用状态
  Future<void> syncAppStatus() async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/sync'),
    );
  }

  /// 获取应用安装信息
  Future<AppInstallInfo> getAppInstallInfo(String appInstallId) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/info/$appInstallId'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppInstallInfo.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 更新应用安装参数
  Future<void> updateAppParams(AppInstalledParamsUpdateRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/params/update'),
      data: request.toJson(),
    );
  }

  /// 修改应用端口
  Future<void> changeAppPort(AppPortUpdateRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/installed/port/change'),
      data: request.toJson(),
    );
  }

  /// 获取应用更新版本列表
  Future<List<AppVersion>> getAppUpdateVersions(String appInstallId) async {
    final response = await _client.post<dynamic>(
      ApiConstants.buildApiPath('/apps/installed/update/versions'),
      data: {'appInstallID': int.tryParse(appInstallId) ?? 0},
    );
    final data = response.data as Map<String, dynamic>;
    // 处理API返回的data字段可能是Map或List的情况
    final dataField = data['data'];
    if (dataField is List) {
      return dataField.map((e) => AppVersion.fromJson(e as Map<String, dynamic>)).toList();
    } else if (dataField is Map<String, dynamic>) {
      final items = dataField['items'] as List?;
      return items?.map((e) => AppVersion.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    }
    return [];
  }

  /// 获取应用服务列表
  Future<List<AppServiceResponse>> getAppServices(String key) async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/apps/services/$key'),
    );
    final data = response.data as Map<String, dynamic>;
    // 处理API返回的data字段可能是Map或List的情况
    final dataField = data['data'];
    if (dataField is List) {
      return dataField.map((e) => AppServiceResponse.fromJson(e as Map<String, dynamic>)).toList();
    } else if (dataField is Map<String, dynamic>) {
      final items = dataField['items'] as List?;
      return items?.map((e) => AppServiceResponse.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    }
    return [];
  }

  /// 获取应用商店配置
  Future<AppstoreConfigResponse> getAppstoreConfig() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/core/settings/apps/store/config'),
    );
    final data = response.data as Map<String, dynamic>;
    return AppstoreConfigResponse.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// 更新应用商店配置
  Future<void> updateAppstoreConfig(AppstoreUpdateRequest request) async {
    await _client.post(
      ApiConstants.buildApiPath('/core/settings/apps/store/update'),
      data: request.toJson(),
    );
  }

  /// 同步本地应用列表
  Future<void> syncLocalApps() async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/sync/local'),
      data: {},
    );
  }

  /// 同步远程应用列表
  Future<void> syncRemoteApps() async {
    await _client.post(
      ApiConstants.buildApiPath('/apps/sync/remote'),
      data: {},
    );
  }
}
