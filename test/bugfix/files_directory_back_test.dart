import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/files_page.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 1000)]) {
    testWidgets('Files root returns to its parent at ${size.width} dp',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CurrentServerController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const FilesPage(autoInitialize: false),
                    ),
                  ),
                  child: const Text('Open Files'),
                ),
              ),
            ),
          ),
        ),
      );

      final openFiles = find.text('Open Files');
      await tester.tap(openFiles);
      await tester.pumpAndSettle();
      final appBar = tester.element(find.byType(AppBar));
      final l10n = AppLocalizations.of(appBar);
      expect(
        find
            .widgetWithText(FilledButton, l10n.filesActionNewFolder)
            .hitTestable(),
        findsOneWidget,
      );
      expect(
        find
            .widgetWithText(OutlinedButton, l10n.filesActionNewFile)
            .hitTestable(),
        findsOneWidget,
      );
      await tester.tap(
        find.byTooltip(MaterialLocalizations.of(appBar).backButtonTooltip),
      );
      await tester.pumpAndSettle();
      expect(openFiles, findsOneWidget);
      expect(find.byType(FilesPage), findsNothing);

      await tester.tap(openFiles);
      await tester.pumpAndSettle();
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(openFiles, findsOneWidget);
      expect(find.byType(FilesPage), findsNothing);
    }, variant: const TargetPlatformVariant({TargetPlatform.android}));
  }
}
