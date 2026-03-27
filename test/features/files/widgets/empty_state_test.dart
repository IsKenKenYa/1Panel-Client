import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/widgets/empty_state.dart';

void main() {
  group('EmptyState Widget Tests', () {
    Widget createTestWidget({
      VoidCallback? onCreateFolder,
      VoidCallback? onCreateFile,
    }) {
      return MaterialApp(
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

    testWidgets('displays correct icon size', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open_outlined));
      expect(icon.size, equals(64));
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

    testWidgets('centers content vertically and horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final center = tester.widget<Center>(find.byType(Center));
      expect(center, isNotNull);
    });

    testWidgets('uses Column for vertical layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('uses Row for button layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final row = tester.widget<Row>(find.byType(Row).last);
      expect(row.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('has proper spacing between elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('applies theme colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final icon = tester.widget<Icon>(find.byIcon(Icons.folder_open_outlined));
      expect(icon.color, isNotNull);
    });
  });
}
