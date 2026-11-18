import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/core/utils/snackbar_utils.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('状态提示在 ${brightness.name} 主题中保持足够对比度', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(body: Text('Server')),
      ));
      final context = tester.element(find.text('Server'));
      final variants = {
        'success': SnackBarUtils.showSuccess,
        'warning': SnackBarUtils.showWarning,
        'information': SnackBarUtils.showInfo,
        'error': SnackBarUtils.showError,
      };
      final closeLabel = MaterialLocalizations.of(context).closeButtonTooltip;
      final close = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == closeLabel,
      );
      for (final entry in variants.entries) {
        final message = '${entry.key} ${brightness.name}';
        entry.value(
          context,
          message,
          action: SnackBarAction(label: 'Retry', onPressed: () {}),
        );
        await tester.pumpAndSettle();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        final text = find.text(message);
        final textColor = tester.widget<Text>(text).style?.color ??
            DefaultTextStyle.of(tester.element(text)).style.color!;
        final icon =
            (snackBar.content as Row).children.whereType<Icon>().single;
        final retry = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Retry'),
        );
        final colors = [
          textColor,
          icon.color!,
          tester.widget<IconButton>(close).color!,
          retry.style!.foregroundColor!.resolve({})!,
        ];
        final background = snackBar.backgroundColor!.computeLuminance();
        for (final color in colors) {
          final luminance = color.computeLuminance();
          final contrast = luminance > background
              ? (luminance + 0.05) / (background + 0.05)
              : (background + 0.05) / (luminance + 0.05);
          expect(contrast, greaterThanOrEqualTo(4.5), reason: message);
        }

        await tester.tap(close);
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets('窄屏大字号显示完整的错误提示和详情入口', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
        child: child!,
      ),
      home: const Scaffold(body: Text('Server')),
    ));
    final context = tester.element(find.text('Server'));
    SnackBarUtils.showErrorWithRetry(
      context,
      'Connection failed',
      () {},
      details: StateError('Connection refused'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(TextButton, 'Retry').hitTestable(),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, 'Details').hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byTooltip(MaterialLocalizations.of(context).closeButtonTooltip)
          .hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('SnackBarUtils.showErrorWithRetry shows snackbar with retry action',
      (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarUtils.showErrorWithRetry(
                    context,
                    '加载失败: 网络错误',
                    () => retried = true,
                    retryLabel: '重试',
                  );
                },
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    snackBar.action!.onPressed();

    expect(retried, isTrue);
  });

  testWidgets('SnackBarUtils.showError truncates long messages', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  SnackBarUtils.showError(context, 'x' * 200);
                },
                child: const Text('show'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final content = snackBar.content as Row;
    final text = content.children.whereType<Expanded>().first.child as Text;
    expect(text.data!.length, lessThanOrEqualTo(120));
  });
}
