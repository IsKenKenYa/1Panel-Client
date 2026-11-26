import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/services/logger/log_level.dart';
import 'package:onepanel_client/core/theme/app_theme.dart';
import 'package:onepanel_client/features/databases/widgets/database_tile_content.dart';
import 'package:onepanel_client/features/logs/widgets/log_status_filter.dart';
import 'package:onepanel_client/features/settings/widgets/app_log_level_dialog.dart';
import 'package:onepanel_client/features/toolbox/widgets/toolbox_snapshot_list.dart';
import 'package:onepanel_client/shared/widgets/app_widgets.dart'
    show AppFormSaveBar, ExpressiveFilterBar, LabelValueRow, ModuleEmptyStateWidget,
        ModuleErrorStateWidget, SectionCard, TextPreviewSheet, showAppDetailsSheet;
import 'package:onepanel_client/shared/widgets/module_search_field.dart';
import 'package:onepanel_client/shared/widgets/status_label_widget.dart';

import 'ui_overflow_test_utils.dart';

void main() {
  test('明暗主题使用相同的触控尺寸和筛选标签颜色规则', () {
    for (final density in [VisualDensity.standard, VisualDensity.compact]) {
      for (final theme in [
        AppTheme.getLightTheme(visualDensity: density),
        AppTheme.getDarkTheme(visualDensity: density),
      ]) {
        final compact = density == VisualDensity.compact;
        expect(theme.visualDensity, density);
        expect(theme.listTileTheme.visualDensity, density);
        expect(theme.materialTapTargetSize, compact
            ? MaterialTapTargetSize.shrinkWrap
            : MaterialTapTargetSize.padded);
        expect(theme.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
            compact ? 44 : kMinInteractiveDimension);
        final color = theme.chipTheme.labelStyle?.color;
        expect(WidgetStateProperty.resolveAs<Color?>(color, {WidgetState.selected}),
            theme.colorScheme.onSecondaryContainer);
        expect(WidgetStateProperty.resolveAs<Color?>(color, {}),
            theme.colorScheme.onSurface);
      }
    }
  });

  const narrow = UiOverflowVariant(
    name: 'narrow panel',
    locale: Locale('en'),
    size: Size(225, 250),
    textScale: 2,
  );

  testWidgets('搜索字段分别传递输入和提交事件', (tester) async {
    final changed = <String>[];
    final submitted = <String>[];
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: ModuleSearchField(
        hintText: 'Search',
        onChanged: changed.add,
        onSubmitted: submitted.add,
        textInputAction: TextInputAction.search,
      ),
    );
    await tester.enterText(find.byType(TextField), 'host');
    expect(changed, ['host']);
    expect(submitted, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submitted, ['host']);
  });

  testWidgets('数据库操作有导航箭头，指标和状态保留各自的文字', (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: kGoldenBaselineVariants.first,
      child: const Column(children: [
        DatabaseTileContent.metric(icon: Icons.storage, title: 'Size', subtitle: '1 GB'),
        DatabaseTileContent.action(icon: Icons.edit, title: 'Edit', subtitle: 'Settings'),
        StatusLabelWidget(label: 'Running', color: Colors.green),
      ]),
    );
    expect(find.text('1 GB'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.widget<Text>(find.text('Running')).style?.color, Colors.green);
  });

  testWidgets('设置对话框返回用户选择的日志等级', (tester) async {
    AppLogLevel? selected;
    await pumpOverflowHarness(
      tester,
      variant: kGoldenBaselineVariants.first,
      child: Builder(builder: (context) => TextButton(
        onPressed: () async {
          selected = await showAppLogLevelDialog(context, AppLogLevel.warning);
        },
        child: const Text('Select level'),
      )),
    );
    await tester.tap(find.text('Select level'));
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is RadioListTile<AppLogLevel> && widget.value == AppLogLevel.fatal));
    await tester.pumpAndSettle();
    expect(selected, AppLogLevel.fatal);
  });

  testWidgets('工具数据首次失败可重试，有数据时刷新失败仍显示原记录', (tester) async {
    var retries = 0;
    Widget page(bool hasSnapshot) => ToolboxSnapshotList(
          hasSnapshot: hasSnapshot,
          isLoading: false,
          loadError: 'Load failed',
          onRetry: () => retries++,
          children: const [Text('Disk A')],
        );
    await pumpOverflowHarness(
      tester,
      variant: kGoldenBaselineVariants.first,
      child: page(false),
    );
    expect(find.byType(ModuleErrorStateWidget), findsOneWidget);
    expect(find.text('Disk A'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
    await pumpOverflowHarness(
      tester,
      variant: kGoldenBaselineVariants.first,
      child: page(true),
    );
    expect(find.byType(ModuleErrorStateWidget), findsNothing);
    expect(find.text('Disk A'), findsOneWidget);
  });

  testWidgets('保存中禁用按钮，防止重复提交', (tester) async {
    var saves = 0;
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: StatefulBuilder(
        builder: (context, setState) => AppFormSaveBar(
          isSaving: saves != 0,
          onSave: () => setState(() => saves++),
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(saves, 1);
  });

  testWidgets('文本预览显示可选正文并提供复制入口', (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants.first,
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => TextPreviewSheet.show(context, title: 'Log', content: 'Line 1'),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Log'), findsOneWidget);
    expect(tester.widget<SelectableText>(find.byType(SelectableText)).data, 'Line 1');
    expect(find.byTooltip('Copy'), findsOneWidget);
  });

  testWidgets('横屏详情弹层的大字号字段均可滚动查看', (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: const UiOverflowVariant(
        name: 'short landscape',
        locale: Locale('en'),
        size: Size(740, 360),
        textScale: 2,
      ),
      child: Builder(builder: (context) => TextButton(
        onPressed: () => showAppDetailsSheet(
          context,
          title: 'Network details',
          children: [
            for (var i = 0; i < 12; i++)
              LabelValueRow(label: 'Field $i', value: 'Value $i'),
          ],
        ),
        child: const Text('Details'),
      )),
    );
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Value 11'), 200,
        scrollable: find.descendant(
          of: find.byType(BottomSheet), matching: find.byType(Scrollable),
        ));
    expect(find.text('Value 11').hitTestable(), findsOneWidget);
    expect(find.byTooltip('Close').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('metadata labels and multiline values fit a narrow panel',
      (tester) async {
    const value = 'certificate.example.invalid';
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: ListView(
        children: const [
          LabelValueRow(label: 'Certificate provider', value: value),
        ],
      ),
    );
    await expectNoFlutterExceptions(tester);
    final field = tester.getRect(find.text('Certificate provider'));
    final content = tester.getRect(find.text(value));
    expect(content.top, greaterThanOrEqualTo(field.bottom));
    expect(content.right, lessThanOrEqualTo(narrow.size.width));
  });

  testWidgets('宽屏详情字段在同一行展示', (tester) async {
    await pumpOverflowHarness(
      tester,
      variant: kCoreOverflowVariants.last,
      child: const LabelValueRow(label: 'Provider', value: 'Certificate'),
    );
    final label = tester.getRect(find.text('Provider'));
    final value = tester.getRect(find.text('Certificate'));
    expect(value.left, greaterThanOrEqualTo(label.right));
    expect(value.top, label.top);
  });

  testWidgets('大字号分区标题与按钮可以分行，筛选项可滚动选择', (tester) async {
    String? selected;
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: ListView(children: [
        SectionCard(
          title: 'Certificate settings',
          action: TextButton(onPressed: () {}, child: const Text('Manage')),
          child: ExpressiveFilterBar(
            options: const [('all', 'All statuses'), ('ready', 'Ready')],
            selected: 'all',
            onSelected: (value) => selected = value,
          ),
        ),
      ]),
    );
    expect(
      tester.getTopLeft(find.widgetWithText(TextButton, 'Manage')).dy,
      greaterThanOrEqualTo(tester.getBottomLeft(find.text('Certificate settings')).dy),
    );
    await tester.ensureVisible(find.text('Ready'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ready'));
    await tester.pump();
    expect(selected, 'ready');
    await expectNoFlutterExceptions(tester);
  });

  testWidgets('both empty state actions are reachable with increased text',
      (tester) async {
    final calls = <String>[];
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: ModuleEmptyStateWidget(
        title: 'No snapshots',
        actions: [
          TextButton(
            onPressed: () => calls.add('create'),
            child: const Text('Create snapshot'),
          ),
          TextButton(
            onPressed: () => calls.add('import'),
            child: const Text('Import snapshot'),
          ),
        ],
      ),
    );
    for (final text in ['Create snapshot', 'Import snapshot']) {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
    }
    await expectNoFlutterExceptions(tester);
    expect(calls, ['create', 'import']);
  });

  testWidgets('task log filter includes executing and reports the API value',
      (tester) async {
    String? value;
    await pumpOverflowHarness(
      tester,
      variant: narrow,
      child: SingleChildScrollView(
        child: LogStatusFilter(
          value: 'Success',
          executingCount: 3,
          onChanged: (selection) => value = selection,
        ),
      ),
    );
    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(4));
    expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isTrue);
    await tester.ensureVisible(chips.last);
    await tester.tap(chips.last);
    expect(value, 'Executing');
  });
}
