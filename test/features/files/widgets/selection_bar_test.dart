import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/widgets/selection_bar.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('SelectionBar Widget Tests', () {
    Widget createTestWidget({
      required int selectionCount,
      VoidCallback? onCompress,
      VoidCallback? onCopy,
      VoidCallback? onMove,
      VoidCallback? onSelectAll,
      VoidCallback? onDeselect,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        locale: const Locale('zh', 'CN'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              SelectionBar(
                selectionCount: selectionCount,
                onCompress: onCompress,
                onCopy: onCopy,
                onMove: onMove,
                onSelectAll: onSelectAll,
                onDeselect: onDeselect,
                onDelete: onDelete,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays selection count correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 5));
      await tester.pumpAndSettle();

      expect(find.textContaining('5'), findsOneWidget);
    });

    testWidgets('displays zero selection count', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 0));
      await tester.pumpAndSettle();

      expect(find.textContaining('0'), findsOneWidget);
    });

    testWidgets('renders all action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 1));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder_zip_outlined), findsOneWidget);
      expect(find.byIcon(Icons.content_copy), findsOneWidget);
      expect(find.byIcon(Icons.drive_file_move_outline), findsOneWidget);
      expect(find.byIcon(Icons.select_all), findsOneWidget);
      expect(find.byIcon(Icons.deselect), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('triggers onCompress callback when compress button is tapped', (WidgetTester tester) async {
      var compressCalled = false;
      await tester.pumpWidget(createTestWidget(
        selectionCount: 1,
        onCompress: () => compressCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.folder_zip_outlined));
      await tester.pump();

      expect(compressCalled, isTrue);
    });

    testWidgets('triggers onCopy callback when copy button is tapped', (WidgetTester tester) async {
      var copyCalled = false;
      await tester.pumpWidget(createTestWidget(
        selectionCount: 1,
        onCopy: () => copyCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pump();

      expect(copyCalled, isTrue);
    });

    testWidgets('triggers onMove callback when move button is tapped', (WidgetTester tester) async {
      var moveCalled = false;
      await tester.pumpWidget(createTestWidget(
        selectionCount: 1,
        onMove: () => moveCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.drive_file_move_outline));
      await tester.pump();

      expect(moveCalled, isTrue);
    });

    testWidgets('triggers onDelete callback when delete button is tapped', (WidgetTester tester) async {
      var deleteCalled = false;
      await tester.pumpWidget(createTestWidget(
        selectionCount: 1,
        onDelete: () => deleteCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('buttons are disabled when callbacks are null', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        selectionCount: 1,
        onCompress: null,
        onCopy: null,
        onMove: null,
        onSelectAll: null,
        onDeselect: null,
        onDelete: null,
      ));
      await tester.pumpAndSettle();

      final iconButtons = tester.widgetList<IconButton>(find.byType(IconButton));
      for (final button in iconButtons) {
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('applies correct container styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 1));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
