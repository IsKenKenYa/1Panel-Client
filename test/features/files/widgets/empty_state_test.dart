import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onepanel_client/features/files/widgets/empty_state.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('EmptyState Widget Tests', () {
    Widget createTestWidget({
      VoidCallback? onCreateFolder,
      VoidCallback? onCreateFile,
    }) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: EmptyState(
            onCreateFolder: onCreateFolder,
            onCreateFile: onCreateFile,
          ),
        ),
      );
    }

    testWidgets('displays folder icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('displays localized title and description', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final strings =
          AppLocalizations.of(tester.element(find.byType(EmptyState)));
      expect(find.text(strings.filesEmptyTitle), findsOneWidget);
      expect(find.text(strings.filesEmptyDesc), findsOneWidget);
    });

    testWidgets('displays create folder button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('displays create file button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.note_add_outlined), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('triggers onCreateFolder callback when folder button is tapped',
        (WidgetTester tester) async {
      var folderCreated = false;
      await tester.pumpWidget(createTestWidget(
        onCreateFolder: () => folderCreated = true,
      ));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(folderCreated, isTrue);
    });

    testWidgets('triggers onCreateFile callback when file button is tapped',
        (WidgetTester tester) async {
      var fileCreated = false;
      await tester.pumpWidget(createTestWidget(
        onCreateFile: () => fileCreated = true,
      ));

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(fileCreated, isTrue);
    });

    testWidgets('buttons are disabled when callbacks are null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onCreateFolder: null,
        onCreateFile: null,
      ));

      final filledButton =
          tester.widget<FilledButton>(find.byType(FilledButton));
      final outlinedButton =
          tester.widget<OutlinedButton>(find.byType(OutlinedButton));

      expect(filledButton.onPressed, isNull);
      expect(outlinedButton.onPressed, isNull);
    });

    testWidgets('keeps actions reachable in a narrow file pane',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(200, 240);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = <String>[];
      await tester.pumpWidget(createTestWidget(
        onCreateFolder: () => actions.add('folder'),
        onCreateFile: () => actions.add('file'),
      ));
      for (final button in [
        find.byType(FilledButton),
        find.byType(OutlinedButton),
      ]) {
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
      }
      expect(tester.takeException(), isNull);
      expect(actions, ['folder', 'file']);
    });

    testWidgets('applies theme colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open_outlined));
      expect(icon.color, isNotNull);
    });
  });
}
