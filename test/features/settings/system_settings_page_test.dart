import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:onepanel_client/core/services/passkey_service.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';
import 'package:onepanel_client/features/settings/system_settings_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeSettingsService extends SettingsService {
  @override
  Future<SystemSettingInfo?> getSystemSettings() async {
    return const SystemSettingInfo(
      panelName: 'Panel',
      systemVersion: '1.0.0',
      proxyUrl: '',
      apiInterfaceStatus: 'Disable',
      ssl: 'Disable',
    );
  }

  @override
  Future<TerminalInfo?> getTerminalSettings() async {
    return const TerminalInfo(fontSize: '14');
  }

  @override
  Future<List<String>?> getNetworkInterfaces() async {
    return const <String>['eth0', 'wlan0'];
  }

  @override
  Future<dynamic> getAppStoreConfig() async {
    return const <String, dynamic>{'storeUrl': 'https://store.example.com'};
  }

  @override
  Future<dynamic> getAuthSetting() async {
    return const <String, dynamic>{'captcha': true};
  }

  @override
  Future<dynamic> getSSHConnection() async {
    return const <String, dynamic>{
      'host': '10.0.0.1',
      'port': 22,
      'user': 'root',
    };
  }

  @override
  Future<String?> getDashboardMemo() async {
    return 'memo';
  }
}

class _MockPasskeyService extends Mock implements PasskeyService {}

class _OneShotSettingsProvider extends SettingsProvider {
  _OneShotSettingsProvider({
    required super.service,
    required super.passkeyService,
  });

  bool _loaded = false;

  @override
  Future<void> load() async {
    if (_loaded) {
      return;
    }
    _loaded = true;
    await super.load();
  }
}

Future<void> _pumpWithFrameCap(
  WidgetTester tester, {
  int maxFrames = 120,
  Duration step = const Duration(milliseconds: 16),
}) async {
  for (var i = 0; i < maxFrames; i++) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) {
      return;
    }
  }
}

void main() {
  testWidgets('SystemSettingsPage shows new setting entries and network dialog',
      (tester) async {
    final passkeyService = _MockPasskeyService();
    when(() => passkeyService.getAvailability()).thenAnswer(
      (_) async => const PasskeyAvailabilityResult.unsupported('test'),
    );

    final provider = _OneShotSettingsProvider(
      service: _FakeSettingsService(),
      passkeyService: passkeyService,
    );
    await provider.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SystemSettingsPage(provider: provider),
      ),
    );

    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(SystemSettingsPage)),
    );

    final networkTile = find.text(l10n.sshSettingsNetworkSectionTitle);
    await tester.scrollUntilVisible(
      networkTile,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(networkTile.first);
    await _pumpWithFrameCap(tester);

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('eth0'), findsOneWidget);
    expect(find.text('wlan0'), findsOneWidget);
  });
}
