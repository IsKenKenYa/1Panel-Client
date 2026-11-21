import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/config/api_config.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/features/shell/controllers/current_server_controller.dart';
import 'package:onepanel_client/features/shell/widgets/server_switcher_action.dart';
import 'package:provider/provider.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  const desktop = UiOverflowVariant(
    name: 'desktop-split',
    locale: Locale('en'),
    size: Size(1200, 640),
    textScale: 2,
  );
  const landscape = UiOverflowVariant(
    name: 'short-landscape',
    locale: Locale('en'),
    size: Size(640, 240),
    textScale: 2,
  );

  testWidgets('服务器切换按钮按所在分栏选择图标或文字', (tester) async {
    final controller = CurrentServerController();
    addTearDown(controller.dispose);
    await pumpOverflowHarness(
      tester,
      variant: desktop,
      child: ChangeNotifierProvider.value(
        value: controller,
        child: const Row(
          children: [
            SizedBox(
              width: 280,
              child: AdaptiveLayoutViewport(child: ServerSwitcherAction()),
            ),
            Expanded(
              child: AdaptiveLayoutViewport(child: ServerSwitcherAction()),
            ),
          ],
        ),
      ),
    );
    expect(find.widgetWithIcon(IconButton, Icons.dns_outlined), findsOneWidget);
    expect(find.byTooltip('Switch server'), findsOneWidget);
    expect(find.text('Switch server'), findsOneWidget);
    await expectNoFlutterExceptions(tester);
  });

  testWidgets('横屏短窗口放大字号后可以访问空目录的两个管理入口', (tester) async {
    var manageCount = 0;
    await pumpOverflowHarness(
      tester,
      variant: landscape,
      child: Center(
        child: SizedBox(
          width: 256,
          height: 150,
          child: ServerPickerSheet(
            servers: const [],
            selectedId: null,
            isLoading: false,
            onSelect: (_) => fail('空目录不应有可选择的服务器'),
            onManage: () => manageCount++,
          ),
        ),
      ),
    );
    for (final label in ['Servers', 'No servers yet']) {
      final action = find.text(label);
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action.hitTestable());
    }
    expect(manageCount, 2);
    await expectNoFlutterExceptions(tester);
  });

  for (final variant in [desktop, landscape]) {
    testWidgets('${variant.name} 的长目录按需构建并返回点击的服务器 ID', (tester) async {
      String? selectedId;
      var managed = false;
      final servers = List.generate(
        240,
        (index) => ApiConfig(
          id: 'server-$index',
          name: 'Production server number $index',
          url: 'https://server-$index.example.invalid',
          apiKey: '',
        ),
      );
      final short = variant == landscape;
      await pumpOverflowHarness(
        tester,
        variant: variant,
        child: Center(
          child: SizedBox(
            width: short ? 256 : 320,
            height: short ? 150 : 560,
            child: ServerPickerSheet(
              servers: servers,
              selectedId: servers.first.id,
              isLoading: false,
              onSelect: (id) => selectedId = id,
              onManage: () => managed = true,
            ),
          ),
        ),
      );
      final firstRow = find.byKey(ValueKey(servers.first.id));
      // 150px 高的横向视口里标题区占满首屏，首行不一定已构建；
      // 该变体只验证按需构建与滚动选择，纵向视口再校验选中态。
      if (!short) {
        expect(tester.widget<ListTile>(firstRow).selected, isTrue);
      }
      expect(find.byKey(ValueKey(servers.last.id)), findsNothing);
      final next = find.byKey(ValueKey(servers[35].id));
      await tester.scrollUntilVisible(next, 140, maxScrolls: 120);
      await tester.pumpAndSettle();
      await tester.tap(next.hitTestable());
      await tester.pump();
      expect(selectedId, servers[35].id);
      final manage = find.byIcon(Icons.settings_outlined);
      if (short) {
        await tester.scrollUntilVisible(manage, -140, maxScrolls: 120);
      }
      await tester.tap(manage.hitTestable());
      expect(managed, isTrue);
      await expectNoFlutterExceptions(tester);
    });
  }
}
