import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/script_library_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/script_library/pages/script_library_page.dart';
import 'package:onepanel_client/features/script_library/providers/script_library_provider.dart';
import 'package:onepanel_client/features/script_library/services/script_library_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockScriptLibraryService extends Mock implements ScriptLibraryService {}

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
  late StreamController<String> controller;

  setUpAll(() {
    registerFallbackValue(const ScriptLibraryQuery());
  });

  setUp(() {
    controller = StreamController<String>.broadcast();
  });

  tearDown(() async {
    await controller.close();
  });

  testWidgets('ScriptLibraryPage renders script card and actions',
      (tester) async {
    final service = _MockScriptLibraryService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => const <GroupInfo>[
        GroupInfo(id: 1, name: 'Default', type: 'script', isDefault: true),
      ],
    );
    when(() => service.searchScripts(any())).thenAnswer(
      (_) async => const PageResult<ScriptLibraryInfo>(
        items: <ScriptLibraryInfo>[
          ScriptLibraryInfo(
            id: 7,
            name: 'Hello Script',
            isInteractive: false,
            label: '',
            script: 'echo hello',
            groupList: <int>[1],
            groupBelong: <String>['Default'],
            isSystem: false,
            description: 'Demo script',
            createdAt: null,
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.syncScripts()).thenAnswer(
      (_) async => const ScriptSyncState(taskId: 'task-1', isRunning: true),
    );
    when(() => service.deleteScripts(any())).thenAnswer((_) async {});
    when(() => service.watchRunOutput()).thenAnswer((_) => controller.stream);
    when(() => service.startRun(any())).thenAnswer((_) async {});
    when(() => service.stopRun()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<ScriptLibraryProvider>(
            create: (_) => ScriptLibraryProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ScriptLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hello Script'), findsOneWidget);
    expect(find.text('View code'), findsOneWidget);
    expect(find.text('Run'), findsOneWidget);
    expect(find.text('Sync'), findsAtLeastNWidgets(1));
  });

  testWidgets('ScriptLibraryPage does not load when no server is active',
      (tester) async {
    final service = _MockScriptLibraryService();
    when(() => service.watchRunOutput()).thenAnswer((_) => controller.stream);
    when(() => service.stopRun()).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _NoServerCurrentServerController(),
          ),
          ChangeNotifierProvider<ScriptLibraryProvider>(
            create: (_) => ScriptLibraryProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const ScriptLibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    verifyNever(
        () => service.loadGroups(forceRefresh: any(named: 'forceRefresh')));
    verifyNever(() => service.searchScripts(any()));
  });
}
