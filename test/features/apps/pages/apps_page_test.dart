import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/features/apps/apps_page.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class MockAppService extends Mock implements AppService {}

class FakeAppInstalledSearchRequest extends Fake
    implements AppInstalledSearchRequest {}

class FakeAppSearchRequest extends Fake implements AppSearchRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAppInstalledSearchRequest());
    registerFallbackValue(FakeAppSearchRequest());
  });

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
    final appService = MockAppService();
    when(() => appService.searchInstalledApps(any())).thenAnswer(
      (_) async => PageResult(items: const [], total: 0),
    );
    when(() => appService.searchApps(any())).thenAnswer(
      (_) async => AppSearchResponse(items: const [], total: 0),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: currentServer,
          ),
          Provider<AppService>.value(value: appService),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(ChoiceChip), findsWidgets);
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('App Store'), findsOneWidget);
  });
}
