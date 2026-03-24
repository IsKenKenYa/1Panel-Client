import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/files/widgets/server_selector.dart';

void main() {
  group('ServerSelector Widget Tests', () {
    Widget createTestWidget({
      ApiConfig? currentServer,
      required void Function(String) onServerChanged,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: ServerSelector(
            currentServer: currentServer,
            onServerChanged: onServerChanged,
          ),
        ),
      );
    }

    testWidgets('renders server selector button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onServerChanged: (_) {},
      ));

      expect(find.byIcon(Icons.dns_outlined), findsOneWidget);
    });

    testWidgets('shows error color when no server is selected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentServer: null,
        onServerChanged: (_) {},
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.dns_outlined));
      expect(icon.color, isNotNull);
    });

    testWidgets('shows normal color when server is selected', (WidgetTester tester) async {
      final server = ApiConfig(
        id: 'test-server',
        name: 'Test Server',
        url: 'https://test.example.com',
        apiKey: 'test-key',
      );

      await tester.pumpWidget(createTestWidget(
        currentServer: server,
        onServerChanged: (_) {},
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.dns_outlined));
      expect(icon.color, isNull);
    });

    testWidgets('shows popup menu when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onServerChanged: (_) {},
      ));

      await tester.tap(find.byIcon(Icons.dns_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('uses FutureBuilder for loading servers', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        onServerChanged: (_) {},
      ));

      expect(find.byType(FutureBuilder<List<ApiConfig>>), findsOneWidget);
    });
  });
}
