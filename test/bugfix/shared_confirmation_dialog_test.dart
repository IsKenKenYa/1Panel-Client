import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/layout/adaptive_layout.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_dialog.dart';
import 'package:onepanel_client/shared/widgets/forms/app_form_panel.dart';
import 'package:onepanel_client/shared/widgets/operations/confirm_action_sheet_widget.dart';

Future<BuildContext> _pumpPage(
  WidgetTester tester, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: const Scaffold(body: Text('Server')),
  ));
  return tester.element(find.text('Server'));
}

void main() {
  testWidgets('分栏内打开表单采用栏宽，取消返回空结果', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: Row(children: [
          SizedBox(
            width: 400,
            child: AdaptiveLayoutViewport(child: Text('Narrow')),
          ),
          Expanded(child: AdaptiveLayoutViewport(child: Text('Wide'))),
        ]),
      ),
    ));
    Future<String?> open(String pane) => showAdaptiveFormPanel<String>(
          tester.element(find.text(pane)),
          builder: (context) => AppFormPanel(
            title: 'Edit',
            content: const TextField(),
            onConfirm: () async => Navigator.of(context).pop('saved'),
          ),
        );
    final narrowResult = open('Narrow');
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(await narrowResult, isNull);
    final wideResult = open('Wide');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(await wideResult, isNull);
  });

  testWidgets('确认提交期间忽略重复点击和关闭操作', (tester) async {
    final context = await _pumpPage(tester);
    final submission = Completer<void>();
    var calls = 0;
    final result = showAppFormDialog(
      context,
      title: 'Delete file?',
      content: const Text('The selected file will be deleted.'),
      destructive: true,
      onConfirm: () {
        calls++;
        return submission.future;
      },
    );
    await tester.pumpAndSettle();

    final confirm = find.byType(FilledButton);
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    final colorScheme = Theme.of(context).colorScheme;
    expect(
      tester.widget<FilledButton>(confirm).style?.backgroundColor?.resolve({}),
      colorScheme.error,
    );
    expect(tester.getCenter(confirm).dy, tester.getCenter(cancel).dy);
    await tester.tap(confirm);
    await tester.tap(confirm);
    await tester.pump();

    expect(calls, 1);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(tester.widget<TextButton>(cancel).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.tapAt(const Offset(10, 10));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AlertDialog), findsOneWidget);

    submission.complete();
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(find.text('Server'), findsOneWidget);
  });

  testWidgets('确认提交失败后可在原对话框重试', (tester) async {
    final context = await _pumpPage(tester);
    final submission = Completer<void>();
    var calls = 0;
    final result = showAppFormDialog(
      context,
      title: 'Save changes?',
      content: const Text('Update the connection settings.'),
      onConfirm: () => calls++ == 0 ? submission.future : Future<void>.value(),
    );
    await tester.pumpAndSettle();

    final confirm = find.byType(FilledButton);
    await tester.tap(confirm);
    await tester.pump();
    submission.completeError(StateError('Save failed'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
    expect(calls, 2);
  });

  testWidgets('短屏幕上的确认表单可以滚动到操作按钮', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final context = await _pumpPage(tester, textScale: 2);
    final result = ConfirmActionSheetWidget.show(
      context,
      title: 'Delete backup record?',
      message: List.filled(
        4,
        'This removes the backup record and the associated files from the server.',
      ).join(' '),
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final action = find.widgetWithText(FilledButton, 'Delete');
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('手机表单的操作按钮适应大字号和屏幕键盘', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    final context = await _pumpPage(tester, textScale: 2);
    const saveLabel = 'Save application configuration';
    final result = showAdaptiveFormPanel<bool>(
      context,
      builder: (sheetContext) => AppFormPanel(
        title: 'Edit application',
        content: const TextField(),
        confirmLabel: saveLabel,
        onConfirm: () async => Navigator.of(sheetContext).pop(true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byType(TextField));
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final save = find.widgetWithText(FilledButton, saveLabel);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(save).dy, lessThanOrEqualTo(400));
    expect(save.hitTestable(), findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets(
    '宽屏上的确认操作支持 Esc 取消并恢复焦点',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      bool? confirmed;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (context) {
            return FilledButton(
              focusNode: focusNode,
              autofocus: true,
              onPressed: () async {
                confirmed = await ConfirmActionSheetWidget.show(
                  context,
                  title: 'Delete server?',
                  message: 'Remove the saved server connection.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
              },
              child: const Text('Remove server'),
            );
          }),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);
      expect(focusNode.hasPrimaryFocus, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
