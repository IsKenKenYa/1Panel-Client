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

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  setUpAll(() {
    registerFallbackValue(const HostSearchRequest());
    registerFallbackValue(<int>[1, 2]);
    registerFallbackValue(const HostGroupChange(id: 1, groupID: 2));
  });

  testWidgets('HostAssetsPage shows host card and create action',
      (tester) async {
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

  testWidgets('HostAssetsPage does not load when no server is active',
      (tester) async {
    final service = _MockHostAssetService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
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

    verifyNever(
        () => service.loadGroups(forceRefresh: any(named: 'forceRefresh')));
    verifyNever(() => service.searchHosts(any()));
  });

  testWidgets('HostAssetsPage supports batch delete flow', (tester) async {
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
        ],
        total: 2,
      ),
    );
    when(() => service.deleteHosts(any())).thenAnswer((_) async {});

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

    await tester.longPress(find.text('edge-01'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('db-01'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.delete_outline), findsWidgets);

    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => service.deleteHosts(<int>[1, 2])).called(1);
  });

  testWidgets('HostAssetsPage applies group filter through picker',
      (tester) async {
    final service = _MockHostAssetService();
    final requests = <HostSearchRequest>[];
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
        const GroupInfo(id: 2, name: 'DB', type: 'host'),
      ],
    );
    when(() => service.searchHosts(any())).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single as HostSearchRequest;
      requests.add(request);
      if (request.groupID == 2) {
        return const PageResult<HostInfo>(
          items: <HostInfo>[
            HostInfo(
              id: 2,
              name: 'db-01',
              addr: '10.0.0.8',
              user: 'ubuntu',
              port: 22,
              groupID: 2,
              groupBelong: 'DB',
              authMode: 'password',
              status: 'active',
            ),
          ],
          total: 1,
        );
      }
      return const PageResult<HostInfo>(
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
          HostInfo(
            id: 2,
            name: 'db-01',
            addr: '10.0.0.8',
            user: 'ubuntu',
            port: 22,
            groupID: 2,
            groupBelong: 'DB',
            authMode: 'password',
            status: 'active',
          ),
        ],
        total: 2,
      );
    });

    Future<int?> groupPicker({
      required BuildContext context,
      required String groupType,
      int? initialSelectedGroupId,
      bool allowClearSelection = false,
      String? clearOptionLabel,
    }) async {
      return 2;
    }

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
          home: HostAssetsPage(groupPicker: groupPicker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilterChip));
    await tester.pumpAndSettle();

    expect(
      requests,
      containsAllInOrder(<HostSearchRequest>[
        const HostSearchRequest(),
        const HostSearchRequest(groupID: 2),
      ]),
    );
    expect(find.text('db-01'), findsOneWidget);
    expect(find.text('edge-01'), findsNothing);
  });

  testWidgets('HostAssetsPage moves host group through picker', (tester) async {
    final service = _MockHostAssetService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
        const GroupInfo(id: 2, name: 'DB', type: 'host'),
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
    when(() => service.updateHostGroup(any())).thenAnswer((_) async {});

    Future<int?> groupPicker({
      required BuildContext context,
      required String groupType,
      int? initialSelectedGroupId,
      bool allowClearSelection = false,
      String? clearOptionLabel,
    }) async {
      return 2;
    }

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
          home: HostAssetsPage(groupPicker: groupPicker),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Move Group'));
    await tester.pumpAndSettle();

    verify(
      () => service.updateHostGroup(
        const HostGroupChange(id: 1, groupID: 2),
      ),
    ).called(1);
  });
}
