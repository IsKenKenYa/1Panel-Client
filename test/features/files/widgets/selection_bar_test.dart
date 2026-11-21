import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/widgets/selection_bar.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('SelectionBar Widget Tests', () {
    Widget createTestWidget({
      required int selectionCount,
      SelectionBar? bar,
      double textScale = 1,
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              bar ?? SelectionBar(
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

    testWidgets('displays selection count correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 5));
      await tester.pumpAndSettle();

      expect(find.text('已选择 5 项'), findsOneWidget);
    });

    testWidgets('file actions remain available on narrow screens with large text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(280, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      void selectAction() => taps++;
      await tester.pumpWidget(createTestWidget(
        selectionCount: 120,
        textScale: 2,
        onCompress: selectAction,
        onCopy: selectAction,
        onMove: selectAction,
        onSelectAll: selectAction,
        onDeselect: selectAction,
        onDelete: selectAction,
      ));
      await tester.pumpAndSettle();
      expect(find.text('已选择 120 项'), findsOneWidget);
      final buttons = find.byType(IconButton);
      expect(buttons, findsNWidgets(6));
      for (var index = 0; index < 6; index++) {
        await tester.tap(buttons.at(index));
      }
      expect(taps, 6);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recycle bin keeps its own actions and selection callbacks', (tester) async {
      final actions = <String>[];
      await tester.pumpWidget(createTestWidget(
        selectionCount: 2,
        bar: SelectionBar.recycleBin(
          selectionCount: 2,
          onRestore: () => actions.add('restore'),
          onDeletePermanently: () => actions.add('delete'),
          onSelectAll: () => actions.add('all'),
          onDeselect: () => actions.add('none'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 已选择'), findsOneWidget);
      expect(find.byType(IconButton), findsNWidgets(4));
      for (final icon in [
        Icons.restore_outlined,
        Icons.delete_forever_outlined,
        Icons.select_all,
        Icons.deselect,
      ]) {
        await tester.tap(find.byIcon(icon));
      }
      expect(actions, ['restore', 'delete', 'all', 'none']);
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

    testWidgets('triggers onCompress callback when compress button is tapped',
        (WidgetTester tester) async {
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

    testWidgets('triggers onCopy callback when copy button is tapped',
        (WidgetTester tester) async {
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

    testWidgets('triggers onMove callback when move button is tapped',
        (WidgetTester tester) async {
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

    testWidgets('triggers onDelete callback when delete button is tapped',
        (WidgetTester tester) async {
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

    testWidgets('buttons are disabled when callbacks are null',
        (WidgetTester tester) async {
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

      final iconButtons =
          tester.widgetList<IconButton>(find.byType(IconButton));
      for (final button in iconButtons) {
        expect(button.onPressed, isNull);
      }
    });

    testWidgets('applies correct container styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(selectionCount: 1));
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
