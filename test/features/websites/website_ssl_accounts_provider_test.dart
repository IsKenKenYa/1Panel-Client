import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/features/websites/providers/website_ssl_accounts_provider.dart';
import 'package:onepanel_client/features/websites/services/website_account_service.dart';

class _FakeWebsiteAccountService extends WebsiteAccountService {
  _FakeWebsiteAccountService()
      : _dnsAccounts = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 1,
            'name': 'dns-main',
            'type': 'cloudflare',
            'authorization': <String, dynamic>{'token': 'x'},
          },
        ],
        _acmeAccounts = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 2,
            'email': 'ops@example.com',
            'type': 'letsencrypt',
            'useProxy': false,
          },
        ],
        _certificateAuthorities = <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 3,
            'name': 'internal-ca',
            'commonName': 'Internal Root CA',
            'sslID': 99,
          },
        ],
        super(api: null);

  final List<Map<String, dynamic>> _dnsAccounts;
  final List<Map<String, dynamic>> _acmeAccounts;
  final List<Map<String, dynamic>> _certificateAuthorities;

  int createDnsCallCount = 0;
  int updateAcmeCallCount = 0;
  int deleteDnsCallCount = 0;
  int renewCallCount = 0;
  int? lastRenewSslId;
  bool failNextOperation = false;

  void _maybeThrow() {
    if (failNextOperation) {
      failNextOperation = false;
      throw Exception('mock failure');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadDnsAccounts() async {
    return List<Map<String, dynamic>>.from(_dnsAccounts);
  }

  @override
  Future<void> createDnsAccount({
    required String name,
    required String type,
    required Map<String, dynamic> authorization,
  }) async {
    _maybeThrow();
    createDnsCallCount += 1;
    _dnsAccounts.add(<String, dynamic>{
      'id': 100 + _dnsAccounts.length,
      'name': name,
      'type': type,
      'authorization': authorization,
    });
  }

  @override
  Future<void> deleteDnsAccount(int id) async {
    _maybeThrow();
    deleteDnsCallCount += 1;
    _dnsAccounts.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<List<Map<String, dynamic>>> loadAcmeAccounts() async {
    return List<Map<String, dynamic>>.from(_acmeAccounts);
  }

  @override
  Future<void> updateAcmeAccount({
    required int id,
    required bool useProxy,
  }) async {
    _maybeThrow();
    updateAcmeCallCount += 1;
    for (final item in _acmeAccounts) {
      if (item['id'] == id) {
        item['useProxy'] = useProxy;
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadCertificateAuthorities() async {
    return List<Map<String, dynamic>>.from(_certificateAuthorities);
  }

  @override
  Future<void> renewCertificateByAuthority(int sslId) async {
    _maybeThrow();
    renewCallCount += 1;
    lastRenewSslId = sslId;
  }

  @override
  Future<String> downloadCertificateAuthorityFile(int id) async {
    _maybeThrow();
    return 'download://ca/$id';
  }
}

void main() {
  test('WebsiteSslAccountsProvider loads all account sections', () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();

    expect(provider.error, isNull);
    expect(provider.dnsAccounts, hasLength(1));
    expect(provider.acmeAccounts, hasLength(1));
    expect(provider.certificateAuthorities, hasLength(1));
  });

  test('WebsiteSslAccountsProvider creates dns account and refreshes list',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final ok = await provider.createDnsAccount(
      name: 'dns-backup',
      type: 'aliyun',
      authorization: <String, dynamic>{'accessKey': 'ak'},
    );

    expect(ok, isTrue);
    expect(service.createDnsCallCount, 1);
    expect(
      provider.dnsAccounts.any((item) => item['name'] == 'dns-backup'),
      isTrue,
    );
    expect(provider.operationError, isNull);
  });

  test('WebsiteSslAccountsProvider updates acme proxy setting', () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final acmeId = provider.resolveAccountId(provider.acmeAccounts.first);
    final ok = await provider.updateAcmeAccount(
      id: acmeId!,
      useProxy: true,
    );

    expect(ok, isTrue);
    expect(service.updateAcmeCallCount, 1);
    expect(provider.acmeAccounts.first['useProxy'], isTrue);
  });

  test('WebsiteSslAccountsProvider renews certificate and tracks failures',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final ok = await provider.renewCertificateByAuthority(99);

    expect(ok, isTrue);
    expect(service.renewCallCount, 1);
    expect(service.lastRenewSslId, 99);

    service.failNextOperation = true;
    final failed = await provider.deleteDnsAccount(1);

    expect(failed, isFalse);
    expect(provider.operationError, contains('mock failure'));
  });
}
