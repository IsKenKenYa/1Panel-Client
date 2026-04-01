import 'package:flutter/foundation.dart';

/// UI target describing platform family + form factor.
///
/// Note: this is a UI-level concept (routing/layout), not a domain concept.
enum UiPlatformKind {
  mobile,
  desktopMacos,
  desktopWindows,
  desktopLinux,
  web,
}

enum UiFormFactor {
  phone,
  tablet,
  desktop,
}

enum TabletKind {
  none,
  ipad,
  androidPad,
  webTablet,
}

@immutable
class UiTarget {
  const UiTarget({
    required this.platformKind,
    required this.formFactor,
    this.tabletKind = TabletKind.none,
  });

  final UiPlatformKind platformKind;
  final UiFormFactor formFactor;
  final TabletKind tabletKind;

  bool get isDesktop => formFactor == UiFormFactor.desktop;
  bool get isTablet => formFactor == UiFormFactor.tablet;
  bool get isPhone => formFactor == UiFormFactor.phone;
}

