import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/services/file_save_service.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssh_log_models.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_logs_provider.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class _MockSshService extends Mock implements SSHService {}

void main() {
  late _MockSshService service;
  late SshLogsProvider provider;

  setUpAll(() {
    registerFallbackValue(const SshLogSearchRequest());
  });

  setUp(() {
    service = _MockSshService();
    when(() => service.searchLogs(any())).thenAnswer(
      (_) async => const PageResult<SshLogEntry>(
        items: <SshLogEntry>[
          SshLogEntry(
            date: null,
            area: 'CN',
            user: 'root',
            authMode: 'password',
            address: '1.1.1.1',
            port: '22',
            status: 'Success',
            message: '',
          ),
        ],
        total: 1,
      ),
    );
    when(() => service.exportLogs(any())).thenAnswer(
      (_) async => const FileSaveResult(success: true, filePath: '/tmp/ssh.log'),
    );
    provider = SshLogsProvider(service: service);
  });

  test('load fetches logs', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
  });

  test('exportLogs returns save result', () async {
    final result = await provider.exportLogs();

    expect(result?.success, isTrue);
  });
}
