import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:onepanel_client/config/app_route_constants.dart';
import 'package:onepanel_client/core/channel/native_channel_manager.dart';
import 'package:onepanel_client/core/security/app_lock_settings_store.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/theme/app_design_tokens.dart';
import 'package:onepanel_client/core/theme/theme_controller.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/features/security/app_lock_controller.dart';
import 'package:onepanel_client/features/security/app_lock_gate.dart';
import 'package:onepanel_client/features/settings/mainland_sdk_disclosure_page.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/pages/settings/settings_page.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('本地设置持久化与应用锁保护范围', (tester) async {
    SharedPreferences.setPrefix(
      'kenpanel.preferences_test.${DateTime.now().microsecondsSinceEpoch}.',
    );
    final preferences = await SharedPreferences.getInstance();
    addTearDown(() async {
      for (final key in preferences.getKeys()) {
        await preferences.remove(key);
      }
    });
    final lockStore = AppLockSettingsStore();
    final initialLock = await lockStore.load();
    expect(initialLock.protectedModuleIds, isNotEmpty);
    await lockStore.save(initialLock.copyWith(protectedModuleIds: const []));
    await preferences.reload();
    expect((await lockStore.load()).protectedModuleIds, isEmpty);
    final settings = AppSettingsController();
    final appearance = ThemeController();
    addTearDown(settings.dispose);
    addTearDown(appearance.dispose);
    await Future.wait([settings.load(), appearance.load()]);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settings,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    final group = find.byType(SectionEntryList).first;
    final initialGroup = tester.widget<SectionEntryList>(group);
    await settings.updateCacheMaxSizeMB(256);
    await tester.pump();
    expect(tester.widget<SectionEntryList>(group), same(initialGroup));
    await expectLater(settings.updateCacheMaxSizeMB(0), throwsArgumentError);
    expect(settings.cacheMaxSizeMB, 256);
    await Future.wait([
      settings.updateLocale(const Locale('zh')),
      appearance.updateThemeMode(ThemeMode.dark),
      settings.updateLocale(const Locale('en')),
      appearance.updateThemeMode(ThemeMode.system),
      appearance.updateUseDynamicColor(false),
      appearance.updateSeedColor(Colors.indigo),
    ]);
    expect(settings.locale, const Locale('en'));
    await tester.pump();
    expect(tester.widget<SectionEntryList>(group), isNot(same(initialGroup)));
    expect(appearance.themeMode, ThemeMode.system);
    expect(appearance.useDynamicColor, isFalse);
    expect(appearance.seedColor.toARGB32(), Colors.indigo.toARGB32());

    final restoredSettings = AppSettingsController();
    final restoredAppearance = ThemeController();
    addTearDown(restoredSettings.dispose);
    addTearDown(restoredAppearance.dispose);
    await preferences.reload();
    await Future.wait([restoredSettings.load(), restoredAppearance.load()]);
    expect(restoredSettings.locale, settings.locale);
    expect(restoredSettings.cacheMaxSizeMB, 256);
    expect(restoredAppearance.themeMode, appearance.themeMode);
    expect(restoredAppearance.useDynamicColor, appearance.useDynamicColor);
    expect(
      restoredAppearance.seedColor.toARGB32(),
      appearance.seedColor.toARGB32(),
    );

    await restoredSettings.updateLocale(null);
    await restoredAppearance.resetSeedColor();
    restoredSettings.markNativeHostMissing();
    await restoredSettings.updateUIRenderMode(UIRenderMode.md3);
    expect(restoredSettings.nativeHostMissing, isFalse);
    final bootGlass = UIRenderPolicy.liquidGlassEnabled;
    final channel = NativeChannelManager.instance;
    final result = await channel.handleMethodCall('updateSetting', {
      'key': 'renderMode',
      'value': 'liquidGlass',
    });
    expect(result['success'], isTrue);
    final invalid = await channel.handleMethodCall('updateSetting', {
      'key': 'renderMode',
      'value': 'invalid',
    });
    expect(invalid['success'], isFalse);
    final service = AppPreferencesService();
    await service.saveUseFilePickerForFileOperations(false);
    await service.saveFileSaveSubDirectoryName('Reports');
    await preferences.reload();
    await Future.wait([settings.load(), appearance.load()]);
    expect(settings.locale, isNull);
    expect(appearance.seedColor, AppDesignTokens.seedColor);
    expect(settings.uiRenderMode, UIRenderMode.liquidGlass);
    expect(UIRenderPolicy.liquidGlassEnabled, bootGlass);
    expect(await service.loadUseFilePickerForFileOperations(), isFalse);
    expect(await service.loadFileSaveSubDirectoryName(), 'Reports');

    await lockStore.save(initialLock.copyWith(
      enabled: true,
      lockOnAppOpen: false,
      protectedModuleIds: const ['files'],
    ));
    final lock = AppLockController(settingsStore: lockStore);
    addTearDown(lock.dispose);
    await lock.load();
    Future<void> showTarget(String target) => tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: lock,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AppLockGate(target: target, child: const Text('content')),
            ),
          ),
        );
    await showTarget('files');
    expect(find.byType(AppLockUnlockView), findsOneWidget);
    expect(find.text('content'), findsNothing);
    await showTarget(AppRoutes.settingsAppLock);
    expect(find.byType(AppLockUnlockView), findsOneWidget);
    await showTarget('containers');
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('SDK 披露页复用依赖清单并支持手动刷新', (tester) async {
    const app = MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainlandSdkDisclosurePage(),
    );
    Future<List<String>> currentScan() => tester
        .widget<FutureBuilder<List<String>>>(
            find.byType(FutureBuilder<List<String>>))
        .future!;

    await tester.pumpWidget(app);
    final first = currentScan();
    final packages = await first;
    await tester.pumpAndSettle();
    expect(packages, isNotEmpty);
    expect(packages.toSet(), hasLength(packages.length));
    expect(find.byType(Scrollable), findsOneWidget);
    expect(tester.widget<ListView>(find.byType(ListView)).childrenDelegate,
        isA<SliverChildBuilderDelegate>());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app);
    expect(currentScan(), same(first));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await tester.pump();
    final refreshed = currentScan();
    expect(refreshed, isNot(same(first)));
    expect(await refreshed, packages);
    await tester.pumpAndSettle();
  });
}
