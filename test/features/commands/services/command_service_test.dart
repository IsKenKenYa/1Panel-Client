import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/commands/services/command_service.dart';

void main() {
  group('CommandService.parseImportPreviewCsv', () {
    final service = CommandService();

    test('parses required name and command columns', () async {
      final csv =
          utf8.encode('name,command\nRestart Nginx,systemctl restart nginx\n');

      final result = await service.parseImportPreviewCsv(
        bytes: csv,
        fileName: 'commands.csv',
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'Restart Nginx');
      expect(result.first.command, 'systemctl restart nginx');
      expect(result.first.type, 'command');
    });

    test('parses optional type/group fields and escaped quotes', () async {
      final csv = utf8.encode(
        'name,command,type,groupBelong,groupID\n'
        '"Echo, Quoted","echo ""hello""",shell,Ops,7\n',
      );

      final result = await service.parseImportPreviewCsv(
        bytes: csv,
        fileName: 'commands.csv',
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'Echo, Quoted');
      expect(result.first.command, 'echo "hello"');
      expect(result.first.type, 'shell');
      expect(result.first.groupBelong, 'Ops');
      expect(result.first.groupID, 7);
    });

    test('throws when required headers are missing', () async {
      final csv = utf8.encode('title,script\nDemo,echo hi\n');

      await expectLater(
        () => service.parseImportPreviewCsv(
          bytes: csv,
          fileName: 'invalid.csv',
        ),
        throwsFormatException,
      );
    });
  });
}
