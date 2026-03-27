import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/features/runtimes/models/runtime_form_args.dart';
import 'package:onepanel_client/features/runtimes/pages/runtime_form_page.dart';
import 'package:onepanel_client/features/runtimes/providers/runtime_form_provider.dart';
import 'package:onepanel_client/features/runtimes/services/runtime_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockRuntimeService extends Mock implements RuntimeService {}

class _FakeCurrentServerController extends CurrentServerController {
  final ApiConfig _config = ApiConfig(
    id: 'server-1',
    name: 'Demo',
    url: 'https://demo.example.com',
    apiKey: 'key',
  );

  @override
  bool get hasServer => true;

  @override
  ApiConfig? get currentServer => _config;
}

class _NoServerCurrentServerController extends CurrentServerController {}

void main() {
  late _MockRuntimeService service;

  Future<void> pumpPage(
    WidgetTester tester, {
    CurrentServerController? serverController,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: serverController ?? _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<RuntimeFormProvider>(
            create: (_) => RuntimeFormProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const RuntimeFormPage(
            args: RuntimeFormArgs(initialType: 'node'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    service = _MockRuntimeService();
    when(() => service.createDraft(any())).thenAnswer(
      (invocation) => RuntimeService().createDraft(
        invocation.positionalArguments.first as String,
      ),
    );
  });

  testWidgets('RuntimeFormPage renders segmented sections', (tester) async {
    await pumpPage(tester);

    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Runtime'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(find.text('Advanced', skipOffstage: false), findsOneWidget);
  });

  testWidgets('RuntimeFormPage does not initialize when no server is active',
      (tester) async {
    await pumpPage(
      tester,
      serverController: _NoServerCurrentServerController(),
    );

    verifyNever(() => service.getRuntimeDetail(any()));
  });
}
