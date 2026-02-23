import '../../api/v2/container_v2.dart';
import '../../core/services/base_component.dart';
import '../../data/models/common_models.dart';
import '../../data/models/container_extension_models.dart';
import '../../data/models/container_models.dart';

class ContainerService extends BaseComponent {
  ContainerService({
    ContainerV2Api? api,
    super.clientManager,
    super.permissionResolver,
  }) : _api = api;

  ContainerV2Api? _api;

  Future<ContainerV2Api> _ensureApi() async {
    if (_api != null) {
      return _api!;
    }
    _api = await clientManager.getContainerApi();
    return _api!;
  }

  Future<List<ContainerInfo>> listContainers() {
    return runGuarded(() async {
      final api = await _ensureApi();
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
      return response.data!;
    });
  }

  Future<String> getContainerLogs(String containerName, {String? since, String? tail}) {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerLogs(
        container: containerName,
        since: since,
        tail: tail,
      );
      
      final data = response.data;
      if (data == null) return '';
      
      if (data is String) {
        // Handle SSE format: "data: log content"
        if (data.contains('data:')) {
          final lines = data.split('\n');
          final logs = <String>[];
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            if (line.startsWith('data:')) {
              var content = line.substring(5);
              if (content.startsWith(' ')) {
                content = content.substring(1);
              }
              logs.add(content);
            } else {
              logs.add(line);
            }
          }
          return logs.join('\n');
        }
        return data;
      }
      
      if (data is Map) {
        // If it's a map, try to find 'data' or return toString
        if (data.containsKey('data')) return data['data'].toString();
        return data.toString();
      }
      if (data is List) return data.join('\n');
      
      return data.toString();
    });
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
      await api.updateDaemonJson(DaemonJsonUpdate(content: content));
    });
  }

  Future<ContainerStatus> getContainerStatus() {
    return runGuarded(() async {
      final api = await _ensureApi();
      final response = await api.getContainerStatus();
      return response.data!;
    });
  }
}
