import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/server/server_provider.dart';
import 'package:onepanel_client/features/server/widgets/server_card.dart';
import 'package:onepanel_client/features/server/widgets/server_card_sliver.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('grid follows pane width and text scaling in the same window',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final servers = [
      for (final name in ['Production in Singapore', 'Development in Tokyo'])
        ApiConfig(
            id: name, name: name, url: 'https://server.example', apiKey: ''),
    ];
    final provider = ServerProvider()..syncDirectory(servers, servers.first.id);
    addTearDown(provider.dispose);
    final pane = ValueNotifier((width: 1000.0, scale: 1.0));
    addTearDown(pane.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ValueListenableBuilder(
        valueListenable: pane,
        builder: (context, layout, _) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(layout.scale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: layout.width,
              child: ChangeNotifierProvider.value(
                  value: provider,
                  child: Scaffold(
                      body: CustomScrollView(slivers: [
                    ServerCardSliver(
                      servers: servers,
                      onOpen: (_) {},
                      onEdit: (_) {},
                      onDelete: (_) {},
                    ),
                  ]))),
            ),
          ),
        ),
      ),
    ));
    final cards = find.byType(ServerCard);
    double secondTop() => tester.getTopLeft(cards.at(1)).dy;
    expect(secondTop(), tester.getTopLeft(cards.first).dy);
    pane.value = (width: 1000.0, scale: 2.0);
    await tester.pump();
    expect(secondTop(),
        greaterThanOrEqualTo(tester.getBottomLeft(cards.first).dy));
    pane.value = (width: 280.0, scale: 2.0);
    await tester.pump();
    final actions = find.descendant(
        of: cards.first, matching: find.byIcon(Icons.more_vert));
    await tester.tap(actions);
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(tester.element(cards.first));
    expect(find.text(l10n.commonEdit).hitTestable(), findsOneWidget);
    expect(find.text(l10n.commonDelete).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  for (final (size, platform) in [
    (const Size(390, 844), TargetPlatform.android),
    (const Size(844, 390), TargetPlatform.android),
    (const Size(900, 900), TargetPlatform.android),
    (const Size(1440, 900), TargetPlatform.windows),
  ]) {
    testWidgets('card actions retain server identity at width ${size.width}',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final servers = [
        for (final id in ['alpha', 'beta'])
          ApiConfig(
            id: id,
            name: id,
            url: 'https://$id.example.org',
            apiKey: '',
          ),
      ];
      final provider = ServerProvider()..syncDirectory(servers, 'alpha');
      addTearDown(provider.dispose);
      final firstCard = GlobalKey();
      String? opened;
      String? edited;
      String? deleted;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider.value(
            value: provider,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  ServerCardSliver(
                    servers: servers,
                    firstCardKey: firstCard,
                    onOpen: (config) => opened = config.id,
                    onEdit: (config) => edited = config.id,
                    onDelete: (config) => deleted = config.id,
                  ),
                ],
              ),
            )),
      ));

      final first = find.byKey(firstCard);
      expect(
        find.descendant(of: first, matching: find.text('alpha')),
        findsOneWidget,
      );
      final second = find.widgetWithText(ServerCard, 'beta');
      final actions = find.descendant(
        of: second,
        matching: find.byIcon(Icons.more_vert),
      );
      final l10n = AppLocalizations.of(tester.element(second));
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonEdit));
      await tester.pumpAndSettle();
      expect(edited, 'beta');
      expect(opened, isNull);
      expect(deleted, isNull);
      await tester.tap(actions);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDelete));
      await tester.pumpAndSettle();
      expect(deleted, 'beta');
      expect(opened, isNull);
      await tester.tap(find.text('alpha'));
      expect(opened, 'alpha');
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(platform));
  }
}
