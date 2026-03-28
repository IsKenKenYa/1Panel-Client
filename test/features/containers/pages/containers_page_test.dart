import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/containers/container_service.dart';
import 'package:onepanel_client/features/containers/containers_page.dart';
import 'package:onepanel_client/features/containers/containers_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/image_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/network_provider.dart';
import 'package:onepanel_client/features/orchestration/providers/volume_provider.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/data/models/container_models.dart';

class MockContainerService extends Mock implements ContainerService {}

void main() {
  testWidgets('uses custom subnav instead of Material TabBar', (tester) async {
    SharedPreferences.setMockInitialValues({
      'api_configs': jsonEncode([
        ApiConfig(
                id: 's1', name: 'Demo', url: 'https://demo.test', apiKey: 'key')
            .toJson(),
      ]),
      'current_api_config_id': 's1',
    });

    final currentServer = CurrentServerController();
    await currentServer.load();

    final service = MockContainerService();
    when(() => service.listContainers()).thenAnswer(
      (_) async => const [
        ContainerInfo(
          id: 'c1',
          name: 'demo',
          image: 'nginx:latest',
          status: 'running',
          state: 'running',
        ),
      ],
    );
    when(() => service.listImages()).thenAnswer((_) async => const []);
    when(() => service.listRepos())
        .thenAnswer((_) async => const <ContainerRepo>[]);
    when(() => service.listTemplates())
        .thenAnswer((_) async => const <ContainerTemplate>[]);
    when(() => service.getContainerStatus()).thenAnswer(
      (_) async => const ContainerStatus(
        all: 1,
        running: 1,
        paused: 0,
        exited: 0,
        created: 0,
        dead: 0,
        removing: 0,
        restarting: 0,
        containerCount: 1,
        imageCount: 4,
        imageSize: 0,
        networkCount: 2,
        volumeCount: 1,
        composeCount: 0,
        composeTemplateCount: 0,
        repoCount: 1,
      ),
    );
    when(() => service.getDaemonJson()).thenAnswer((_) async => '{}');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
              value: currentServer),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ContainersPage(
            containersProvider: ContainersProvider(service: service),
            composeProvider: ComposeProvider(),
            imageProvider: DockerImageProvider(),
            networkProvider: NetworkProvider(),
            volumeProvider: VolumeProvider(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.text('Containers'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
  });
}
