import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onepanel_client/features/websites/pages/website_ssl_accounts_page.dart';
import 'package:onepanel_client/features/websites/providers/website_ssl_accounts_provider.dart';
import 'package:onepanel_client/features/websites/services/website_account_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

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

  bool failDnsCreate = false;
  bool failAcmeCreate = false;
  bool failCaCreate = false;
  int deleteAcmeCallCount = 0;
  int deleteCaCallCount = 0;

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
    if (failDnsCreate) {
      throw Exception('mock failure: create dns');
    }
    _dnsAccounts.add(<String, dynamic>{
      'id': 100 + _dnsAccounts.length,
      'name': name,
      'type': type,
      'authorization': authorization,
    });
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
    if (failAcmeCreate) {
      throw Exception('mock failure: create acme');
    }
    _acmeAccounts.add(<String, dynamic>{
      'id': 200 + _acmeAccounts.length,
      'email': email,
      'type': type,
      'useProxy': useProxy,
    });
  }

  @override
  Future<void> deleteAcmeAccount(int id) async {
    deleteAcmeCallCount += 1;
    _acmeAccounts.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<void> updateAcmeAccount({
    required int id,
    required bool useProxy,
  }) async {
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
    if (failCaCreate) {
      throw Exception('mock failure: create ca');
    }
    _certificateAuthorities.add(<String, dynamic>{
      'id': 300 + _certificateAuthorities.length,
      'name': name,
      'commonName': commonName,
    });
  }

  @override
  Future<void> deleteCertificateAuthority(int id) async {
    deleteCaCallCount += 1;
    _certificateAuthorities.removeWhere((item) => item['id'] == id);
  }

  @override
  Future<void> renewCertificateByAuthority(int sslId) async {}

  @override
  Future<String> downloadCertificateAuthorityFile(int id) async {
    return 'download://ca/$id';
  }
}

void main() {
  Widget _buildPage(WebsiteSslAccountsProvider provider) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: WebsiteSslAccountsPage(provider: provider),
    );
  }

  testWidgets('WebsiteSslAccountsPage renders three account tabs',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    expect(find.text('CA'), findsOneWidget);
    expect(find.text('ACME'), findsOneWidget);
    expect(find.text('DNS'), findsOneWidget);

    expect(find.text('internal-ca'), findsOneWidget);

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();
    expect(find.text('ops@example.com'), findsOneWidget);

    await tester.tap(find.text('DNS'));
    await tester.pumpAndSettle();
    expect(find.text('dns-main'), findsOneWidget);
  });

  testWidgets('WebsiteSslAccountsPage CA tab shows obtain/renew/download icons',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    // CA tab is default; check action icons are present
    expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('WebsiteSslAccountsPage ACME tab shows edit/delete icons',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('WebsiteSslAccountsPage ACME tab shows email and type info',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();

    expect(find.text('ops@example.com'), findsOneWidget);
    expect(find.textContaining('letsencrypt'), findsOneWidget);
  });

  testWidgets('WebsiteSslAccountsPage creates ACME account via dialog',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create ACME account'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    final allTextFields = find.byType(TextField);
    await tester.enterText(allTextFields.first, 'newuser@example.com');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Dialog should close on success
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
      'WebsiteSslAccountsPage keeps ACME dialog open on create failure',
      (tester) async {
    final service = _FakeWebsiteAccountService()..failAcmeCreate = true;
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create ACME account'));
    await tester.pumpAndSettle();

    final allTextFields = find.byType(TextField);
    await tester.enterText(allTextFields.first, 'fail@example.com');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('mock failure'), findsOneWidget);
  });

  testWidgets('WebsiteSslAccountsPage shows confirm dialog when deleting ACME',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACME'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteAcmeCallCount, 1);
  });

  testWidgets(
      'WebsiteSslAccountsPage shows confirm dialog when deleting CA entry',
      (tester) async {
    final service = _FakeWebsiteAccountService();
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(service.deleteCaCallCount, 1);
  });

  testWidgets('WebsiteSslAccountsPage keeps dns dialog open on save failure',
      (tester) async {
    final service = _FakeWebsiteAccountService()..failDnsCreate = true;
    final provider = WebsiteSslAccountsProvider(service: service);

    await tester.pumpWidget(_buildPage(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DNS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create DNS account'));
    await tester.pumpAndSettle();

    // Dialog now has: name TextField + template auth field (cloudflare: API Token)
    // Type is a DropdownButtonFormField (not a TextField)
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'dns-backup');
    await tester.enterText(fields.at(1), 'test-api-token');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('mock failure'), findsOneWidget);
  });
}
