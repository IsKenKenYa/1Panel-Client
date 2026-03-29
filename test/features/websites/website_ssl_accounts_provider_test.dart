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
  int createAcmeCallCount = 0;
  int deleteAcmeCallCount = 0;
  int createCaCallCount = 0;
  int deleteCaCallCount = 0;
  int obtainCallCount = 0;
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
  Future<void> createAcmeAccount({
    required String email,
    String type = 'letsencrypt',
    String keyType = '2048',
    bool useProxy = false,
    String? eabKid,
    String? eabHmacKey,
    String? caDirUrl,
    bool useEab = false,
  }) async {
    _maybeThrow();
    createAcmeCallCount += 1;
    _acmeAccounts.add(<String, dynamic>{
      'id': 200 + _acmeAccounts.length,
      'email': email,
      'type': type,
      'useProxy': useProxy,
    });
  }

  @override
  Future<void> deleteAcmeAccount(int id) async {
    _maybeThrow();
    deleteAcmeCallCount += 1;
    _acmeAccounts.removeWhere((item) => item['id'] == id);
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
  Future<void> createCertificateAuthority({
    required String name,
    required String commonName,
    required String country,
    required String organization,
    required String keyType,
    String? organizationUint,
    String? province,
    String? city,
  }) async {
    _maybeThrow();
    createCaCallCount += 1;
    _certificateAuthorities.add(<String, dynamic>{
      'id': 300 + _certificateAuthorities.length,
      'name': name,
      'commonName': commonName,
      'country': country,
      'organization': organization,
    });
  }

  @override
  Future<void> deleteCertificateAuthority(int id) async {
    _maybeThrow();
    deleteCaCallCount += 1;
    _certificateAuthorities.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<void> obtainCertificateByAuthority({
    required int id,
    required String domains,
    String keyType = '2048',
    int time = 1,
    String unit = 'year',
  }) async {
    _maybeThrow();
    obtainCallCount += 1;
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

  test('WebsiteSslAccountsProvider creates acme account and refreshes list',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final ok = await provider.createAcmeAccount(
      email: 'new@example.com',
      type: 'zerossl',
      useProxy: true,
    );

    expect(ok, isTrue);
    expect(service.createAcmeCallCount, 1);
    expect(
      provider.acmeAccounts.any((item) => item['email'] == 'new@example.com'),
      isTrue,
    );
    expect(provider.operationError, isNull);
  });

  test('WebsiteSslAccountsProvider deletes acme account and refreshes list',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    expect(provider.acmeAccounts, hasLength(1));

    final acmeId = provider.resolveAccountId(provider.acmeAccounts.first);
    final ok = await provider.deleteAcmeAccount(acmeId!);

    expect(ok, isTrue);
    expect(service.deleteAcmeCallCount, 1);
    expect(provider.acmeAccounts, isEmpty);
    expect(provider.operationError, isNull);
  });

  test(
      'WebsiteSslAccountsProvider creates certificate authority and refreshes',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final ok = await provider.createCertificateAuthority(
      name: 'test-ca',
      commonName: 'Test CA',
      country: 'CN',
      organization: 'Test Org',
      keyType: '2048',
    );

    expect(ok, isTrue);
    expect(service.createCaCallCount, 1);
    expect(
      provider.certificateAuthorities.any((item) => item['name'] == 'test-ca'),
      isTrue,
    );
    expect(provider.operationError, isNull);
  });

  test(
      'WebsiteSslAccountsProvider deletes certificate authority and refreshes',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    expect(provider.certificateAuthorities, hasLength(1));

    final caId =
        provider.resolveAccountId(provider.certificateAuthorities.first);
    final ok = await provider.deleteCertificateAuthority(caId!);

    expect(ok, isTrue);
    expect(service.deleteCaCallCount, 1);
    expect(provider.certificateAuthorities, isEmpty);
    expect(provider.operationError, isNull);
  });

  test('WebsiteSslAccountsProvider obtains certificate via CA', () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final caId =
        provider.resolveAccountId(provider.certificateAuthorities.first);
    final ok = await provider.obtainCertificateByAuthority(
      id: caId!,
      domains: 'example.com',
      keyType: '2048',
      time: 1,
      unit: 'year',
    );

    expect(ok, isTrue);
    expect(service.obtainCallCount, 1);
    expect(provider.operationError, isNull);
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

  test('WebsiteSslAccountsProvider clears operationError on next successful op',
      () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();

    service.failNextOperation = true;
    await provider.deleteDnsAccount(1);
    expect(provider.operationError, isNotNull);

    final ok = await provider.createDnsAccount(
      name: 'recovery',
      type: 'cloudflare',
      authorization: <String, dynamic>{'token': 'y'},
    );
    expect(ok, isTrue);
    expect(provider.operationError, isNull);
  });

  test('WebsiteSslAccountsProvider downloads CA file successfully', () async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await provider.load();
    final caId =
        provider.resolveAccountId(provider.certificateAuthorities.first);
    final link = await provider.downloadCertificateAuthorityFile(caId!);

    expect(link, equals('download://ca/$caId'));
    expect(provider.operationError, isNull);
  });
}
