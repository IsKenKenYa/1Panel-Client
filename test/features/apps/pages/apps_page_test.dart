import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanel_client/features/shell/widgets/module_subnav.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('apps module uses custom subnav instead of Material TabBar',
      (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = ModuleSubnavController(
      storageKey: 'apps_module_subnav',
      defaultOrder: const ['installed', 'store'],
      maxVisibleItems: 2,
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(
          builder: (context) => Scaffold(
            body: ModuleSubnav(
              controller: controller,
              items: [
                ModuleSubnavItem(
                  id: 'installed',
                  label: AppLocalizations.of(context).appStoreInstalled,
                  icon: Icons.download_done_outlined,
                ),
                ModuleSubnavItem(
                  id: 'store',
                  label: AppLocalizations.of(context).appStoreTitle,
                  icon: Icons.storefront_outlined,
                ),
              ],
              selectedId: 'installed',
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('Installed'), findsOneWidget);
    expect(find.text('App Store'), findsOneWidget);
  });
}
