import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/config/api_constants.dart';
import '../../data/models/container_models.dart';
import '../../data/models/common_models.dart';
import '../../data/models/runtime_models.dart';
import '../../data/models/setting_models.dart';
import 'api_response_parser.dart';

/// API响应解析帮助类
class _Parser {
  /// 从1Panel API响应中提取data字段
  static T extractData<T>(Response<Map<String, dynamic>> response,
      T Function(Map<String, dynamic>) fromJson) {
    return ApiResponseParser.extractData(response, fromJson);
  }

  /// 从1Panel API响应中提取data字段（Map类型）
  static Map<String, dynamic> extractMapData(
      Response<Map<String, dynamic>> response) {
    return ApiResponseParser.extractMapData(response);
  }

  static List<T> extractListDataFromMap<T>(
      Response<Map<String, dynamic>> response,
      T Function(Map<String, dynamic>) fromJson) {
    final data = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> extractRawListDataFromMap(
      Response<Map<String, dynamic>> response) {
    final data = ApiResponseParser.asList(
      response.data,
      nestedItemsKey: 'items',
    );
    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  /// 从1Panel API响应中提取data字段（PageResult类型）
  static PageResult<T> extractPageData<T>(
      Response<Map<String, dynamic>> response,
      T Function(Map<String, dynamic>) fromJson) {
    final data = ApiResponseParser.asMap(response.data);
    if (data.isNotEmpty) {
      return PageResult.fromJson(
        data,
        (dynamic item) => fromJson(item as Map<String, dynamic>),
      );
    }
    return PageResult(items: [], total: 0);
  }
}

class ContainerV2Api {
  final DioClient _client;

  ContainerV2Api(this._client);

  /// 创建容器
  Future<Response<void>> createContainer(ContainerOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers'),
      data: request.toJson(),
    );
  }

  /// 通过命令创建容器
  Future<Response<void>> createContainerByCommand(
      ContainerCreateByCommand request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/command'),
      data: request.toJson(),
    );
  }

