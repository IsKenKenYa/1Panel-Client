enum UIRenderMode {
  /// Native host shell (macOS SwiftUI / Windows WinUI3).
  native,

  /// Flutter-rendered MDUI3, solid surfaces (glass floats disabled).
  md3,

  /// Flutter-rendered MDUI3 with Liquid Glass navigation floats
  /// (AppBar / bottom nav / desktop sidebar rendered via glass package,
  /// following Apple Liquid Glass layering semantics).
  liquidGlass
}
