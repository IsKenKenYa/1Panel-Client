enum UIRenderMode {
  /// SwiftUI 宿主（iOS、macOS）或 WinUI3 宿主（Windows）。
  native,

  /// 使用标准导航组件的 Flutter MDUI3 界面。
  md3,

  /// 使用玻璃效果导航组件的 Flutter MDUI3 界面。
  liquidGlass,
}
