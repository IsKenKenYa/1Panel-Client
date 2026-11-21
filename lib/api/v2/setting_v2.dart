import 'package:dio/dio.dart'
    show Response, Options, ResponseType, DioException;
import '../../core/network/dio_client.dart';
import '../../core/network/network_exceptions.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/setting_models.dart';
import '../../data/models/ssh_settings_models.dart';
import 'api_response_parser.dart';

class SettingV2Api {
  final DioClient _client;

  SettingV2Api(this._client);

  /// Extracts `data` field, filtering HTML error pages that some endpoints
  /// return instead of JSON when the resource does not exist.
  dynamic _extractDataRaw(dynamic responseData) {
    if (responseData is String) {
      final normalized = responseData.trimLeft().toLowerCase();
      if (normalized.startsWith('<!doctype html') ||
          normalized.startsWith('<html')) {
        return null;
      }
      return responseData;
    }
    return ApiResponseParser.unwrap(responseData);
  }

  // Some endpoints moved from /settings/* to /core/settings/* in newer versions.
  bool _shouldFallbackToLegacySettingsPath(Object error) {
    if (error is EndpointNotFoundException) {
      return true;
    }
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      return statusCode == 404 || statusCode == 405;
    }
    if (error is NetworkException) {
      final statusCode = error.statusCode;
      return statusCode == 404 || statusCode == 405;
    }
    return false;
  }

  /// 获取系统设置
  ///
  /// 获取系统设置信息
  /// @return 系统设置
  Future<Response<SystemSettingInfo>> getSystemSettings() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/search'),
      options: DioClient.sensitiveOptions,
    );
    final data = ApiResponseParser.asMapOrNull(response.data);
    return Response(
      data: data != null ? SystemSettingInfo.fromJson(data) : null,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }


  /// 更新系统设置
  ///
  /// 更新系统设置
  /// @param request 设置更新请求
  /// @return 更新结果
  Future<Response<void>> updateSystemSetting(SettingUpdate request) async {
    try {
      return await _client.post(
        ApiConstants.buildApiPath('/core/settings/update'),
        data: request.toJson(),
      );
    } catch (error) {
      if (!_shouldFallbackToLegacySettingsPath(error)) {
        rethrow;
      }
      return await _client.post(
        ApiConstants.buildApiPath('/settings/update'),
        data: request.toJson(),
      );
    }
  }

  /// 获取系统信息
  ///
  /// 获取系统基本信息
  /// @return 系统信息
  Future<Response<SystemInfo>> getSystemInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/dashboard/base/os'),
    );
    final data = ApiResponseParser.asMapOrNull(response.data);
    return Response(
      data: data != null ? SystemInfo.fromJson(data) : null,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取终端设置
  ///
  /// 获取终端设置信息
  /// @return 终端设置
  Future<Response<TerminalInfo>> getTerminalSettings() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/terminal/search'),
    );
    final data = ApiResponseParser.asMapOrNull(response.data);
    return Response(
      data: data != null ? TerminalInfo.fromJson(data) : null,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新终端设置
  ///
  /// 更新终端设置
  /// @param request 终端设置更新请求
  /// @return 更新结果
  Future<Response<void>> updateTerminalSettings(TerminalUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/terminal/update'),
      data: request.toJson(),
    );
  }

  /// 获取网络接口列表
  ///
  /// 获取服务器网络接口IP地址列表
  /// @return IP地址列表
  Future<Response<List<String>>> getNetworkInterfaces() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/interface'),
    );
    final data = ApiResponseParser.asListOrNull(response.data);
    return Response(
      data: data != null ? List<String>.from(data) : null,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  Future<Response<String?>> getDashboardMemo() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/settings/memo'),
    );
    final memo = _extractDataRaw(response.data);
    return Response<String?>(
      data: memo?.toString(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
      headers: response.headers,
      extra: response.extra,
      redirects: response.redirects,
      isRedirect: response.isRedirect,
    );
  }

  Future<Response<void>> updateDashboardMemo(MemoUpdate request) async {
    return _client.post<void>(
      ApiConstants.buildApiPath('/core/settings/memo'),
      data: request.toJson(),
    );
  }

  /// 更新端口设置
  ///
  /// 更新系统端口设置
  /// @param request 端口更新请求
  /// @return 更新结果
  Future<Response<void>> updatePortSettings(PortUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/port/update'),
      data: request.toJson(),
    );
  }

  /// 更新代理设置
  ///
  /// 更新系统代理设置
  /// @param request 代理更新请求
  /// @return 更新结果
  Future<Response<void>> updateProxySettings(ProxyUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/proxy/update'),
      data: request.toJson(),
    );
  }

  /// 更新绑定设置
  ///
  /// 更新绑定相关设置
  /// @param request 绑定更新请求
  /// @return 更新结果
  Future<Response<void>> updateBindSettings(BindUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/bind/update'),
      data: request.toJson(),
    );
  }

  /// 更新菜单设置
  ///
  /// 更新系统菜单设置
  /// @param request 菜单更新请求
  /// @return 更新结果
  Future<Response<void>> updateMenuSettings(MenuUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/menu/update'),
      data: request.toJson(),
    );
  }

  /// 获取默认菜单
  ///
  /// 获取默认菜单配置
  /// @return 默认菜单
  Future<Response<dynamic>> getDefaultMenu() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/menu/default'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取应用商店配置
  ///
  /// 获取应用商店配置信息
  /// @return 应用商店配置
  Future<Response<dynamic>> getAppStoreConfig() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/apps/store/config'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新应用商店配置
  ///
  /// 更新应用商店配置
  /// @param request 应用商店配置更新请求
  /// @return 更新结果
  Future<Response<void>> updateAppStoreConfig(
      AppStoreConfigUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/apps/store/update'),
      data: request.toJson(),
    );
  }

  // ==================== 快照相关API ====================

  /// 获取基础目录设置
  ///
  /// 获取基础目录配置信息
  /// @return 基础目录设置
  Future<Response<dynamic>> getBaseDir() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/settings/basedir'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 通过key获取设置（settings路径）
  ///
  /// 通过key获取设置
  /// @param key 设置key
  /// @return 设置值
  Future<Response<dynamic>> getSettingByKey(String key) async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/settings/get/$key'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 搜索设置
  ///
  /// 搜索系统设置
  /// @return 设置信息
  Future<Response<dynamic>> searchSettings() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/settings/search'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 检查设置可用性
  ///
  /// 检查设置是否可用
  /// @return 可用性结果
  Future<Response<dynamic>> checkSettingsAvailable() async {
    Response<dynamic> response;
    try {
      response = await _client.get(
        ApiConstants.buildApiPath('/core/settings/search/available'),
      );
    } catch (error) {
      if (!_shouldFallbackToLegacySettingsPath(error)) {
        rethrow;
      }
      response = await _client.get(
        ApiConstants.buildApiPath('/settings/search/available'),
      );
    }
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 保存描述
  ///
  /// 保存系统描述
  /// @param request 描述保存请求
  /// @return 保存结果
  Future<Response<void>> saveDescription(DescriptionSave request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/description/save'),
      data: request.toJson(),
    );
  }

  // ==================== SSL相关API ====================

  /// 获取SSL证书信息
  ///
  /// 获取系统SSL证书信息
  /// @return SSL证书信息
  Future<Response<Map<String, dynamic>>> getSSLInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/ssl/info'),
      options: DioClient.sensitiveOptions,
    );
    final data = ApiResponseParser.unwrap(response.data);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('面板证书信息格式无效');
    }
    return Response(
      data: {
        for (final field in ['domain', 'timeout', 'rootPath'])
          if (data[field] is String && (data[field] as String).isNotEmpty)
            field: data[field],
        if (data['sslID'] is int && data['sslID'] != 0) 'sslID': data['sslID'],
      },
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新SSL设置
  ///
  /// 更新系统SSL设置
  /// @param request SSL更新请求
  /// @return 更新结果
  Future<Response<void>> updateSSL(SSLUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/ssl/update'),
      data: request.toJson(),
      options: DioClient.sensitiveOptions,
    );
  }

  /// 下载SSL证书
  ///
  /// 下载系统SSL证书
  /// @return 证书文件数据
  Future<Response<List<int>>> downloadSSL() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/ssl/download'),
      options: DioClient.sensitiveOptions.copyWith(responseType: ResponseType.bytes),
    );
    return Response(
      data: response.data as List<int>,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 升级相关API ====================

  /// 获取升级信息
  ///
  /// 获取系统升级信息
  /// @return 升级信息
  Future<Response<dynamic>> getUpgradeInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/upgrade'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 执行升级
  ///
  /// 执行系统升级
  /// @param request 升级请求
  /// @return 升级结果
  Future<Response<void>> upgrade(UpgradeRequest request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/core/settings/upgrade'),
      data: request.toJson(),
    );
  }

  /// 获取版本发布说明
  ///
  /// 获取指定版本的发布说明
  /// @param request 版本请求
  /// @return 发布说明
  Future<Response<String>> getReleaseNotes(ReleaseNotesRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/core/settings/upgrade/notes'),
      data: request.toJson(),
    );
    return Response(
      data: _extractDataRaw(response.data) as String?,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取升级版本列表
  ///
  /// 获取可升级的版本列表
  /// @return 版本列表
  Future<Response<List<dynamic>>> getUpgradeReleases() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/settings/upgrade/releases'),
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return Response(
      data: ApiResponseParser.asListOrNull(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取备份账户选项
  ///
  /// 获取可用的备份账户列表
  /// @return 备份账户列表
  Future<Response<List<Map<String, dynamic>>>> getBackupAccountOptions() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/backups/options'),
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>?;
    return Response(
      data: items?.cast<Map<String, dynamic>>() ?? [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除备份账户
  ///
  /// 删除指定的备份账户
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response<void>> deleteBackupAccount(
      BackupAccountDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/backups/del'),
      data: request.toJson(),
    );
  }

  // ==================== 快照相关API ====================

  /// 创建快照
  ///
  /// 创建系统快照
  /// @param request 快照创建请求
  /// @return 创建结果
  Future<Response<void>> createSnapshot(SnapshotCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot'),
      data: request.toJson(),
    );
  }

  /// 删除快照
  ///
  /// 删除指定快照
  /// @param request 删除请求
  /// @return 删除结果
  Future<Response<void>> deleteSnapshot(SnapshotDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/del'),
      data: request.toJson(),
    );
  }

  /// 更新快照描述
  ///
  /// 更新快照描述信息
  /// @param request 描述更新请求
  /// @return 更新结果
  Future<Response<void>> updateSnapshotDescription(
      SnapshotDescriptionUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/description/update'),
      data: request.toJson(),
    );
  }

  /// 导入快照
  ///
  /// 导入系统快照
  /// @param request 导入请求
  /// @return 导入结果
  Future<Response<void>> importSnapshot(SnapshotImport request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/import'),
      data: request.toJson(),
    );
  }

  /// 加载快照数据
  ///
  /// 加载系统快照数据
  /// @return 快照数据
  Future<Response<dynamic>> loadSnapshot() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/settings/snapshot/load'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 恢复快照
  ///
  /// 从快照恢复系统
  /// @param request 恢复请求
  /// @return 恢复结果
  Future<Response<void>> recoverSnapshot(SnapshotRecover request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/recover'),
      data: request.toJson(),
    );
  }

  /// 重建快照
  ///
  /// 重建系统快照
  /// @param request 重建请求
  /// @return 重建结果
  Future<Response<void>> recreateSnapshot(SnapshotRecreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/recreate'),
      data: request.toJson(),
    );
  }

  /// 回滚快照
  ///
  /// 回滚系统快照
  /// @param request 回滚请求
  /// @return 回滚结果
  Future<Response<void>> rollbackSnapshot(SnapshotRollback request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/rollback'),
      data: request.toJson(),
    );
  }

  /// 搜索快照
  ///
  /// 分页搜索快照列表
  /// @param request 搜索请求
  /// @return 快照列表
  Future<Response<dynamic>> searchSnapshots(SnapshotSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/settings/snapshot/search'),
      data: request.toJson(),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== SSH相关API ====================

  /// 保存SSH连接信息
  ///
  /// 保存本地SSH连接信息
  /// @param request SSH连接请求
  /// @return 保存结果
  Future<Response<void>> saveSSHConnection(SSHConnectionSave request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/ssh'),
      data: request.toJson(),
    );
  }

  /// 检查SSH连接信息
  ///
  /// 检查本地SSH连接信息
  /// @param request 检查请求
  /// @return 检查结果
  Future<Response<bool>> checkSSHConnection(
      SSHConnectionCheck request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/ssh/check/info'),
      data: request.toJson(),
    );
    return Response<bool>(
      data: _extractDataRaw(response.data) as bool?,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取SSH连接
  ///
  /// 获取本地SSH连接信息
  /// @return SSH连接信息
  Future<Response<SshLocalConnectionInfo>> getSSHConnection() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/ssh/conn'),
    );
    final data = _extractDataRaw(response.data);
    return Response<SshLocalConnectionInfo>(
      data: SshLocalConnectionInfo.fromJson(
        data is Map<String, dynamic> ? data : const <String, dynamic>{},
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新默认SSH连接
  ///
  /// 更新本地默认SSH连接
  /// @param request 更新请求
  /// @return 更新结果
  Future<Response<void>> updateDefaultSSHConnection(
      SSHDefaultUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/settings/ssh/default'),
      data: request.toJson(),
    );
  }

  // ==================== 认证相关API ====================

  /// 获取登录设置
  ///
  /// 获取登录页面的设置信息
  /// @return 登录设置
  Future<Response<dynamic>> getAuthSetting() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/core/auth/setting'),
    );
    return Response(
      data: _extractDataRaw(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 重置系统设置
  Future<Response<void>> resetSystemSetting() async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/core/settings/reset'),
    );
  }

  /// 获取监控设置
  Future<Response<Map<String, dynamic>>> getMonitorSetting() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/hosts/monitor/setting'),
    );
    final data = ApiResponseParser.asMapOrNull(response.data);
    return Response(
      data: data,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新监控设置
  Future<Response<void>> updateMonitorSetting(String key, String value) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/hosts/monitor/setting/update'),
      data: {'key': key, 'value': value},
    );
  }

  // ==================== New settings endpoints (R5 API adaptation) ====================

  /// Search file history settings.
  Future<Response<Map<String, dynamic>>> searchFileHistory() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/file-history/search'),
    );
    return Response<Map<String, dynamic>>(
      data: response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Update file history settings.
  Future<void> updateFileHistory(Map<String, dynamic> request) async {
    await _client.post<dynamic>(
      ApiConstants.buildApiPath('/settings/file-history/update'),
      data: request,
    );
  }

  /// Search file manage AI settings.
  Future<Response<Map<String, dynamic>>> searchFilesAi() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/files/ai/search'),
    );
    return Response<Map<String, dynamic>>(
      data: response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Update file manage AI settings.
  Future<void> updateFilesAi(Map<String, dynamic> request) async {
    await _client.post<dynamic>(
      ApiConstants.buildApiPath('/settings/files/ai/update'),
      data: request,
    );
  }

  /// Search terminal AI settings.
  Future<Response<Map<String, dynamic>>> searchTerminalAi() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/terminal/ai/search'),
    );
    return Response<Map<String, dynamic>>(
      data: response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Update terminal AI settings.
  Future<void> updateTerminalAi(Map<String, dynamic> request) async {
    await _client.post<dynamic>(
      ApiConstants.buildApiPath('/settings/terminal/ai/update'),
      data: request,
    );
  }

  /// Check SSH local connection (POST /settings/ssh/check).
  Future<Response<Map<String, dynamic>>> checkSshConnection(
      Map<String, dynamic> request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/settings/ssh/check'),
      data: request,
    );
    return Response<Map<String, dynamic>>(
      data: response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Load base system setting info (POST /core/settings/search/base).
  Future<Response<Map<String, dynamic>>> searchBaseSettings() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/core/settings/search/base'),
    );
    return Response<Map<String, dynamic>>(
      data: response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{},
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// Load website dir setting (GET /settings/website/dir).
  Future<Response<String>> getWebsiteDir() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/settings/website/dir'),
    );
    return Response<String>(
      data: response.data?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取模型下载器设置。
  Future<Response<ModelDownloaderSetting>> getModelDownloaderSettings() async {
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/xpack/model/downloader/settings'),
    );
    final data = ApiResponseParser.asMapOrNull(response.data);
    return Response<ModelDownloaderSetting>(
      data: data != null ? ModelDownloaderSetting.fromJson(data) : null,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新模型下载器设置。
  Future<Response<void>> updateModelDownloaderSettings(
      ModelDownloaderSetting request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/xpack/model/downloader/settings'),
      data: request.toJson(),
    );
  }
}

// ==================== 请求模型 ====================

class SettingUpdate {
  final String key;
  final String value;

  const SettingUpdate({required this.key, required this.value});

  Map<String, dynamic> toJson() => {'key': key, 'value': value};
}

class TerminalUpdate {
  final String? lineTheme;
  final String? fontSize;
  final String? fontFamily;
  final String? backgroundColor;
  final String? foregroundColor;
  final String? cursorStyle;
  final String? cursorBlink;
  final String? scrollSensitivity;
  final String? scrollback;
  final String? lineHeight;
  final String? letterSpacing;

  const TerminalUpdate({
    this.lineTheme,
    this.fontSize,
    this.fontFamily,
    this.backgroundColor,
    this.foregroundColor,
    this.cursorStyle,
    this.cursorBlink,
    this.scrollSensitivity,
    this.scrollback,
    this.lineHeight,
    this.letterSpacing,
  });

  Map<String, dynamic> toJson() => {
        if (lineTheme != null) 'lineTheme': lineTheme,
        if (fontSize != null) 'fontSize': fontSize,
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (foregroundColor != null) 'foregroundColor': foregroundColor,
        if (cursorStyle != null) 'cursorStyle': cursorStyle,
        if (cursorBlink != null) 'cursorBlink': cursorBlink,
        if (scrollSensitivity != null) 'scrollSensitivity': scrollSensitivity,
        if (scrollback != null) 'scrollback': scrollback,
        if (lineHeight != null) 'lineHeight': lineHeight,
        if (letterSpacing != null) 'letterSpacing': letterSpacing,
      };
}

class PortUpdate {
  final int port;

  const PortUpdate({required this.port});

  Map<String, dynamic> toJson() => {'port': port};
}

class ProxyUpdate {
  final String? proxyUrl;
  final int? proxyPort;

  const ProxyUpdate({this.proxyUrl, this.proxyPort});

  Map<String, dynamic> toJson() => {
        if (proxyUrl != null) 'proxyUrl': proxyUrl,
        if (proxyPort != null) 'proxyPort': proxyPort,
      };
}

class BindUpdate {
  final String? bindAddress;

  const BindUpdate({this.bindAddress});

  Map<String, dynamic> toJson() => {
        if (bindAddress != null) 'bindAddress': bindAddress,
      };
}

class MenuUpdate {
  final List<String> menus;

  const MenuUpdate({required this.menus});

  Map<String, dynamic> toJson() => {'menus': menus};
}

class ExpiredHandle {
  final String? method;

  const ExpiredHandle({this.method});

  Map<String, dynamic> toJson() => {if (method != null) 'method': method};
}

class AppStoreConfigUpdate {
  final String? storeUrl;

  const AppStoreConfigUpdate({this.storeUrl});

  Map<String, dynamic> toJson() => {if (storeUrl != null) 'storeUrl': storeUrl};
}

class DescriptionSave {
  final String description;

  const DescriptionSave({required this.description});

  Map<String, dynamic> toJson() => {'description': description};
}

// ==================== SSL请求模型 ====================

class SSLUpdate {
  final String ssl;
  final String cert;
  final String key;

  SSLUpdate.importPem({
    required String? currentMode,
    required this.cert,
    required this.key,
  }) : ssl = switch (currentMode) {
          'Enable' || 'Disable' => 'Enable',
          'Mux' => 'Mux',
          _ => throw const FormatException('无法识别面板 HTTPS 设置'),
        };

  Map<String, dynamic> toJson() => {
        'ssl': ssl,
        'sslType': 'import-paste',
        'cert': cert,
        'key': key,
      };
}

// ==================== 升级请求模型 ====================

class UpgradeRequest {
  final String? version;

  const UpgradeRequest({this.version});

  Map<String, dynamic> toJson() => {if (version != null) 'version': version};
}

class ReleaseNotesRequest {
  final String version;

  const ReleaseNotesRequest({required this.version});

  Map<String, dynamic> toJson() => {'version': version};
}

// ==================== 快照请求模型 ====================

class SnapshotCreate {
  final String? description;
  final String sourceAccountIDs;
  final int downloadAccountID;

  const SnapshotCreate({
    this.description,
    required this.sourceAccountIDs,
    required this.downloadAccountID,
  });

  Map<String, dynamic> toJson() => {
        if (description != null) 'description': description,
        'sourceAccountIDs': sourceAccountIDs,
        'downloadAccountID': downloadAccountID,
      };
}

class SnapshotDelete {
  final List<int> ids;

  const SnapshotDelete({required this.ids});

  Map<String, dynamic> toJson() => {'ids': ids};
}

class SnapshotDescriptionUpdate {
  final int id;
  final String description;

  const SnapshotDescriptionUpdate(
      {required this.id, required this.description});

  Map<String, dynamic> toJson() => {'id': id, 'description': description};
}

class SnapshotImport {
  final String path;

  const SnapshotImport({required this.path});

  Map<String, dynamic> toJson() => {'path': path};
}

class SnapshotRecover {
  final int id;

  const SnapshotRecover({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

class SnapshotRecreate {
  final int id;

  const SnapshotRecreate({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

class SnapshotRollback {
  final int id;

  const SnapshotRollback({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

class SnapshotSearch {
  final int page;
  final int pageSize;
  final String orderBy;
  final String order;

  const SnapshotSearch({
    this.page = 1,
    this.pageSize = 10,
    this.orderBy = 'createdAt',
    this.order = 'descending',
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
        'orderBy': orderBy,
        'order': order,
      };
}

class BackupAccountDelete {
  final int id;

  const BackupAccountDelete({required this.id});

  Map<String, dynamic> toJson() => {'id': id};
}

// ==================== SSH请求模型 ====================

class SSHConnectionSave {
  final String? addr;
  final int? port;
  final String? user;
  final String? authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;
  final String? localSSHConnShow;

  const SSHConnectionSave(
      {this.addr,
      this.port,
      this.user,
      this.authMode,
      this.password,
      this.privateKey,
      this.passPhrase,
      this.localSSHConnShow});

  Map<String, dynamic> toJson() => {
        if (addr != null) 'addr': addr,
        if (port != null) 'port': port,
        if (user != null) 'user': user,
        if (authMode != null) 'authMode': authMode,
        if (password != null) 'password': password,
        if (privateKey != null) 'privateKey': privateKey,
        if (passPhrase != null) 'passPhrase': passPhrase,
        if (localSSHConnShow != null) 'localSSHConnShow': localSSHConnShow,
      };
}

class SSHConnectionCheck {
  final String? addr;
  final int? port;
  final String? user;
  final String? authMode;
  final String? password;
  final String? privateKey;
  final String? passPhrase;

  const SSHConnectionCheck({
    this.addr,
    this.port,
    this.user,
    this.authMode,
    this.password,
    this.privateKey,
    this.passPhrase,
  });

  Map<String, dynamic> toJson() => {
        if (addr != null) 'addr': addr,
        if (port != null) 'port': port,
        if (user != null) 'user': user,
        if (authMode != null) 'authMode': authMode,
        if (password != null) 'password': password,
        if (privateKey != null) 'privateKey': privateKey,
        if (passPhrase != null) 'passPhrase': passPhrase,
      };
}

class SSHDefaultUpdate {
  final bool withReset;
  final String defaultConn;

  const SSHDefaultUpdate({
    required this.withReset,
    required this.defaultConn,
  });

  Map<String, dynamic> toJson() => {
        'withReset': withReset,
        'defaultConn': defaultConn,
      };
}
