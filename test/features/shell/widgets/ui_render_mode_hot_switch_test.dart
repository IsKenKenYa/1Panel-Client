import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onepanel_client/core/services/app_settings_controller.dart';
import 'package:onepanel_client/core/services/app_preferences_service.dart';
import 'package:onepanel_client/core/theme/ui_render_mode.dart';
import 'package:onepanel_client/core/theme/ui_render_policy.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

/// 渲染模式必须在运行期切换生效，不依赖重启应用。
void main() {
  test('模式切换同步刷新玻璃策略', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController(
      preferencesService: AppPreferencesService(),
    );
    addTearDown(controller.dispose);
    addTearDown(() => UIRenderPolicy.applyMode(UIRenderMode.md3));

    await controller.updateUIRenderMode(UIRenderMode.liquidGlass);
    expect(controller.uiRenderMode, UIRenderMode.liquidGlass);
    expect(UIRenderPolicy.liquidGlassEnabled, isTrue);
    expect(UIRenderPolicy.currentMode, UIRenderMode.liquidGlass);

    await controller.updateUIRenderMode(UIRenderMode.md3);
    expect(controller.uiRenderMode, UIRenderMode.md3);
    expect(UIRenderPolicy.liquidGlassEnabled, isFalse);
    expect(UIRenderPolicy.currentMode, UIRenderMode.md3);
  });

  test('渲染形态判定只认液态玻璃', () {
    expect(UIRenderPolicy.glassEnabledFor(UIRenderMode.liquidGlass), isTrue);
    expect(UIRenderPolicy.glassEnabledFor(UIRenderMode.md3), isFalse);
    expect(UIRenderPolicy.glassEnabledFor(UIRenderMode.native), isFalse);
  });

  testWidgets('底栏随设置切换即时更换形态，无需重建页面', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppSettingsController(
      preferencesService: AppPreferencesService(),
    );
    addTearDown(controller.dispose);
    addTearDown(() => UIRenderPolicy.applyMode(UIRenderMode.md3));

    await tester.pumpWidget(
      ChangeNotifierProvider<AppSettingsController>.value(
        value: controller,
        child: MaterialApp(
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              items: const [
                AppNavigationBarItem(
                  icon: Icons.dns_outlined,
                  selectedIcon: Icons.dns,
                  label: 'Servers',
                ),
                AppNavigationBarItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder,
                  label: 'Files',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    await controller.updateUIRenderMode(UIRenderMode.liquidGlass);
    await tester.pumpAndSettle();

    // 玻璃模式下全部目的地可用，底栏走 GlassTabBar 形态。
    expect(find.byType(GlassTabBar), findsOneWidget,
        reason: '切到液态玻璃后底栏应立即换成玻璃形态');

    await controller.updateUIRenderMode(UIRenderMode.md3);
    await tester.pumpAndSettle();

    expect(find.byType(GlassTabBar), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: '切回实色模式后底栏立即换回 NavigationBar');
    expect(tester.takeException(), isNull);
  });
}
