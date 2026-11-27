import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/shared/widgets/section_card.dart';

void main() {
  Widget harness(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? AppTheme.getLightTheme(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  group('SectionPropertyList', () {
    testWidgets('多行属性合并到一张卡，空值显示占位', (tester) async {
      await tester.pumpWidget(
        harness(
          const SectionPropertyList(
            title: 'Info',
            properties: [
              SectionProperty(label: 'A', value: 'one'),
              SectionProperty(label: 'B', value: null),
              SectionProperty(label: 'C', value: ''),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = find.descendant(
        of: find.byType(SectionPropertyList),
        matching: find.byType(Card),
      );
      expect(cards, findsOneWidget,
          reason: '属性行必须共用一张卡，而不是每行一张');
      expect(find.byType(Divider), findsNWidgets(2),
          reason: '三行之间各有一次分隔');
      expect(find.text('one'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2));
    });

    testWidgets('窄宽度下标签与值换行显示', (tester) async {
      tester.view.physicalSize = const Size(240, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        harness(
          const SectionPropertyList(
            properties: [
              SectionProperty(
                label: 'A very long property label',
                value: 'A very long property value',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('操作按钮渲染在标题行', (tester) async {
      await tester.pumpWidget(
        harness(
          SectionPropertyList(
            title: 'Info',
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.refresh),
              ),
            ],
            properties: const [
              SectionProperty(label: 'A', value: 'one'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
    });
  });

  group('ExpressiveFilterBar', () {
    testWidgets('选中项使用次级容器色与配对前景色', (tester) async {
      String? picked;
      await tester.pumpWidget(
        harness(
          ExpressiveFilterBar(
            options: const [('a', 'All'), ('b', 'Running')],
            selected: 'b',
            onSelected: (value) => picked = value,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final selected = chips.firstWhere((chip) => chip.selected);
      final scheme = AppTheme.getLightTheme().colorScheme;
      expect(selected.selectedColor, scheme.secondaryContainer);
      expect(
        selected.labelStyle?.color,
        scheme.onSecondaryContainer,
      );

      await tester.tap(find.text('All'));
      expect(picked, 'a');
    });
  });
}
