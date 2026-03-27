import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/files/widgets/path_breadcrumb.dart';

void main() {
  group('PathBreadcrumb Widget Tests', () {
    Widget createTestWidget({
      required String currentPath,
      required void Function(String) onNavigate,
    }) {
      return MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: PathBreadcrumb(
            currentPath: currentPath,
            onNavigate: onNavigate,
          ),
        ),
      );
    }

    testWidgets('renders root path correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/',
        onNavigate: (_) {},
      ));

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('renders single level path correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home',
        onNavigate: (_) {},
      ));

      expect(find.text('home'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('renders multi-level path correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user/documents',
        onNavigate: (_) {},
      ));

      expect(find.text('home'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
      expect(find.text('documents'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });

    testWidgets('handles trailing slash in path', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user/',
        onNavigate: (_) {},
      ));

      expect(find.text('home'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('handles multiple consecutive slashes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '//home///user//',
        onNavigate: (_) {},
      ));

      expect(find.text('home'), findsOneWidget);
      expect(find.text('user'), findsOneWidget);
    });

    testWidgets('triggers onNavigate with root path when home is tapped',
        (WidgetTester tester) async {
      String? navigatedPath;
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user',
        onNavigate: (path) => navigatedPath = path,
      ));

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();

      expect(navigatedPath, equals('/'));
    });

    testWidgets('triggers onNavigate with correct path when segment is tapped',
        (WidgetTester tester) async {
      String? navigatedPath;
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user/documents',
        onNavigate: (path) => navigatedPath = path,
      ));

      await tester.tap(find.text('user'));
      await tester.pump();

      expect(navigatedPath, equals('/home/user'));
    });

    testWidgets(
        'triggers onNavigate with full path when last segment is tapped',
        (WidgetTester tester) async {
      String? navigatedPath;
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user/documents',
        onNavigate: (path) => navigatedPath = path,
      ));

      await tester.tap(find.text('documents'));
      await tester.pump();

      expect(navigatedPath, equals('/home/user/documents'));
    });

    testWidgets('is scrollable horizontally', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/very/long/path/with/many/segments/to/test/scrolling',
        onNavigate: (_) {},
      ));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('applies correct styling from theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home',
        onNavigate: (_) {},
      ));

      final material = tester.widget<Material>(find.byType(Material).first);
      expect(material.color, isNotNull);
    });

    testWidgets('renders TextButton widgets for each segment',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/user/documents',
        onNavigate: (_) {},
      ));

      expect(find.byType(TextButton), findsNWidgets(4)); // root + 3 segments
    });

    testWidgets('handles empty path segments', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '',
        onNavigate: (_) {},
      ));

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('handles paths with special characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        currentPath: '/home/my folder/documents',
        onNavigate: (_) {},
      ));

      expect(find.text('my folder'), findsOneWidget);
    });
  });
}
