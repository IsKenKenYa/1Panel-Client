import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/data/models/ssl_models.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/features/security_gateway/pages/security_gateway_center_page.dart';
import 'package:onepanel_client/features/security_gateway/providers/security_gateway_center_provider.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeSecurityGatewayCenterProvider extends SecurityGatewayCenterProvider {
  _FakeSecurityGatewayCenterProvider() : super(initialWebsiteId: 7) {
    panelSslInfo = <String, dynamic>{'domain': 'panel.example.com'};
    certificates = <WebsiteSSL>[
      WebsiteSSL(
        id: 9,
        primaryDomain: 'example.com',
        expireDate:
            DateTime.now().add(const Duration(days: 4)).toIso8601String(),
      ),
    ];
    openRestySnapshot = const OpenRestySnapshot(
      status: <String, dynamic>{'active': 1},
      https: <String, dynamic>{'https': true},
      modules: <String, dynamic>{'mirror': 'https://mirror.local'},
      configContent: 'http { server {} }',
    );
  }

  bool rollbackCalled = false;

  @override
  Future<void> load() async {}

  @override
  Future<bool> rollbackLatest() async {
    rollbackCalled = true;
    notifyListeners();
    return true;
  }
}

Widget _wrapTestApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('SecurityGatewayCenterPage triggers rollback action',
      (tester) async {
    final provider = _FakeSecurityGatewayCenterProvider();

    await tester.pumpWidget(
      _wrapTestApp(
        SecurityGatewayCenterPage(
          initialSection: SecurityGatewaySection.websiteCertificates,
          initialWebsiteId: 7,
          provider: provider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rollbackFinder =
        find.byKey(const Key('security-gateway-rollback-action'));
    await tester.ensureVisible(rollbackFinder);
    final button = tester.widget<OutlinedButton>(rollbackFinder);
    button.onPressed?.call();
    await tester.pumpAndSettle();

    expect(provider.rollbackCalled, isTrue);
    expect(find.text('Rolled back the latest local snapshot.'), findsOneWidget);
  });
}
