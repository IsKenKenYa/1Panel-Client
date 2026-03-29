import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

void main() {
  testWidgets('SystemSettingsPage shows new setting entries and network dialog',
      (tester) async {
    final provider = SettingsProvider(service: _FakeSettingsService());

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: SystemSettingsPage(provider: provider),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_ethernet_outlined), findsOneWidget);
    expect(find.byIcon(Icons.device_hub_outlined), findsOneWidget);

    await tester.tap(find.text('Network').first);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('eth0'), findsOneWidget);
    expect(find.text('wlan0'), findsOneWidget);
  });
}
