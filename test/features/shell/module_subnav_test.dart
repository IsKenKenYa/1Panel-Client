import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/shell/controllers/module_subnav_controller.dart';
import 'package:onepanel_client/features/shell/widgets/module_subnav.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

const _items = [
  ModuleSubnavItem(id: 'list', label: 'List', icon: Icons.view_list_outlined),
  ModuleSubnavItem(id: 'jobs', label: 'Jobs', icon: Icons.work_outline),
  ModuleSubnavItem(id: 'runs', label: 'Runs', icon: Icons.play_arrow_outlined),
  ModuleSubnavItem(
      id: 'logs', label: 'Logs', icon: Icons.receipt_long_outlined),
  ModuleSubnavItem(id: 'rules', label: 'Rules', icon: Icons.rule_outlined),
];

void main() {
  testWidgets('desktop uses the content pane width and a keyboard popup',
      (tester) async {
    await _pumpSubnav(tester, selectedId: 'logs', paneWidth: 420);

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Logs'), findsNothing);

    for (var index = 0; index < 4; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Logs'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Logs'), findsNothing);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('touch overflow and customization use the same visible count',
      (tester) async {
    String? selected;
    await _pumpSubnav(tester,
        paneWidth: 400, onSelected: (id) => selected = id);

    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle();
    expect(selected, 'logs');

    await tester.tap(find.byTooltip('Customize sections'));
    await tester.pumpAndSettle();
    expect(find.text('The first 3 items stay visible. Others move into More.'),
        findsOneWidget);
    final logRow =
        find.ancestor(of: find.text('Logs'), matching: find.byType(ListTile));
    expect(find.descendant(of: logRow, matching: find.text('In More')),
        findsOneWidget);
  },
      variant: const TargetPlatformVariant(
          {TargetPlatform.android, TargetPlatform.iOS}));
}

Future<void> _pumpSubnav(
  WidgetTester tester, {
  required double paneWidth,
  String selectedId = 'list',
  ValueChanged<String>? onSelected,
}) async {
  final controller = ModuleSubnavController(
    storageKey: 'module-subnav-widget-test',
    defaultOrder: _items.map((item) => item.id).toList(),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: paneWidth,
          child: ModuleSubnav(
            controller: controller,
            items: _items,
            selectedId: selectedId,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}
