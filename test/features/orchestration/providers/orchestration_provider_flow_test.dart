import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/container_models.dart';
import 'package:onepanel_client/data/models/docker_models.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/orchestration/services/orchestration_service.dart';

class MockOrchestrationService extends Mock implements OrchestrationService {}

void main() {
  group('Orchestration provider flow', () {
    late MockOrchestrationService service;

    setUp(() {
      service = MockOrchestrationService();
    });

    test('ComposeProvider loadComposes success', () async {
      final compose = ContainerCompose(
        id: 'compose-1',
        name: 'stack-prod',
        status: 'running',
      );
      when(
        () => service.loadComposes(page: 1, pageSize: 10),
      ).thenAnswer((_) async => [compose]);

      final provider = ComposeProvider(service: service);
      await provider.loadComposes();

      expect(provider.composes, hasLength(1));
      expect(provider.composes.first.name, 'stack-prod');
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);
    });

    test('ComposeProvider loadComposes failure keeps error for retry',
        () async {
      when(
        () => service.loadComposes(page: 1, pageSize: 10),
      ).thenThrow(Exception('request failed'));

      final provider = ComposeProvider(service: service);
      await provider.loadComposes();

      expect(provider.composes, isEmpty);
      expect(provider.error, contains('request failed'));
    });

    test('DockerImageProvider pullImage failure sets error', () async {
      when(() => service.loadImages()).thenAnswer((_) async => const []);
      when(
        () => service.pullImage(const ImagePull(image: 'nginx', tag: 'latest')),
      ).thenThrow(Exception('pull blocked'));

      final provider = DockerImageProvider(service: service);
      final success = await provider.pullImage('nginx', tag: 'latest');

      expect(success, isFalse);
      expect(provider.error, contains('pull blocked'));
    });

    test('NetworkProvider removeNetwork success refreshes list', () async {
      when(() => service.removeNetwork('network-1')).thenAnswer((_) async {});
      when(() => service.loadNetworks()).thenAnswer(
        (_) async => const [
          DockerNetwork(id: 'network-2', name: 'bridge', driver: 'bridge'),
        ],
      );

      final provider = NetworkProvider(service: service);
      final success = await provider.removeNetwork('network-1');

      expect(success, isTrue);
      expect(provider.networks, hasLength(1));
      verify(() => service.removeNetwork('network-1')).called(1);
      verify(() => service.loadNetworks()).called(1);
    });

    test('VolumeProvider createVolume failure exposes error', () async {
      const request = VolumeCreate(name: 'volume-dev', driver: 'local');
      when(() => service.createVolume(request)).thenThrow(Exception('invalid'));

      final provider = VolumeProvider(service: service);
      final success = await provider.createVolume(request);

      expect(success, isFalse);
      expect(provider.error, contains('invalid'));
    });
  });
}
