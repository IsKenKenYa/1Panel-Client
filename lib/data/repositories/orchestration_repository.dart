import 'package:onepanel_client/api/v2/compose_v2.dart';
import 'package:onepanel_client/api/v2/docker_v2.dart';
import 'package:onepanel_client/core/network/api_client_manager.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';

class OrchestrationRepository {
  OrchestrationRepository({ApiClientManager? clientManager})
      : _clientManager = clientManager ?? ApiClientManager.instance;

  final ApiClientManager _clientManager;

  Future<ComposeV2Api> _getComposeApi() => _clientManager.getComposeApi();

  Future<DockerV2Api> _getDockerApi() => _clientManager.getDockerApi();

  Future<List<ComposeProject>> loadComposes({
    int page = 1,
    int pageSize = 10,
  }) async {
    final api = await _getComposeApi();
    final response = await api.listComposes(page: page, pageSize: pageSize);
    return response.data?.items ?? const <ComposeProject>[];
  }

  Future<void> createCompose(ContainerComposeCreate compose) async {
    final api = await _getComposeApi();
    await api.createCompose(compose);
  }

  Future<void> upCompose(ComposeProject compose) async {
    final api = await _getComposeApi();
    await api.upCompose(compose);
  }

  Future<void> downCompose(ComposeProject compose) async {
    final api = await _getComposeApi();
    await api.downCompose(compose);
  }

  Future<void> startCompose(ComposeProject compose) async {
    final api = await _getComposeApi();
    await api.startCompose(compose);
  }

  Future<void> stopCompose(ComposeProject compose) async {
    final api = await _getComposeApi();
    await api.stopCompose(compose);
  }

  Future<void> restartCompose(ComposeProject compose) async {
    final api = await _getComposeApi();
    await api.restartCompose(compose);
  }

  Future<void> updateCompose(ContainerComposeUpdateRequest request) async {
    final api = await _getComposeApi();
    await api.updateCompose(request);
  }

  Future<void> testCompose(ContainerComposeCreate request) async {
    final api = await _getComposeApi();
    await api.testCompose(request);
  }

  Future<void> cleanComposeLog(ContainerComposeLogCleanRequest request) async {
    final api = await _getComposeApi();
    await api.cleanComposeLog(request);
  }

  Future<List<DockerImage>> loadImages() async {
    final api = await _getDockerApi();
    final response = await api.listImages();
    return response.data ?? const <DockerImage>[];
  }

  Future<void> pullImage(ImagePull request) async {
    final api = await _getDockerApi();
    await api.pullImage(request);
  }

  Future<void> removeImage(String imageId, {bool force = false}) async {
    final api = await _getDockerApi();
    await api.removeImage(imageId, force: force);
  }

  Future<void> buildImage(ImageBuild request) async {
    final api = await _getDockerApi();
    await api.buildImage(request);
  }

  Future<void> loadImage(ImageLoad request) async {
    final api = await _getDockerApi();
    await api.loadImage(request);
  }

  Future<void> saveImage(ImageSave request) async {
    final api = await _getDockerApi();
    await api.saveImage(request);
  }

  Future<void> tagImage(ImageTag request) async {
    final api = await _getDockerApi();
    await api.tagImage(request);
  }

  Future<void> pushImage(ImagePush request) async {
    final api = await _getDockerApi();
    await api.pushImage(request);
  }

  Future<PageResult<Map<String, dynamic>>> searchImages(
    SearchWithPage request,
  ) async {
    final api = await _getDockerApi();
    final response = await api.searchImages(request);
    return response.data ?? const PageResult(items: [], total: 0);
  }

  Future<List<DockerNetwork>> loadNetworks() async {
    final api = await _getDockerApi();
    final response = await api.listNetworks();
    return response.data ?? const <DockerNetwork>[];
  }

  Future<void> createNetwork(NetworkCreate request) async {
    final api = await _getDockerApi();
    await api.createNetwork(request);
  }

  Future<void> removeNetwork(String networkId) async {
    final api = await _getDockerApi();
    await api.removeNetwork(networkId);
  }

  Future<List<DockerVolume>> loadVolumes() async {
    final api = await _getDockerApi();
    final response = await api.listVolumes();
    return response.data ?? const <DockerVolume>[];
  }

  Future<void> createVolume(VolumeCreate request) async {
    final api = await _getDockerApi();
    await api.createVolume(request);
  }

  Future<void> removeVolume(String volumeName) async {
    final api = await _getDockerApi();
    await api.removeVolume(volumeName);
  }
}
