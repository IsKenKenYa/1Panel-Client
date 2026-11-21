import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/data/models/setting_models.dart';
import 'package:onepanel_client/data/models/ssh_settings_models.dart';
import 'package:onepanel_client/features/settings/language_settings_page.dart';
import 'package:onepanel_client/features/settings/legal_center_page.dart';
import 'package:onepanel_client/features/settings/panel_settings_page.dart';
import 'package:onepanel_client/features/settings/proxy_settings_page.dart';
import 'package:onepanel_client/features/settings/security_settings_page.dart';
import 'package:onepanel_client/features/settings/settings_provider.dart';
import 'package:onepanel_client/features/settings/settings_service.dart';
import 'package:onepanel_client/features/settings/terminal_settings_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class _FakeSettingsService extends SettingsService {
  @override
  Future<SystemSettingInfo?> getSystemSettings() async {
    return const SystemSettingInfo(
      panelName: 'Test Panel',
      systemVersion: '1.0.0',
      serverPort: '8080',
      proxyUrl: '',
      apiInterfaceStatus: 'Enable',
      ssl: 'Disable',
    );
  }

  @override
  Future<TerminalInfo?> getTerminalSettings() async {
    return const TerminalInfo(fontSize: '14');
  }

  @override
  Future<List<String>?> getNetworkInterfaces() async {
    return const <String>['eth0'];
  }

  @override
  Future<dynamic> getAppStoreConfig() async {
    return const <String, dynamic>{'storeUrl': 'https://store.example.com'};
  }

  @override
  Future<dynamic> getAuthSetting() async {
    return const <String, dynamic>{'captcha': false};
  }

  @override
  Future<SshLocalConnectionInfo> getSSHConnection() async {
    return const SshLocalConnectionInfo(
      addr: '10.0.0.1',
      port: 22,
      user: 'root',
    );
  }

  @override
  Future<String?> getDashboardMemo() async => null;

}

Widget _buildTestableWidget(Widget child, {SettingsProvider? provider}) {
  final settingsProvider = provider ??
      SettingsProvider(service: _FakeSettingsService());

  return ChangeNotifierProvider<SettingsProvider>.value(
    value: settingsProvider,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    ),
  );
}

void main() {
  group('PanelSettingsPage smoke test', () {
    testWidgets('renders without error', (tester) async {
      final provider = SettingsProvider(service: _FakeSettingsService());
      await provider.load();

      await tester.pumpWidget(_buildTestableWidget(
        const PanelSettingsPage(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PanelSettingsPage), findsOneWidget);
      expect(find.text('Test Panel'), findsOneWidget);
    });
  });

  group('SecuritySettingsPage smoke test', () {
    testWidgets('shows one account link for the selected panel', (tester) async {
      final provider = SettingsProvider(
        service: _FakeSettingsService(),
        serverUrl: 'https://panel.example.com',
      );
      await provider.load();

      await tester.pumpWidget(_buildTestableWidget(
        const SecuritySettingsPage(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      final accountLink = find.widgetWithText(ListTile, 'Panel account security');
      expect(accountLink, findsOneWidget);
      expect(tester.widget<ListTile>(accountLink).onTap, isNotNull);
    });
  });

  group('ProxySettingsPage smoke test', () {
    testWidgets('renders without error', (tester) async {
      final provider = SettingsProvider(service: _FakeSettingsService());
      await provider.load();

      await tester.pumpWidget(_buildTestableWidget(
        const ProxySettingsPage(),
        provider: provider,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(ProxySettingsPage), findsOneWidget);
    });
  });

  group('LanguageSettingsPage smoke test', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => AppSettingsController(),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const LanguageSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSettingsPage), findsOneWidget);
    });
  });

  group('LegalCenterPage smoke test', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const LegalCenterPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LegalCenterPage), findsOneWidget);
    });
  });

  group('TerminalSettingsPage smoke test', () {
    testWidgets('renders without error', (tester) async {
      final provider = SettingsProvider(service: _FakeSettingsService());
      await provider.load();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: TerminalSettingsPage(provider: provider),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TerminalSettingsPage), findsOneWidget);
    });
  });
}
