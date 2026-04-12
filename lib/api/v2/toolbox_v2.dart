import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/toolbox_models.dart';
import '../../data/models/common_models.dart';

class ToolboxV2Api {
  final DioClient _client;

  ToolboxV2Api(this._client);

  // ==================== Clam 病毒扫描 ====================

  /// 创建Clam扫描任务
  Future<Response> createClam(ClamCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam'),
      data: request.toJson(),
    );
  }

  /// 获取Clam基础信息
  Future<Response<ClamBaseInfo>> getClamBaseInfo() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/base'),
    );
    return Response(
      data: ClamBaseInfo.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除Clam扫描任务
  Future<Response> deleteClam(ClamDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/del'),
      data: request.toJson(),
    );
  }

  /// 搜索Clam扫描文件
  Future<Response<PageResult<ClamFileInfo>>> searchClamFiles(
      ClamFileReq request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/file/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => ClamFileInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新Clam扫描文件
  Future<Response> updateClamFile(ClamFileReq request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/file/update'),
      data: request.toJson(),
    );
  }

  /// 操作Clam服务
  Future<Response> operateClam(String operation) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/operate'),
      data: <String, dynamic>{'operation': operation},
    );
  }

  /// 执行Clam扫描任务
  Future<Response> handleClam(OperateByID request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/handle'),
      data: request.toJson(),
    );
  }

  /// 清理Clam扫描记录
  Future<Response> cleanClamRecords(OperateByID request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/record/clean'),
      data: request.toJson(),
    );
  }

  /// 搜索Clam扫描记录
  Future<Response<PageResult<ClamLogInfo>>> searchClamRecords(
      ClamLogSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/record/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => ClamLogInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 搜索Clam扫描任务
  Future<Response<PageResult<ClamBaseInfo>>> searchClam(
      PageRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => ClamBaseInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新Clam扫描状态
  Future<Response> updateClamStatus(ClamUpdateStatus request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/status/update'),
      data: request.toJson(),
    );
  }

  /// 更新Clam扫描任务
  Future<Response> updateClam(ClamUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clam/update'),
      data: request.toJson(),
    );
  }

  // ==================== 系统清理 ====================

  /// 系统清理
  Future<Response> cleanSystem(Clean request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/clean'),
      data: request.toJson(),
    );
  }

  /// 获取清理数据列表
  Future<Response<List<CleanData>>> getCleanData() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/clean/data'),
    );
    return Response(
      data: (response.data as List<dynamic>)
          .map((e) => CleanData.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取清理日志
  Future<Response<PageResult<CleanLog>>> getCleanLogs(
      PageRequest request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/clean/log'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => CleanLog.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取清理树形结构
  Future<Response<List<CleanTree>>> getCleanTree() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/clean/tree'),
    );
    return Response(
      data: (response.data as List<dynamic>)
          .map((e) => CleanTree.fromJson(e as Map<String, dynamic>))
          .toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== 设备管理 ====================

  /// 获取设备基础信息
  Future<Response<DeviceBaseInfo>> getDeviceBaseInfo() async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/base'),
    );
    return Response(
      data: DeviceBaseInfo.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 检查DNS配置
  Future<Response> checkDNS(String dns) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/check/dns'),
      data: {'dns': dns},
    );
  }

  /// 获取设备配置
  Future<Response<List<String>>> getDeviceConf(String name) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/conf'),
      data: {'name': name},
    );
    return Response(
      data: (response.data as List<dynamic>).map((e) => e as String).toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 通过配置更新设备
  Future<Response> updateDeviceByConf(String conf) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/update/byconf'),
      data: {'conf': conf},
    );
  }

  /// 更新设备配置
  Future<Response> updateDeviceConf(DeviceConfUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/update/conf'),
      data: request.toJson(),
    );
  }

  /// 更新设备主机名
  Future<Response> updateDeviceHostname(String hostname) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/update/host'),
      data: {'hostname': hostname},
    );
  }

  /// 更新设备密码
  Future<Response> updateDevicePassword(DevicePasswdUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/update/passwd'),
      data: request.toJson(),
    );
  }

  /// 更新交换分区
  Future<Response> updateDeviceSwap(String swap) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/device/update/swap'),
      data: {'swap': swap},
    );
  }

  /// 获取设备用户列表
  Future<Response<List<String>>> getDeviceUsers() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/device/users'),
    );
    return Response(
      data: (response.data as List<dynamic>).map((e) => e as String).toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取时区选项
  Future<Response<List<String>>> getDeviceZoneOptions() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/device/zone/options'),
    );
    return Response(
      data: (response.data as List<dynamic>).map((e) => e as String).toList(),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // ==================== Fail2ban 入侵防护 ====================

  /// 获取Fail2ban基础信息
  Future<Response<Fail2banBaseInfo>> getFail2banBaseInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/fail2ban/base'),
    );
    return Response(
      data: Fail2banBaseInfo.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 加载Fail2ban配置
  Future<Response<String>> loadFail2banConf() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/fail2ban/load/conf'),
    );
    return Response(
      data: response.data as String,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 操作Fail2ban
  Future<Response> operateFail2ban(String operation) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/fail2ban/operate'),
      data: <String, dynamic>{'operation': operation},
    );
  }

  /// 操作Fail2ban SSHD
  Future<Response> operateFail2banSshd(Fail2banSet request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/fail2ban/operate/sshd'),
      data: request.toJson(),
    );
  }

  /// 搜索Fail2ban记录
  Future<Response<PageResult<Fail2banRecord>>> searchFail2ban(
      Fail2banSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/fail2ban/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => Fail2banRecord.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新Fail2ban配置
  Future<Response> updateFail2ban(Fail2banUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/fail2ban/update'),
      data: request.toJson(),
    );
  }

  /// 通过配置更新Fail2ban
  Future<Response> updateFail2banByConf(String conf) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/fail2ban/update/byconf'),
      data: {'conf': conf},
    );
  }

  // ==================== FTP 管理 ====================

  /// 创建FTP账户
  Future<Response> createFtp(FtpCreate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp'),
      data: request.toJson(),
    );
  }

  /// 获取FTP基础信息
  Future<Response<FtpBaseInfo>> getFtpBaseInfo() async {
    final response = await _client.get(
      ApiConstants.buildApiPath('/toolbox/ftp/base'),
    );
    return Response(
      data: FtpBaseInfo.fromJson(response.data),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除FTP账户
  Future<Response> deleteFtp(FtpDelete request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/del'),
      data: request.toJson(),
    );
  }

  /// 搜索FTP日志
  Future<Response<PageResult<dynamic>>> searchFtpLogs(
      FtpLogSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/log/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 操作FTP服务
  Future<Response> operateFtp(String operation) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/operate'),
      data: <String, dynamic>{'operation': operation},
    );
  }

  /// 搜索FTP账户
  Future<Response<PageResult<FtpInfo>>> searchFtp(FtpSearch request) async {
    final response = await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/search'),
      data: request.toJson(),
    );
    return Response(
      data: PageResult.fromJson(
        response.data,
        (json) => FtpInfo.fromJson(json as Map<String, dynamic>),
      ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 同步FTP配置
  Future<Response> syncFtp({List<int> ids = const <int>[]}) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/sync'),
      data: <String, dynamic>{'ids': ids},
    );
  }

  /// 更新FTP账户
  Future<Response> updateFtp(FtpUpdate request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/ftp/update'),
      data: request.toJson(),
    );
  }

  // ==================== 系统扫描 ====================

  /// 系统扫描
  Future<Response> scanSystem(Scan request) async {
    return await _client.post(
      ApiConstants.buildApiPath('/toolbox/scan'),
      data: request.toJson(),
    );
  }
}
