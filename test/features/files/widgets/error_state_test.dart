import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onepanel_client/features/files/widgets/error_state.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  group('ErrorState Widget Tests', () {
    Widget createTestWidget({
      required String error,
      VoidCallback? onRetry,
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
          body: ErrorState(
            error: error,
            onRetry: onRetry,
          ),
        ),
      );
    }

    testWidgets('displays error icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays correct icon size', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, equals(48));
    });

    testWidgets('displays error message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays long error message', (WidgetTester tester) async {
      const longError =
          'This is a very long error message that should still be displayed correctly '
          'and might need to wrap to multiple lines depending on the screen width';

      await tester.pumpWidget(createTestWidget(
        error: longError,
      ));

      expect(find.text(longError), findsOneWidget);
    });

    testWidgets('displays retry button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
        onRetry: () {},
      ));

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('triggers onRetry callback when retry button is tapped',
        (WidgetTester tester) async {
      var retryCalled = false;
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
        onRetry: () => retryCalled = true,
      ));

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('retry button is disabled when onRetry is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
        onRetry: null,
      ));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('centers content vertically and horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final centers = tester.widgetList<Center>(find.byType(Center));
      expect(
        centers.any((center) => center.child is Column),
        isTrue,
      );
    });

    testWidgets('uses Column for vertical layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('has proper spacing between elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('applies error color to icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, isNotNull);
    });

    testWidgets('text is centered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Test error message',
      ));

      final text = tester.widget<Text>(find.text('Test error message'));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('handles empty error message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: '',
      ));

      expect(find.text(''), findsOneWidget);
    });

    testWidgets('handles special characters in error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        error: 'Error: <test> & "quotes" \'apostrophes\'',
      ));

      expect(find.text('Error: <test> & "quotes" \'apostrophes\''),
          findsOneWidget);
    });
  });
}
