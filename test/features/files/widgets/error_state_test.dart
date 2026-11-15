import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';

void main() {
  group('ModuleErrorStateWidget Tests', () {
    Widget createTestWidget({
      String? message,
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
        locale: const Locale('zh'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: ModuleErrorStateWidget(
            message: message,
            onRetry: onRetry,
          ),
        ),
      );
    }

    testWidgets('displays error icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays correct icon size', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, equals(56));
    });

    testWidgets('displays error message', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays long error message', (WidgetTester tester) async {
      const longError =
          'This is a very long error message that should still be displayed correctly '
          'and might need to wrap to multiple lines depending on the screen width';

      await tester.pumpWidget(createTestWidget(message: longError));
      await tester.pumpAndSettle();

      // 长文案按 Toast 规范截断到 120 字符（完整事实保留在日志与
      // Debug 详情中），错误页展示截断后的文案。
      final expected = '${longError.substring(0, 119)}…';
      expect(find.text(expected), findsOneWidget);
    });

    testWidgets('displays retry button when onRetry is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        message: 'Test error message',
        onRetry: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('triggers onRetry callback when retry button is tapped',
        (WidgetTester tester) async {
      var retryCalled = false;
      await tester.pumpWidget(createTestWidget(
        message: 'Test error message',
        onRetry: () => retryCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('hides retry button when onRetry is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        message: 'Test error message',
        onRetry: null,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('centers content vertically and horizontally',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('uses Column for vertical layout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('has proper spacing between elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      expect(sizedBoxes.length, greaterThanOrEqualTo(2));
    });

    testWidgets('applies error color to icon', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.color, isNotNull);
    });

    testWidgets('text is centered', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: 'Test error message'));
      await tester.pumpAndSettle();

      final text = tester.widget<Text>(find.text('Test error message'));
      expect(text.textAlign, equals(TextAlign.center));
    });

    testWidgets('shows fallback message when message is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(message: ''));
      await tester.pumpAndSettle();

      expect(find.text('发生错误'), findsOneWidget);
    });

    testWidgets('handles special characters in error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        message: 'Error: <test> & "quotes" \'apostrophes\'',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Error: <test> & "quotes" \'apostrophes\''),
          findsOneWidget);
    });
  });
}
