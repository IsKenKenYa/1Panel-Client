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
  Future<List<Map<String, dynamic>>> loadCertificateAuthorities() async {
    return List<Map<String, dynamic>>.from(_certificateAuthorities);
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

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(3));
    await tester.enterText(fields.at(0), 'dns-backup');
    await tester.enterText(fields.at(1), 'aliyun');
    await tester.enterText(fields.at(2), '{"token":"abc"}');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('mock failure'), findsOneWidget);
  });
}