  /// 操作容器（启动/停止/重启等）
  Future<Response<void>> operateContainer(ContainerOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/operate'),
      data: request.toJson(),
    );
  }

  /// 启动容器
  Future<Response<void>> startContainer(List<String> names) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: ContainerOperationType.start.value,
    ));
  }

  /// 停止容器
  Future<Response<void>> stopContainer(List<String> names,
      {bool force = false}) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: force
          ? ContainerOperationType.kill.value
          : ContainerOperationType.stop.value,
    ));
  }

  /// 强制停止容器 (Kill)
  Future<Response<void>> killContainer(List<String> names) async {
    return await stopContainer(names, force: true);
  }

  /// 重启容器
  Future<Response<void>> restartContainer(List<String> names) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: ContainerOperationType.restart.value,
    ));
  }

  /// 暂停容器
  Future<Response<void>> pauseContainer(List<String> names) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: ContainerOperationType.pause.value,
    ));
  }

  /// 恢复容器
  Future<Response<void>> unpauseContainer(List<String> names) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: ContainerOperationType.unpause.value,
    ));
  }

  /// 删除容器
  Future<Response<void>> deleteContainer(List<String> names,
      {bool force = false}) async {
    return await operateContainer(ContainerOperation(
      names: names,
      operation: ContainerOperationType.remove.value,
    ));
  }

  /// 搜索容器
  Future<Response<PageResult<ContainerInfo>>> searchContainers(
      PageContainer request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, ContainerInfo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器列表
  Future<Response<List<ContainerInfo>>> listContainers() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/list'),
    );
    return Response(
      data: _Parser.extractListDataFromMap(response, ContainerInfo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器统计信息
  Future<Response<ContainerStats>> getContainerStats(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/stats/$id'),
    );
    return Response(
      data: _Parser.extractData(response, ContainerStats.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器列表统计信息
  Future<Response<List<ContainerListStats>>> listContainerStats() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/list/stats'),
    );
    return Response(
      data:
          _Parser.extractListDataFromMap(response, ContainerListStats.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器列表（按镜像分组）
  Future<Response<List<ContainerOption>>> listContainersByImage() async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/list/byimage'),
      data: {},
    );
    return Response(
      data: _Parser.extractListDataFromMap(response, ContainerOption.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器资源占用统计
  Future<Response<ContainerItemStats>> getContainerItemStats(
      OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/item/stats'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractData(response, ContainerItemStats.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器用户列表
  Future<Response<List<String>>> getContainerUsers(
      OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/users'),
      data: request.toJson(),
    );
    final data = response.data?['data'];
    final users = <String>[];
    if (data is List) {
      users.addAll(data.map((item) => item.toString()));
    }
    return Response(
      data: users,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器状态统计
  Future<Response<ContainerStatus>> getContainerStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/status'),
    );
    return Response(
      data: _Parser.extractData(response, ContainerStatus.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取Docker服务状态
  Future<Response<DockerStatus>> getDockerStatus() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/docker/status'),
    );
    return Response(
      data: _Parser.extractData(response, DockerStatus.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 操作Docker服务
  Future<Response<void>> operateDocker(DockerOperation request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/docker/operate'),
      data: request.toJson(),
    );
  }

  /// 更新Docker日志配置
  Future<Response<void>> updateDockerLogOption(LogOption request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/logoption/update'),
      data: request.toJson(),
    );
  }

  /// 更新Docker IPv6配置
  Future<Response<void>> updateDockerIpv6Option(LogOption request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/ipv6option/update'),
      data: request.toJson(),
    );
  }

  /// 升级容器
  Future<Response<void>> upgradeContainer(ContainerUpgrade request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/upgrade'),
      data: request.toJson(),
    );
  }

  /// 重命名容器
  Future<Response<void>> renameContainer(ContainerRename request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/rename'),
      data: request.toJson(),
    );
  }

  /// 提交容器为镜像
  Future<Response<void>> commitContainer(ContainerCommit request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/commit'),
      data: request.toJson(),
    );
  }

  /// 清理容器资源
  Future<Response<void>> pruneContainers(ContainerPrune request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/prune'),
      data: request.toJson(),
    );
  }

  /// 清理容器日志
  Future<Response<void>> cleanContainerLog(OperationWithName request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/clean/log'),
      data: request.toJson(),
    );
  }

  /// 获取容器信息
  Future<Response<ContainerOperate>> getContainerInfo(
      OperationWithName request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/info'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractData(response, ContainerOperate.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 检查容器
  Future<Response<String>> inspectContainer(InspectReq request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/inspect'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器日志
  Future<Response<dynamic>> getContainerLogs({
    required String container,
    String? since,
    bool? follow,
    String? tail,
  }) async {
    final queryParams = <String, dynamic>{
      'container': container,
    };
    if (since != null) queryParams['since'] = since;
    if (follow != null) queryParams['follow'] = follow.toString();
    if (tail != null) queryParams['tail'] = tail;

    // Use ResponseType.plain to handle SSE/text response without JSON parsing error
    final response = await _client.get<dynamic>(
      ApiConstants.buildApiPath('/containers/search/log'),
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.plain),
    );

    // Return the raw 'data' field which might be String, List, or Map
    // For SSE/plain text, response.data will be the string content
    return response;
  }

  /// 获取容器文件列表
  Future<Response<List<ContainerFileInfo>>> searchContainerFiles(
      ContainerFileRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/files/search'),
      data: request.toJson(),
    );
    return Response(
      data:
          _Parser.extractListDataFromMap(response, ContainerFileInfo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器文件内容
  Future<Response<ContainerFileContent>> getContainerFileContent(
      ContainerFileRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/files/content'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractData(response, ContainerFileContent.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取容器文件大小
  Future<Response<int>> getContainerFileSize(
      ContainerFileRequest request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/files/size'),
      data: request.toJson(),
    );
    final data = response.data?['data'];
    final size = (data is num) ? data.toInt() : 0;
    return Response(
      data: size,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除容器文件
  Future<Response<void>> deleteContainerFiles(
      ContainerFileBatchDeleteRequest request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/files/del'),
      data: request.toJson(),
    );
  }

  /// 下载容器文件
  Future<Response<List<int>>> downloadContainerFile(
      ContainerFileRequest request) async {
    final response = await _client.post<List<int>>(
      ApiConstants.buildApiPath('/containers/files/download'),
      data: request.toJson(),
      options: Options(responseType: ResponseType.bytes),
    );
    return Response(
      data: response.data ?? const [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 上传容器文件
  Future<Response> uploadContainerFile({
    required String containerId,
    required String path,
    required MultipartFile file,
  }) async {
    final formData = FormData.fromMap({
      'containerID': containerId,
      'path': path,
      'file': file,
    });
    return await _client.post(
      ApiConstants.buildApiPath('/containers/files/upload'),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// 更新容器
  Future<Response<void>> updateContainer(ContainerOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/update'),
      data: request.toJson(),
    );
  }

  /// 获取容器资源限制
  Future<Response<Map<String, dynamic>>> getContainerLimits() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/limit'),
    );
    return Response(
      data: _Parser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // 镜像管理相关方法
  /// 获取镜像选项
  Future<Response<List<Map<String, dynamic>>>> getImageOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image'),
    );
    return Response(
      data: _Parser.extractRawListDataFromMap(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取所有镜像
  Future<Response<List<Map<String, dynamic>>>> getAllImages() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/all'),
    );
    final data = response.data!;
    final list = data['data'] as List?;
    return Response(
      data: list?.map((item) => item as Map<String, dynamic>).toList() ?? [],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 构建镜像
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

  /// 加载镜像
  Future<Response<void>> loadImage(ImageLoad request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/load'),
      data: request.toJson(),
    );
  }

  /// 拉取镜像
  Future<Response<void>> pullImage(ImagePull request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/pull'),
      data: request.toJson(),
    );
  }

  /// 推送镜像
  Future<Response<void>> pushImage(ImagePush request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/push'),
      data: request.toJson(),
    );
  }

  /// 删除镜像
  Future<Response<ContainerPruneReport>> removeImage(
      BatchDelete request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/remove'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractData(response, ContainerPruneReport.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 保存镜像
  Future<Response<void>> saveImage(ImageSave request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/save'),
      data: request.toJson(),
    );
  }

  /// 搜索镜像
  Future<Response<PageResult<Map<String, dynamic>>>> searchImages(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/image/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, (json) => json),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 标记镜像
  Future<Response<void>> tagImage(ImageTag request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/image/tag'),
      data: request.toJson(),
    );
  }

  // 网络管理相关方法
  /// 获取网络选项
  Future<Response<List<Map<String, dynamic>>>> getNetworkOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/network'),
    );
    return Response(
      data: _Parser.extractRawListDataFromMap(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建网络
  Future<Response<void>> createNetwork(NetworkCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/network'),
      data: request.toJson(),
    );
  }

  /// 删除网络
  Future<Response<void>> deleteNetwork(BatchDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/network/del'),
      data: request.toJson(),
    );
  }

  /// 搜索网络
  Future<Response<PageResult<Map<String, dynamic>>>> searchNetworks(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/network/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, (json) => json),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // 卷管理相关方法
  /// 获取卷选项
  Future<Response<List<Map<String, dynamic>>>> getVolumeOptions() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/volume'),
    );
    return Response(
      data: _Parser.extractRawListDataFromMap(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建卷
  Future<Response<void>> createVolume(VolumeCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/volume'),
      data: request.toJson(),
    );
  }

  /// 删除卷
  Future<Response<void>> deleteVolume(BatchDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/volume/del'),
      data: request.toJson(),
    );
  }

  /// 搜索卷
  Future<Response<PageResult<Map<String, dynamic>>>> searchVolumes(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/volume/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, (json) => json),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // 仓库管理
  /// 获取仓库列表
  Future<Response<List<ContainerRepo>>> getRepos() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/repo'),
    );
    return Response(
      data: _Parser.extractListDataFromMap(response, ContainerRepo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建仓库
  Future<Response<void>> createRepo(ContainerRepoOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/repo'),
      data: request.toJson(),
    );
  }

  /// 更新仓库
  Future<Response<void>> updateRepo(ContainerRepoOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/repo/update'),
      data: request.toJson(),
    );
  }

  /// 获取仓库状态
  Future<Response<dynamic>> getRepoStatus(OperateByID request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/repo/status'),
      data: request.toJson(),
    );
    return Response(
      data: response.data?['data'],
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 删除仓库
  Future<Response<void>> deleteRepo(BatchDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/repo/del'),
      data: request.toJson(),
    );
  }

  /// 搜索仓库
  Future<Response<PageResult<ContainerRepo>>> searchRepos(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/repo/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, ContainerRepo.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // 编排模版
  /// 获取模版列表
  Future<Response<List<ContainerTemplate>>> getTemplates() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/template'),
    );
    return Response(
      data:
          _Parser.extractListDataFromMap(response, ContainerTemplate.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 创建模版
  Future<Response<void>> createTemplate(ContainerTemplateOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/template'),
      data: request.toJson(),
    );
  }

  /// 批量创建模版
  Future<Response<void>> createTemplateBatch(ContainerTemplateBatch request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/template/batch'),
      data: request.toJson(),
    );
  }

  /// 更新模版
  Future<Response<void>> updateTemplate(ContainerTemplateOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/template/update'),
      data: request.toJson(),
    );
  }

  /// 删除模版
  Future<Response<void>> deleteTemplate(BatchDelete request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/template/del'),
      data: request.toJson(),
    );
  }

  /// 搜索模版
  Future<Response<PageResult<ContainerTemplate>>> searchTemplates(
      SearchWithPage request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/template/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, ContainerTemplate.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  // Compose 管理
  /// 创建 Compose 项目
  Future<Response<void>> createCompose(ContainerComposeCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose'),
      data: request.toJson(),
    );
  }

  /// 搜索 Compose 项目
  Future<Response<PageResult<ContainerCompose>>> searchComposeProjects(
    ContainerComposeSearch request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/compose/search'),
      data: request.toJson(),
    );
    return Response(
      data: _Parser.extractPageData(response, ContainerCompose.fromJson),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 操作 Compose 项目
  Future<Response<void>> operateComposeProject(ContainerComposeOperate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose/operate'),
      data: request.toJson(),
    );
  }

  /// 读取 Compose 环境变量
  Future<Response<List<String>>> loadComposeEnv(FilePath request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/compose/env'),
      data: request.toJson(),
    );
    final rawItems = response.data?['data'] as List<dynamic>? ?? const [];
    return Response<List<String>>(
      data: rawItems.map((dynamic item) => item.toString()).toList(
            growable: false,
          ),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 Compose 配置
  Future<Response<void>> updateComposeProject(
    ContainerComposeUpdateRequest request,
  ) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose/update'),
      data: request.toJson(),
    );
  }

  /// 测试 Compose 配置
  Future<Response<void>> testComposeProject(ContainerComposeCreate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose/test'),
      data: request.toJson(),
    );
  }

  /// 清理 Compose 日志
  Future<Response<void>> cleanComposeProjectLog(
    ContainerComposeLogCleanRequest request,
  ) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/compose/clean/log'),
      data: request.toJson(),
    );
  }

  /// 读取 PHP 运行时容器配置
  Future<Response<PHPContainerConfig>> loadPhpContainerConfig(int id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/runtimes/php/container/$id'),
    );
    final rawData = response.data?['data'];
    final config = switch (rawData) {
      Map<String, dynamic> map => PHPContainerConfig.fromJson(map),
      _ => PHPContainerConfig(id: id),
    };
    return Response<PHPContainerConfig>(
      data: config.id == 0 ? config.copyWith(id: id) : config,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新 PHP 运行时容器配置
  Future<Response<void>> updatePhpContainerConfig(PHPContainerConfig request) {
    return _client.post<void>(
      ApiConstants.buildApiPath('/runtimes/php/container/update'),
      data: request.toJson(),
    );
  }

  // 配置
  /// 获取Daemon配置
  Future<Response<Map<String, dynamic>>> getDaemonJson() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/daemonjson'),
    );
    return Response(
      data: _Parser.extractMapData(response),
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 获取Daemon配置内容 (File content)
  Future<Response<String>> getDaemonJsonFile() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.buildApiPath('/containers/daemonjson/file'),
    );
    return Response(
      data: response.data?['data']?.toString() ?? '',
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      requestOptions: response.requestOptions,
    );
  }

  /// 更新Daemon配置（按键值）
  Future<Response<void>> updateDaemonJsonSetting(SettingUpdate request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/daemonjson/update'),
      data: request.toJson(),
    );
  }

  /// 更新Daemon配置（通过文件内容）
  Future<Response<void>> updateDaemonJsonByFile(
      DaemonJsonUpdateByFile request) async {
    return await _client.post<void>(
      ApiConstants.buildApiPath('/containers/daemonjson/update/byfile'),
      data: request.toJson(),
    );
  }
}
