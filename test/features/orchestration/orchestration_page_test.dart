import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/orchestration/compose_page.dart';
import 'package:onepanel_client/features/orchestration/orchestration_page.dart';
import 'package:onepanel_client/features/orchestration/providers/compose_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('OrchestrationPage renders tabs and switches primary actions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OrchestrationPage(),
      ),
    );
    await tester.pump();

    expect(find.text('Orchestration'), findsOneWidget);
    expect(find.text('Compose'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
    expect(find.text('Networks'), findsOneWidget);
    expect(find.text('Volumes'), findsOneWidget);
    expect(find.text('Create Project'), findsOneWidget);

    final composePageContext = tester.element(find.byType(ComposePage));
    expect(
      Provider.of<ComposeProvider>(composePageContext, listen: false),
      isA<ComposeProvider>(),
    );

    await tester.tap(find.byType(Tab).at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Pull Image'), findsOneWidget);

    await tester.tap(find.byType(Tab).at(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create Network'), findsOneWidget);

    await tester.tap(find.byType(Tab).at(3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Create Volume'), findsOneWidget);
  });
}
