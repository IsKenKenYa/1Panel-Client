import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/config/app_router.dart';
import 'package:onepanel_client/features/ai/ai_page.dart';
import 'package:onepanel_client/features/ai/mcp_server_provider.dart';
import 'package:onepanel_client/features/ai/ai_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AI route builds page and injects provider', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateRoute: AppRouter.generateRoute,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    navigatorKey.currentState!.pushNamed(AppRoutes.ai);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AIPage), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('GPU'), findsOneWidget);
    expect(find.text('Domain'), findsOneWidget);
    expect(find.text('MCP'), findsOneWidget);

    final aiContext = tester.element(find.byType(AIPage));
    expect(
      Provider.of<AIProvider>(aiContext, listen: false),
      isA<AIProvider>(),
    );
    expect(
      Provider.of<McpServerProvider>(aiContext, listen: false),
      isA<McpServerProvider>(),
    );
  });
}
