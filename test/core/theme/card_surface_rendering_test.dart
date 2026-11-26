import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/shared/widgets/app_card.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

/// 渲染层校验：页面、内容卡与浮层的实际底色必须构成 M3 的层级。
void main() {
  Widget harness(ThemeData theme, Widget child) => MaterialApp(
        theme: theme,
        home: Scaffold(body: Center(child: child)),
      );

  for (final (label, theme) in [
    ('浅色', AppTheme.getLightTheme()),
    ('深色', AppTheme.getDarkTheme()),
  ]) {
    testWidgets('$label 下内容卡与页面底色不同', (tester) async {
      await tester.pumpWidget(
        harness(theme, const SectionCard(title: 'Section', child: Text('Body'))),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(SectionCard),
          matching: find.byType(Card),
        ),
      );
      expect(
        card.color,
        AppTheme.cardSurface(theme.colorScheme),
        reason: '分组卡必须使用共享的卡片底色角色',
      );
      expect(card.color, isNot(theme.scaffoldBackgroundColor));
    });

    testWidgets('$label 下信息卡与页面底色不同', (tester) async {
      await tester.pumpWidget(
        harness(theme, const AppCard(title: 'Server')),
      );
      await tester.pumpAndSettle();

      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(AppCard),
          matching: find.byType(Card),
        ),
      );
      expect(card.color, AppTheme.cardSurface(theme.colorScheme));
      expect(card.color, isNot(theme.scaffoldBackgroundColor));
    });

    testWidgets('$label 下对话框底色高于页面', (tester) async {
      await tester.pumpWidget(
        harness(
          theme,
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(content: Text('Dialog')),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      final dialog = tester.widget<Material>(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(Material),
        ).first,
      );
      expect(dialog.color, AppTheme.floatSurface(theme.colorScheme));
      expect(
        dialog.color!.computeLuminance(),
        isNot(closeTo(theme.scaffoldBackgroundColor.computeLuminance(), 0.01)),
        reason: '对话浮层不得与页面同色',
      );
    });
  }
}
