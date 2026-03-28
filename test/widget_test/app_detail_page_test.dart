import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/features/apps/app_detail_page.dart';
import 'package:onepanel_client/features/apps/app_service.dart';
import 'package:onepanel_client/data/models/app_models.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class MockAppService extends Mock implements AppService {}

void main() {
  late MockAppService mockAppService;
  late AppItem testApp;

  setUp(() {
    mockAppService = MockAppService();
    testApp = AppItem(
      id: 1,
      name: 'Test App',
      type: 'runtime',
      versions: ['1.0.0'],
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Provider<AppService>.value(
        value: mockAppService,
        child: AppDetailPage(app: testApp),
      ),
    );
  }

  testWidgets('AppDetailPage renders without crashing', (tester) async {
    when(() => mockAppService.getAppDetail(any(), any(), any()))
        .thenAnswer((_) async => testApp);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(AppDetailPage), findsOneWidget);
  });

  testWidgets('AppDetailPage shows loading indicator then content',
      (tester) async {
    final detailedApp = AppItem(
      id: 1,
      name: 'Test App',
      type: 'runtime',
      versions: ['1.0.0'],
      readMe: 'Detailed Readme Content',
      description: 'Detailed Description',
      key: null, // Ensure no icon to avoid CachedNetworkImage issues
      icon: null,
    );

    // Return a future that completes after a delay to simulate loading
    when(() => mockAppService.getAppDetail(any(), any(), any()))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return detailedApp;
    });

    await tester.pumpWidget(createWidgetUnderTest());

    // Should show loading initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to finish the future
    await tester.pumpAndSettle();

    // Should show content
    expect(find.text('Detailed Readme Content'), findsOneWidget);
    expect(find.text('Detailed Description'), findsOneWidget);
  });

  testWidgets('AppDetailPage does not throw ProviderNotFoundException',
      (tester) async {
    when(() => mockAppService.getAppDetail(any(), any(), any()))
        .thenAnswer((_) async => testApp);

    await tester.pumpWidget(createWidgetUnderTest());
    expect(tester.takeException(), isNull);
  });
}
