import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/features/shell/models/client_module.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/widgets/navigation/app_bottom_navigation_bar.dart';

void main() {
  group('Navigation Icon Optimization Tests', () {
    testWidgets('Bottom navigation bar displays new MD3 icons',
        (tester) async {
      final items = [
        const AppNavigationBarItem(
          icon: Icons.dns_outlined,
          selectedIcon: Icons.dns,
          label: '服务器',
        ),
        const AppNavigationBarItem(
          icon: Icons.folder_open_outlined,
          selectedIcon: Icons.folder_open,
          label: '文件',
        ),
        const AppNavigationBarItem(
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
          label: '容器',
        ),
        const AppNavigationBarItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: '设置',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            bottomNavigationBar: AppBottomNavigationBar(
              currentIndex: 0,
              onTap: (_) {},
              items: items,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证导航栏存在
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsWidgets);
      
      // 验证标签文本
      expect(find.text('服务器'), findsOneWidget);
      expect(find.text('文件'), findsOneWidget);
      expect(find.text('容器'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('ClientModule uses optimized MD3 icons', (tester) async {
      // 验证新图标
      expect(ClientModule.files.icon, Icons.folder_open_outlined);
      expect(ClientModule.files.selectedIcon, Icons.folder_open);
      
      expect(ClientModule.containers.icon, Icons.widgets_outlined);
      expect(ClientModule.containers.selectedIcon, Icons.widgets);
      
      expect(ClientModule.apps.icon, Icons.grid_view_outlined);
      expect(ClientModule.apps.selectedIcon, Icons.grid_view);
      
      expect(ClientModule.websites.icon, Icons.public_outlined);
      expect(ClientModule.websites.selectedIcon, Icons.public);
      
      expect(ClientModule.ai.icon, Icons.psychology_outlined);
      expect(ClientModule.ai.selectedIcon, Icons.psychology);
      
      expect(ClientModule.verification.icon, Icons.shield_outlined);
      expect(ClientModule.verification.selectedIcon, Icons.shield);
    });

    testWidgets('Navigation bar has smooth animations', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                bottomNavigationBar: AppBottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: const [
                    AppNavigationBarItem(
                      icon: Icons.dns_outlined,
                      selectedIcon: Icons.dns,
                      label: '服务器',
                    ),
                    AppNavigationBarItem(
                      icon: Icons.folder_open_outlined,
                      selectedIcon: Icons.folder_open,
                      label: '文件',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击第二个导航项
      await tester.tap(find.text('文件'));
      await tester.pump();

      // 验证动画正在进行
      expect(find.byType(AnimatedSwitcher), findsWidgets);
      
      // 等待动画完成
      await tester.pumpAndSettle();
      
      // 验证选中状态已更新
      expect(selectedIndex, 1);
    });
  });
}
