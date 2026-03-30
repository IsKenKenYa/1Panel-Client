import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onepanel_client/l10n/generated/app_localizations.dart';

class UiOverflowVariant {
  const UiOverflowVariant({
    required this.name,
    required this.locale,
    required this.size,
    required this.textScale,
  });

  final String name;
  final Locale locale;
  final Size size;
  final double textScale;
}

const List<UiOverflowVariant> kCoreOverflowVariants = [
  UiOverflowVariant(
    name: 'en-small-portrait-1.0x',
    locale: Locale('en'),
    size: Size(360, 640),
    textScale: 1.0,
  ),
  UiOverflowVariant(
    name: 'zh-small-portrait-2.0x',
    locale: Locale('zh'),
    size: Size(360, 640),
    textScale: 2.0,
  ),
  UiOverflowVariant(
    name: 'en-tablet-portrait-1.3x',
    locale: Locale('en'),
    size: Size(600, 1024),
    textScale: 1.3,
  ),
  UiOverflowVariant(
    name: 'zh-desktop-landscape-1.0x',
    locale: Locale('zh'),
    size: Size(1280, 720),
    textScale: 1.0,
  ),
];

Future<void> pumpOverflowHarness(
  WidgetTester tester, {
  required Widget child,
  required UiOverflowVariant variant,
  bool settle = true,
  bool wrapWithScaffold = true,
}) async {
  tester.view.physicalSize = variant.size;
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      locale: variant.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, appChild) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(variant.textScale),
          ),
          child: appChild ?? const SizedBox.shrink(),
        );
      },
      home: wrapWithScaffold ? Scaffold(body: child) : child,
    ),
  );
  await tester.pump();
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

Future<void> expectNoFlutterExceptions(
  WidgetTester tester, {
  String? reason,
}) async {
  await tester.pump();
  final errors = <Object>[];
  Object? error = tester.takeException();
  while (error != null) {
    errors.add(error);
    error = tester.takeException();
  }

  expect(
    errors,
    isEmpty,
    reason: reason ?? 'Unexpected Flutter exceptions: $errors',
  );
}
