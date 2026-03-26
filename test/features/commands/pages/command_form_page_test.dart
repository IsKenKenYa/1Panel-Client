import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/pages/command_form_page.dart';
import 'package:onepanel_client/features/commands/providers/command_form_provider.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';
import 'package:onepanel_client/features/commands/widgets/command_preview_box_widget.dart';
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
    registerFallbackValue(
      const CommandOperate(
        name: 'fallback',
        command: 'echo fallback',
        type: 'command',
      ),
    );
  });

  testWidgets('CommandFormPage shows preview and enabled save for valid edit',
      (tester) async {
    final service = _MockCommandService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer(
      (_) async => <GroupInfo>[
        const GroupInfo(
            id: 1, name: 'Default', type: 'command', isDefault: true),
      ],
    );
    when(() => service.updateCommand(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<CurrentServerController>.value(
              value: _FakeCurrentServerController(),
            ),
            ChangeNotifierProvider<CommandFormProvider>(
              create: (_) => CommandFormProvider(service: service)
                ..initialize(
                  const CommandFormArgs(
                    initialValue: CommandInfo(
                      id: 2,
                      name: 'Restart',
                      command: 'systemctl restart nginx',
                      type: 'command',
                      groupID: 1,
                      groupBelong: 'Default',
                    ),
                  ),
                ),
            ),
          ],
          child: const CommandFormPage(
            args: CommandFormArgs(
              initialValue: CommandInfo(
                id: 2,
                name: 'Restart',
                command: 'systemctl restart nginx',
                type: 'command',
                groupID: 1,
                groupBelong: 'Default',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CommandPreviewBoxWidget), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
