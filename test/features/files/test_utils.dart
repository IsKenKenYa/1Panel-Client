import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onepanelapp_app/features/files/files_provider.dart';
import 'package:onepanelapp_app/l10n/generated/app_localizations.dart';

Widget wrapWithMaterial(
  Widget widget, {
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: Scaffold(
      body: widget,
    ),
  );
}

Widget wrapWithLocalization({
  required Widget child,
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: Scaffold(body: child),
  );
}
