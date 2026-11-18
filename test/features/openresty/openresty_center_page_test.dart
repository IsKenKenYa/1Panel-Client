import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/openresty/pages/openresty_center_page.dart';
import 'package:onepanel_client/features/openresty/providers/openresty_provider.dart';
import 'package:onepanel_client/features/openresty/services/openresty_service.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/operations/module_error_state_widget.dart';
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

/// 模拟 OpenResty 未安装：服务端 500 "record not found"。
class _NotInstalledOpenRestyService extends OpenRestyService {
  @override
  Future<OpenRestySnapshot> loadSnapshot() async {
    throw Exception('服务错误: record not found');
  }
}

Widget _wrapTestApp(Widget child) {
  return ChangeNotifierProvider<CurrentServerController>(
    create: (_) => _FakeCurrentServerController(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

class _FakeCurrentServerController extends CurrentServerController {
  @override
  String? get currentServerId => 'server-1';

  @override
  bool get hasServer => true;
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

  testWidgets(
      'OpenResty center renders not-installed empty state instead of error view',
      (tester) async {
    // 回归（P1-7）：OpenResty 未安装时服务端返回 "record not found"，
    // 页面应渲染未安装空态与「前往应用商店」入口，而不是加载失败红屏。
    final provider = OpenRestyProvider(service: _NotInstalledOpenRestyService());
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

    expect(find.byKey(const Key('openresty-not-installed-empty')),
        findsOneWidget);
    expect(find.byType(ModuleErrorStateWidget), findsNothing);
    expect(find.text('Go to App Store'), findsOneWidget);
  });
}
