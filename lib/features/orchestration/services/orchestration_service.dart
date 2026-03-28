import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/data/repositories/orchestration_repository.dart';

class OrchestrationService {
  OrchestrationService({OrchestrationRepository? repository})
      : _repository = repository ?? OrchestrationRepository();

  final OrchestrationRepository _repository;

  Future<List<ComposeProject>> loadComposes({
    int page = 1,
    int pageSize = 10,
  }) {
    return _repository.loadComposes(page: page, pageSize: pageSize);
  }

  Future<void> createCompose(ContainerComposeCreate compose) {
    return _repository.createCompose(compose);
  }

  Future<void> upCompose(ComposeProject compose) {
    return _repository.upCompose(compose);
  }

  Future<void> downCompose(ComposeProject compose) {
    return _repository.downCompose(compose);
  }

  Future<void> startCompose(ComposeProject compose) {
    return _repository.startCompose(compose);
  }

  Future<void> stopCompose(ComposeProject compose) {
    return _repository.stopCompose(compose);
  }

  Future<void> restartCompose(ComposeProject compose) {
    return _repository.restartCompose(compose);
  }

  Future<void> updateCompose(ContainerComposeUpdateRequest request) {
    return _repository.updateCompose(request);
  }

  Future<void> testCompose(ContainerComposeCreate request) {
    return _repository.testCompose(request);
  }

  Future<void> cleanComposeLog(ContainerComposeLogCleanRequest request) {
    return _repository.cleanComposeLog(request);
  }

  Future<List<DockerImage>> loadImages() {
    return _repository.loadImages();
  }

  Future<void> pullImage(ImagePull request) {
    return _repository.pullImage(request);
  }

  Future<void> removeImage(String imageId, {bool force = false}) {
    return _repository.removeImage(imageId, force: force);
  }

  Future<void> buildImage(ImageBuild request) {
    return _repository.buildImage(request);
  }

  Future<void> loadImage(ImageLoad request) {
    return _repository.loadImage(request);
  }

  Future<void> saveImage(ImageSave request) {
    return _repository.saveImage(request);
  }

  Future<void> tagImage(ImageTag request) {
    return _repository.tagImage(request);
  }

  Future<void> pushImage(ImagePush request) {
    return _repository.pushImage(request);
  }

  Future<PageResult<Map<String, dynamic>>> searchImages(
    SearchWithPage request,
  ) {
    return _repository.searchImages(request);
  }

  Future<List<DockerNetwork>> loadNetworks() {
    return _repository.loadNetworks();
  }

  Future<void> createNetwork(NetworkCreate request) {
    return _repository.createNetwork(request);
  }

  Future<void> removeNetwork(String networkId) {
    return _repository.removeNetwork(networkId);
  }

  Future<List<DockerVolume>> loadVolumes() {
    return _repository.loadVolumes();
  }

  Future<void> createVolume(VolumeCreate request) {
    return _repository.createVolume(request);
  }

  Future<void> removeVolume(String volumeName) {
    return _repository.removeVolume(volumeName);
  }
}
