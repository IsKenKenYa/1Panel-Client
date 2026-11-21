import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/server/view_models/server_list_view_model.dart';
import 'package:onepanel_client/features/server/widgets/server_list_view.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_list_page.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('切换当前面板只更新涉及的服务器卡片', (tester) async {
    final configs = [
      for (final id in ['alpha', 'bravo', 'charlie'])
        ApiConfig(id: id, name: id, url: 'https://$id.example', apiKey: ''),
    ];
    final provider = ServerProvider()..syncDirectory(configs, 'alpha');
    final model =
        ServerListViewModel(serverProvider: provider, enableCoach: false);
    addTearDown(provider.dispose);
    addTearDown(model.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: model),
        ],
        child: const ServerListView(),
      ),
    ));
    ServerCard card(String name) =>
        tester.widget(find.widgetWithText(ServerCard, name));
    final third = card('charlie');
    final search =
        tester.widget<ModuleSearchField>(find.byType(ModuleSearchField));
    provider.syncDirectory(configs, 'bravo');
    await tester.pump();
    expect(card('alpha').data.isCurrent, isFalse);
    expect(card('bravo').data.isCurrent, isTrue);
    expect(card('charlie'), same(third));
    expect(tester.widget(find.byType(ModuleSearchField)), same(search));
    await tester.enterText(find.byType(TextField), ' BRAVO ');
    await tester.pump();
    expect(find.byType(ServerCard), findsOneWidget);
    expect(card('bravo').data.isCurrent, isTrue);
  });

  testWidgets(
      'split view retains search and exposes the add action at each width',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final width = ValueNotifier(1100.0);
    final provider = ServerProvider()..syncDirectory([], null);
    final viewModel =
        ServerListViewModel(serverProvider: provider, enableCoach: false);
    addTearDown(width.dispose);
    addTearDown(provider.dispose);
    addTearDown(viewModel.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: provider),
          ChangeNotifierProvider.value(value: viewModel),
        ],
        child: ValueListenableBuilder(
          valueListenable: width,
          builder: (context, value, _) => Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: value,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(2)),
                child: const AdaptiveLayoutViewport(child: ServerListView()),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'production');
    for (final value in [620.0, 320.0, 1100.0]) {
      width.value = value;
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<ModuleSearchField>(find.byType(ModuleSearchField))
              .controller
              ?.text,
          'production');
      expect(find.byKey(viewModel.addKey).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('coach mark highlight aligns with add button', (tester) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ServerProvider()..syncDirectory([], null),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ServerListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add your first server'), findsOneWidget);
    final addButton = find.byIcon(Icons.add_circle_outline);
    final highlight = find.byKey(const Key('coachmark-highlight'));
    expect(addButton, findsOneWidget);
    expect(highlight, findsOneWidget);

    final addRect = tester.getRect(addButton);
    final highlightRect = tester.getRect(highlight);

    expect((addRect.center.dx - highlightRect.center.dx).abs(), lessThan(2.0));
    expect((addRect.center.dy - highlightRect.center.dy).abs(), lessThan(2.0));
    expect(highlightRect.width, greaterThan(addRect.width));
    expect(highlightRect.height, greaterThan(addRect.height));
  });

  testWidgets('mobile server list renders populated cards without exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final configs = [
      ApiConfig(
        id: 'server-1',
        name: 'Tencent Guangzhou',
        url: 'http://10.0.0.1:11451',
        apiKey: 'key-1',
        allowInsecureTls: true,
        isDefault: true,
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) =>
                  ServerProvider()..syncDirectory(configs, configs.first.id)),
          ChangeNotifierProvider(
              create: (context) => ServerListViewModel(
                  serverProvider: context.read(), enableCoach: false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ServerListView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tencent Guangzhou'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet server list uses wide add action and grid layout',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 1366);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final configs = [
      ApiConfig(
        id: 'server-1',
        name: 'Alpha',
        url: 'http://10.0.0.1:11451',
        apiKey: 'key-1',
        allowInsecureTls: true,
        isDefault: true,
      ),
      ApiConfig(
        id: 'server-2',
        name: 'Beta',
        url: 'http://10.0.0.2:11451',
        apiKey: 'key-2',
        allowInsecureTls: true,
        isDefault: false,
      ),
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (_) =>
                  ServerProvider()..syncDirectory(configs, configs.first.id)),
          ChangeNotifierProvider(
              create: (context) => ServerListViewModel(
                  serverProvider: context.read(), enableCoach: false)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ServerListView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
