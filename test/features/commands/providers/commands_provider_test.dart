import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/command_models.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/system_group_models.dart';
import 'package:onepanel_client/features/commands/providers/commands_provider.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';

class _MockCommandService extends Mock implements CommandService {}

void main() {
  late _MockCommandService service;
  late CommandsProvider provider;

  final groups = <GroupInfo>[
    const GroupInfo(id: 1, name: 'Default', type: 'command', isDefault: true),
  ];
  final commands = <CommandInfo>[
    const CommandInfo(
      id: 10,
      name: 'Restart Nginx',
      command: 'systemctl restart nginx',
      type: 'command',
      groupID: 1,
      groupBelong: 'Default',
    ),
  ];

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const CommandSearchRequest());
    registerFallbackValue(
      const GroupInfo(id: 1, name: 'Default', type: 'command', isDefault: true),
    );
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
    when(() => service.searchCommands(any())).thenAnswer(
      (_) async => PageResult<CommandInfo>(
        items: commands,
        total: commands.length,
      ),
    );
    when(() => service.deleteCommands(any())).thenAnswer((_) async {});
    when(() => service.uploadCommandsCsv(
          bytes: any(named: 'bytes'),
          fileName: any(named: 'fileName'),
        )).thenAnswer(
      (_) async => <CommandInfo>[
        const CommandInfo(
          name: 'Preview',
          command: 'echo hello',
          type: 'command',
          groupBelong: 'Default',
          groupID: 1,
        ),
      ],
    );
    when(() => service.importCommands(any())).thenAnswer((_) async {});
    provider = CommandsProvider(service: service);
  });

  test('load sets commands and groups', () async {
    await provider.load();

    expect(provider.groups, hasLength(1));
    expect(provider.commands, hasLength(1));
    expect(provider.commands.first.name, 'Restart Nginx');
  });

  test('deleteSelected calls service and refreshes list', () async {
    await provider.load();
    provider.toggleSelection(10);

    await provider.deleteSelected();

    verify(() => service.deleteCommands(<int>[10])).called(1);
    verify(() => service.searchCommands(any())).called(2);
  });

  test('loadImportPreview assigns temporary ids when missing', () async {
    await provider.loadImportPreview(
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
      fileName: 'commands.csv',
    );

    expect(provider.importPreviewItems, hasLength(1));
    expect(provider.importPreviewItems.first.id, isNotNull);
    expect(provider.selectedPreviewIds, isNotEmpty);
  });
}
