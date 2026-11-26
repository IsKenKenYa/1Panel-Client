import SwiftUI

public extension View {
    /// 主操作按钮样式。
    ///
    /// iOS 26 与 macOS 26 起使用系统玻璃主按钮，让主操作与导航栏的
    /// Liquid Glass 属于同一层材质；更早的系统版本使用描边主按钮。
    @ViewBuilder
    func prominentActionButton() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
