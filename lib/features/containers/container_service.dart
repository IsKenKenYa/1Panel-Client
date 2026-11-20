import 'dart:convert';

import 'package:dio/dio.dart';
import '../../api/v2/compose_v2.dart';
import '../../api/v2/container_v2.dart';
import '../../core/network/api_client_manager.dart';
import '../../core/services/base_component.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_extension_models.dart';
import '../../data/models/container_models.dart';
import '../../data/models/docker_models.dart';
import '../../data/repositories/container_repository.dart';

class ContainerService extends BaseComponent {
  ContainerService({
    ContainerRepository? repository,
    ContainerV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _repository = repository ??
            ContainerRepository(
              clientManager: clientManager,
              api: api,
            );

  final ContainerRepository _repository;
  // Compose API uses a separate client because it lives in a different API module
  // than container operations (ComposeV2Api vs ContainerV2Api).
  ComposeV2Api? _composeApi;

  Future<ContainerV2Api> _ensureApi() async {
    return _repository.ensureApi();
  }

  Future<ComposeV2Api> _ensureComposeApi() async {
    return _composeApi ??= await ApiClientManager.instance.getComposeApi();
  }

  void resetForServerChange() {
    _repository.resetForServerChange();
    _composeApi = null;
  }

  Future<List<ContainerInfo>> listContainers() {
    return runGuarded(() async {
      final api = await _ensureApi();
      // pageSize 100 is a pragmatic limit; the server API doesn't support unbounded queries.
      final response = await api.searchContainers(PageContainer(
        page: 1,
        pageSize: 100,
        state: 'all',
      ));
      return response.data?.items ?? [];
    });
  }

  Future<List<ContainerImage>> listImages() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getAllImages();
      return response.data
              ?.map((item) => ContainerImage.fromJson(item))
              .toList() ??
          [];
    });
  }

  Future<void> createContainer(ContainerOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createContainer(request);
    });
  }

  Future<void> createContainerByCommand(ContainerCreateByCommand request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createContainerByCommand(request);
    });
  }

  Future<void> startContainer(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.startContainer([containerId]);
    });
  }

  Future<void> stopContainer(String containerId, {bool force = false}) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.stopContainer([containerId], force: force);
    });
  }

  Future<void> killContainer(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.killContainer([containerId]);
    });
  }

  Future<void> restartContainer(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.restartContainer([containerId]);
    });
  }

  Future<void> removeContainer(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.deleteContainer([containerId]);
    });
  }

  Future<void> renameContainer(ContainerRename request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.renameContainer(request);
    });
  }

  Future<void> upgradeContainer(ContainerUpgrade request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.upgradeContainer(request);
    });
  }

  Future<void> commitContainer(ContainerCommit request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.commitContainer(request);
    });
  }

  Future<ContainerPruneReport> pruneContainers(ContainerPrune request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.pruneContainers(request);
      return response.data ?? const ContainerPruneReport();
    });
  }

  Future<void> updateContainer(ContainerOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateContainer(request);
    });
  }

  Future<void> cleanContainerLog(String name) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.cleanContainerLog(OperationWithName(name: name));
    });
  }

  Future<void> removeImage(int imageId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.removeImage(BatchDelete(ids: [imageId]));
    });
  }

  Future<ContainerStats> getContainerStats(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerStats(containerId);
      return response.data ??
          const ContainerStats(
            cache: 0,
            cpuPercent: 0,
            ioRead: 0,
            ioWrite: 0,
            memory: 0,
            networkRX: 0,
            networkTX: 0,
          );
    });
  }

  Future<DockerStatus> getDockerStatus() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getDockerStatus();
      return response.data ?? const DockerStatus(isActive: false, isExist: false);
    });
  }

  Future<void> operateDocker(DockerOperation request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.operateDocker(request);
    });
  }

  Future<void> updateDockerLogOption(LogOption request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateDockerLogOption(request);
    });
  }

  Future<void> updateDockerIpv6Option(LogOption request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateDockerIpv6Option(request);
    });
  }

  Future<List<ContainerOption>> listContainersByImage() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.listContainersByImage();
      return response.data ?? [];
    });
  }

  Future<ContainerItemStats> getContainerItemStats(String name) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response =
          await api.getContainerItemStats(OperationWithName(name: name));
      return response.data ?? const ContainerItemStats();
    });
  }

  Future<List<String>> getContainerUsers(String name) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response =
          await api.getContainerUsers(OperationWithName(name: name));
      return response.data ?? [];
    });
  }

  Future<List<ContainerFileInfo>> searchContainerFiles({
    required String containerId,
    required String path,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.searchContainerFiles(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data ?? [];
    });
  }

  Future<ContainerFileContent> getContainerFileContent({
    required String containerId,
    required String path,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerFileContent(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data ??
          const ContainerFileContent(
            content: '',
            isBinary: false,
            size: 0,
            truncated: false,
          );
    });
  }

  Future<int> getContainerFileSize({
    required String containerId,
    required String path,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerFileSize(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data ?? 0;
    });
  }

  Future<void> deleteContainerFiles({
    required String containerId,
    required List<String> paths,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.deleteContainerFiles(
        ContainerFileBatchDeleteRequest(containerId: containerId, paths: paths),
      );
    });
  }

  Future<List<int>> downloadContainerFile({
    required String containerId,
    required String path,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.downloadContainerFile(
        ContainerFileRequest(containerId: containerId, path: path),
      );
      return response.data ?? [];
    });
  }

  Future<void> uploadContainerFile({
    required String containerId,
    required String path,
    required MultipartFile file,
  }) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.uploadContainerFile(
        containerId: containerId,
        path: path,
        file: file,
      );
    });
  }

  /// 容器日志（纯文本）。
  ///
  /// 上游日志下载接口直接返回 text/plain，空响应表示容器没有 stdout 输出。
  Future<String> getContainerLogs(String containerName,
      {String? since, String? tail}) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerLogs(
        container: containerName,
        since: since,
        tail: tail,
      );
      return (response.data as String?)?.trimRight() ?? '';
    });
  }

  /// 容器日志跟随流。
  ///
  /// 服务端以 base64 SSE 帧持续推送；[follow] 为 false 时只回放
  /// [tail] 行随后结束。
  Stream<String> streamContainerLogs(
    String containerName, {
    String? since,
    String? tail,
    bool follow = true,
    bool timestamps = false,
  }) async* {
    final api = await ApiClientManager.instance.getContainerLogStreamApi();
    yield* api.streamContainerLogs(
      container: containerName,
      since: since,
      tail: tail,
      follow: follow,
      timestamps: timestamps,
    );
  }

  Future<String> inspectContainer(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.inspectContainer(InspectReq(
        id: containerId,
        type: 'container',
      ));
      return response.data ?? '';
    });
  }

  /// 容器 inspect：解包 ResponseType.plain 的 JSON envelope 并按缩进格式化，
  /// 供原生详情页直接展示。
  Future<String> inspectContainerFormatted(String containerId) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.inspectContainer(InspectReq(
        id: containerId,
        type: 'container',
      ));
      final raw = (response.data ?? '').trim();
      var text = raw;
      if (raw.startsWith('{')) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map && decoded.containsKey('data')) {
            final inner = decoded['data'];
            if (inner == null) return '';
            text = inner is String ? inner : jsonEncode(inner);
          }
        } on FormatException {
          // 非 envelope 文本按原始内容处理。
        }
      }
      try {
        return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
      } on FormatException {
        return text;
      }
    });
  }

  Future<List<ContainerRepo>> listRepos() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getRepos();
      return response.data ?? [];
    });
  }

  Future<void> createRepo(ContainerRepoOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createRepo(request);
    });
  }

  Future<void> updateRepo(ContainerRepoOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateRepo(request);
    });
  }

  Future<void> deleteRepo(List<int> ids) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.deleteRepo(BatchDelete(ids: ids));
    });
  }

  Future<List<ContainerTemplate>> listTemplates() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getTemplates();
      return response.data ?? [];
    });
  }

  Future<void> createTemplate(ContainerTemplateOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createTemplate(request);
    });
  }

  Future<void> updateTemplate(ContainerTemplateOperate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateTemplate(request);
    });
  }

  Future<void> deleteTemplate(List<int> ids) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.deleteTemplate(BatchDelete(ids: ids));
    });
  }

  Future<void> createCompose(ContainerComposeCreate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createCompose(request);
    });
  }

  Future<void> createNetwork(NetworkCreate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createNetwork(request);
    });
  }

  Future<void> createVolume(VolumeCreate request) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.createVolume(request);
    });
  }

  Future<String> getDaemonJson() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getDaemonJsonFile();
      return response.data ?? '';
    });
  }

  Future<void> updateDaemonJson(String content) {
    return runGuarded(() async {
      final api = await _ensureApi();
      await api.updateDaemonJsonByFile(DaemonJsonUpdateByFile(file: content));
    });
  }

  Future<ContainerStatus> getContainerStatus() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerStatus();
      return response.data ??
          const ContainerStatus(
            all: 0,
            composeCount: 0,
            composeTemplateCount: 0,
            containerCount: 0,
            created: 0,
            dead: 0,
            exited: 0,
            imageCount: 0,
            imageSize: 0,
            networkCount: 0,
            paused: 0,
            removing: 0,
            repoCount: 0,
            restarting: 0,
            running: 0,
            volumeCount: 0,
          );
    });
  }

  /// 获取所有容器的实时 CPU/内存统计
  Future<List<ContainerListStats>> listContainerStats() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.listContainerStats();
      return response.data ?? [];
    });
  }

  /// 列出 Compose 项目（分页，取第一页总数）
  Future<PageResult<ComposeProject>> listComposesPage({
    int page = 1,
    int pageSize = 100,
  }) {
    return runGuarded(() async {
      final api = await _ensureComposeApi();
      final response = await api.listComposes(page: page, pageSize: pageSize);
      return response.data ?? PageResult(items: [], total: 0);
    });
  }
}
