import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/host_asset_models.dart';
import 'package:onepanel_client/data/models/host_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/pages/host_assets_page.dart';
import 'package:onepanel_client/features/host_assets/providers/host_assets_provider.dart';
import 'package:onepanel_client/features/host_assets/services/host_asset_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockHostAssetService extends Mock implements HostAssetService {}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;

  @override
  String? get currentServerId => _config.id;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const HostSearchRequest());
  });

  testWidgets('HostAssetsPage reloads list with search query', (tester) async {
    final service = _MockHostAssetService();
    final requests = <HostSearchRequest>[];
    const groups = <GroupInfo>[
      GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
    ];
    const allHosts = <HostInfo>[
      HostInfo(
        id: 1,
        name: 'edge-01',
        addr: '10.0.0.7',
        user: 'root',
        port: 22,
        groupID: 1,
        groupBelong: 'Default',
        authMode: 'password',
        status: 'active',
      ),
      HostInfo(
        id: 2,
        name: 'db-01',
        addr: '10.0.0.8',
        user: 'ubuntu',
        port: 22,
        groupID: 1,
        groupBelong: 'Default',
        authMode: 'password',
        status: 'active',
      ),
    ];

    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.searchHosts(any())).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single as HostSearchRequest;
      requests.add(request);
      if (request.info == 'db') {
        return PageResult<HostInfo>(
          items: <HostInfo>[allHosts[1]],
          total: 1,
        );
      }
      return PageResult<HostInfo>(
        items: allHosts,
        total: 2,
      );
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<HostAssetsProvider>(
            create: (_) => HostAssetsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HostAssetsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('edge-01'), findsOneWidget);
    expect(find.text('db-01'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'db');
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(
      requests,
      containsAllInOrder(<HostSearchRequest>[
        const HostSearchRequest(),
        const HostSearchRequest(info: 'db'),
      ]),
    );
    expect(find.text('db-01'), findsOneWidget);
    expect(find.text('edge-01'), findsNothing);
  });
}
