/// macOS native window appearance/material context returned via platform channel.
///
/// Contains appearance mode, accessibility toggles, and recommended visual tuning
/// values that Flutter shell can use to better match NSVisualEffect behavior.
class MacosAppearanceContextModel {
  const MacosAppearanceContextModel({
    required this.isDarkMode,
    required this.isHighContrast,
    required this.reduceTransparencyEnabled,
    required this.windowOpaque,
    required this.titlebarTransparent,
    required this.backingScaleFactor,
    required this.preferredGlassBlurSigma,
    required this.preferredSidebarAlpha,
    required this.preferredContentAlpha,
  });

  final bool isDarkMode;
  final bool isHighContrast;
  final bool reduceTransparencyEnabled;
  final bool windowOpaque;
  final bool titlebarTransparent;
  final double backingScaleFactor;
  final double preferredGlassBlurSigma;
  final double preferredSidebarAlpha;
  final double preferredContentAlpha;

  static const fallback = MacosAppearanceContextModel(
    isDarkMode: false,
    isHighContrast: false,
    reduceTransparencyEnabled: false,
    windowOpaque: false,
    titlebarTransparent: true,
    backingScaleFactor: 1,
    preferredGlassBlurSigma: 16,
    preferredSidebarAlpha: 0.65,
    preferredContentAlpha: 0.85,
  );

  factory MacosAppearanceContextModel.fromMap(Map<Object?, Object?> map) {
    double parseDouble(Object? value, double fallback) {
      if (value is num) {
        return value.toDouble();
      }
      return fallback;
    }

    bool parseBool(Object? value, bool fallback) {
      if (value is bool) {
        return value;
      }
      return fallback;
    }

    return MacosAppearanceContextModel(
      isDarkMode: parseBool(map['isDarkMode'], false),
      isHighContrast: parseBool(map['isHighContrast'], false),
      reduceTransparencyEnabled: parseBool(map['reduceTransparencyEnabled'], false),
      windowOpaque: parseBool(map['windowOpaque'], false),
      titlebarTransparent: parseBool(map['titlebarTransparent'], true),
      backingScaleFactor: parseDouble(map['backingScaleFactor'], 1),
      preferredGlassBlurSigma: parseDouble(map['preferredGlassBlurSigma'], 16),
      preferredSidebarAlpha: parseDouble(map['preferredSidebarAlpha'], 0.65),
      preferredContentAlpha: parseDouble(map['preferredContentAlpha'], 0.85),
    );
  }
}
