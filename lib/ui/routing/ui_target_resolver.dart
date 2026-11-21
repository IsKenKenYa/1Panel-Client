import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onepanel_client/core/platform/platform_capabilities.dart';
import 'package:onepanel_client/core/utils/platform_utils.dart';

import 'ui_target.dart';

class UiTargetResolver {
  const UiTargetResolver._();

  static UiTarget resolve(BuildContext context, {double? width}) {
    return resolveForTest(
      isWeb: kIsWeb,
      platform: defaultTargetPlatform,
      width: width ?? MediaQuery.sizeOf(context).width,
      isOhos: PlatformCapabilities.current().isOhos,
    );
  }

  @visibleForTesting
  static UiTarget resolveForTest({
    required bool isWeb,
    required TargetPlatform platform,
    required double width,
    bool isOhos = false,
  }) {
    final (platformKind, tabletKind) = isWeb
        ? (UiPlatformKind.web, TabletKind.webTablet)
        : switch (platform.name) {
            'macOS' => (UiPlatformKind.desktopMacos, TabletKind.none),
            'windows' => (UiPlatformKind.desktopWindows, TabletKind.none),
            'linux' => (UiPlatformKind.desktopLinux, TabletKind.none),
            'iOS' => (UiPlatformKind.mobile, TabletKind.ipad),
            'android' when !isOhos =>
              (UiPlatformKind.mobile, TabletKind.androidPad),
            _ => (UiPlatformKind.harmony, TabletKind.harmonyPad),
          };
    final formFactor = switch (width) {
      < PlatformUtils.mobileWidthBreakpoint => UiFormFactor.phone,
      >= PlatformUtils.tabletWidthBreakpoint
          when platformKind != UiPlatformKind.mobile &&
              platformKind != UiPlatformKind.harmony => UiFormFactor.desktop,
      _ => UiFormFactor.tablet,
    };
    return UiTarget(
      platformKind: platformKind,
      formFactor: formFactor,
      tabletKind:
          formFactor == UiFormFactor.tablet ? tabletKind : TabletKind.none,
    );
  }
}
