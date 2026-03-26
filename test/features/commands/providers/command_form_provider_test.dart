import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/models/command_form_args.dart';
import 'package:onepanel_client/features/commands/providers/command_form_provider.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';

class _MockCommandService extends Mock implements CommandService {}

void main() {
  late _MockCommandService service;
  late CommandFormProvider provider;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'command', isDefault: true),
  ];

  setUpAll(() {
    registerFallbackValue(
      const CommandOperate(
        name: 'fallback',
        command: 'echo fallback',
        type: 'command',
      ),
    );
  });

  setUp(() {
    service = _MockCommandService();
    when(() => service.loadGroups(forceRefresh: any(named: 'forceRefresh')))
        .thenAnswer((_) async => groups);
    when(() => service.createCommand(any())).thenAnswer((_) async {});
    when(() => service.updateCommand(any())).thenAnswer((_) async {});
    provider = CommandFormProvider(service: service);
  });

  test('initialize selects default group', () async {
    await provider.initialize(null);

    expect(provider.selectedGroupId, 1);
    expect(provider.isEditing, isFalse);
  });

  test('save create calls createCommand', () async {
    await provider.initialize(null);
    provider.updateName('Deploy');
    provider.updateCommand('deploy.sh');

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.createCommand(any())).called(1);
  });

  test('save edit calls updateCommand', () async {
    await provider.initialize(
      const CommandFormArgs(
        initialValue: CommandInfo(
          id: 5,
          name: 'Existing',
          command: 'ls',
          type: 'command',
          groupID: 1,
          groupBelong: 'Default',
        ),
      ),
    );

    final result = await provider.save();

    expect(result, isTrue);
    verify(() => service.updateCommand(any())).called(1);
  });
}
