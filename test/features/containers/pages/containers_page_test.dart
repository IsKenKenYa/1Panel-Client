import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanel_client/features/shell/widgets/module_subnav.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('containers module uses custom subnav instead of Material TabBar',
      (tester) async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    final controller = ModuleSubnavController(
      storageKey: 'container_module_subnav',
      defaultOrder: const ['containers', 'images'],
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
                  id: 'containers',
                  label: AppLocalizations.of(context).containerTabContainers,
                  icon: Icons.inventory_2_outlined,
                ),
                ModuleSubnavItem(
                  id: 'images',
                  label: AppLocalizations.of(context).containerTabImages,
                  icon: Icons.image_outlined,
                ),
              ],
              selectedId: 'containers',
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TabBar), findsNothing);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
    expect(find.text('Containers'), findsOneWidget);
    expect(find.text('Images'), findsOneWidget);
  });
}
