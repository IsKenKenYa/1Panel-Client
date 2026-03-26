import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/host_assets/pages/host_asset_form_page.dart';
import 'package:onepanel_client/features/host_assets/providers/host_asset_form_provider.dart';
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
  testWidgets('HostAssetFormPage save disabled before connection test',
      (tester) async {
    final service = _MockHostAssetService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(id: 1, name: 'Default', type: 'host', isDefault: true),
      ],
    );
    when(() => service.resolveDefaultGroupId(any())).thenReturn(1);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<HostAssetFormProvider>(
            create: (_) => HostAssetFormProvider(service: service)..initialize(null),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HostAssetFormPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton).last);
    expect(button.onPressed, isNull);
    expect(find.byType(FilledButton), findsWidgets);
  });
}
