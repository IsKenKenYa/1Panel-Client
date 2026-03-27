import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_center_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/security_gateway/security_gateway_snapshot_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOpenRestyService extends OpenRestyService {
  @override
  Future<OpenRestySnapshot> loadSnapshot() async {
    return const OpenRestySnapshot(
      status: <String, dynamic>{'active': 0},
      https: <String, dynamic>{'https': false, 'sslRejectHandshake': false},
      modules: <String, dynamic>{'mirror': '', 'modules': []},
      configContent: '',
    );
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
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SecurityGatewaySnapshotStore.instance.resetForTest();
  });

  testWidgets(
      'OpenResty center renders five cards, risk banner, and diff preview entry',
      (tester) async {
    final provider = OpenRestyProvider(service: _FakeOpenRestyService());
    await provider.loadAll();

    await tester.pumpWidget(
      _wrapTestApp(
        ChangeNotifierProvider<OpenRestyProvider>.value(
          value: provider,
          child: const OpenRestyCenterPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const statusKey = Key('openresty-section-status');
    const httpsKey = Key('openresty-section-https');
    const modulesKey = Key('openresty-section-modules');
    const configKey = Key('openresty-section-config');
    const buildKey = Key('openresty-section-build');

    expect(find.byKey(statusKey), findsOneWidget);
    expect(find.byKey(const Key('openresty-risk-banner')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(httpsKey), 200);
    await tester.scrollUntilVisible(find.byKey(modulesKey), 200);
    await tester.scrollUntilVisible(find.byKey(configKey), 200);
    await tester.scrollUntilVisible(find.byKey(buildKey), 200);

    expect(find.byKey(httpsKey), findsOneWidget);
    expect(find.byKey(modulesKey), findsOneWidget);
    expect(find.byKey(configKey), findsOneWidget);
    expect(find.byKey(buildKey), findsOneWidget);
    expect(find.text('Preview diff'), findsWidgets);
  });
}
