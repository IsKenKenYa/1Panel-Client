import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/command_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/pages/commands_page.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

class _MockCommandService extends Mock implements CommandService {}

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

  @override
  String? get currentServerId => _config.id;
}

void main() {
  setUpAll(() {
    registerFallbackValue(const CommandSearchRequest());
    registerFallbackValue(
      const CommandOperate(
        name: 'fallback',
        command: 'echo fallback',
        type: 'command',
      ),
    );
  });

  testWidgets('CommandsPage shows command card and create action',
      (tester) async {
    final service = _MockCommandService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(
            id: 1, name: 'Default', type: 'command', isDefault: true),
      ],
    );
    when(() => service.searchCommands(any())).thenAnswer(
      (_) async => const PageResult<CommandInfo>(
        items: <CommandInfo>[
          CommandInfo(
            id: 1,
            name: 'Deploy',
            command: './deploy.sh',
            type: 'command',
            groupID: 1,
            groupBelong: 'Default',
          ),
        ],
        total: 1,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<CurrentServerController>.value(
            value: _FakeCurrentServerController(),
          ),
          ChangeNotifierProvider<CommandsProvider>(
            create: (_) => CommandsProvider(service: service),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const CommandsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deploy'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
