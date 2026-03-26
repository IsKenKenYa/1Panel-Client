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

  testWidgets('HostAssetsPage shows host card and create action', (tester) async {
    final service = _MockHostAssetService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
      ],
    );
    when(() => service.searchHosts(any())).thenAnswer(
      (_) async => const PageResult<HostInfo>(
        items: <HostInfo>[
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
        ],
        total: 1,
      ),
    );

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
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
