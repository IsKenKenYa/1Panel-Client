import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/data/models/common_models.dart';
import 'package:onepanel_client/data/models/ssh_cert_models.dart';
import 'package:onepanel_client/features/ssh/providers/ssh_certs_provider.dart';
import 'package:onepanel_client/features/ssh/services/ssh_service.dart';

class _MockSshService extends Mock implements SSHService {}

void main() {
  late _MockSshService service;
  late SshCertsProvider provider;

  const cert = SshCertInfo(
    id: 1,
    createdAt: null,
    name: 'default',
    encryptionMode: 'ed25519',
    passPhrase: '',
    publicKey: '',
    privateKey: '',
    description: '',
  );

  setUpAll(() {
    registerFallbackValue(
      const SshCertOperate(
        name: 'default',
        mode: 'generate',
        encryptionMode: 'ed25519',
      ),
    );
  });

  setUp(() {
    service = _MockSshService();
    when(() => service.searchCerts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
        )).thenAnswer(
      (_) async => const PageResult<SshCertInfo>(
        items: <SshCertInfo>[cert],
        total: 1,
      ),
    );
    when(() => service.createCert(any())).thenAnswer((_) async {});
    when(() => service.updateCert(any())).thenAnswer((_) async {});
    when(() => service.deleteCerts(any(), forceDelete: any(named: 'forceDelete')))
        .thenAnswer((_) async {});
    when(() => service.syncCerts()).thenAnswer((_) async {});
    provider = SshCertsProvider(service: service);
  });

  test('load returns cert items', () async {
    await provider.load();

    expect(provider.items, hasLength(1));
  });

  test('syncCerts refreshes list', () async {
    await provider.load();

    final success = await provider.syncCerts();

    expect(success, isTrue);
    verify(() => service.syncCerts()).called(1);
  });
}
