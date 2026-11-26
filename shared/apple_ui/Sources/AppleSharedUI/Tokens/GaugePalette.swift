import SwiftUI

/// 资源占用阈值配色。
///
/// 阈值与 Dart 侧资源卡保持一致：低于 70% 用页面给定的语义主色，
/// 70% 起提示，90% 起进入危险区间。缺少数值时保留主色，
/// 由调用方显示不可用文案。
public enum GaugePalette {
    /// 提示阈值。
    public static let warningThreshold: Double = 70
    /// 危险阈值。
    public static let dangerThreshold: Double = 90

    /// 按占用百分比给出进度条与图标的颜色。
    ///
    /// `base` 由页面按字段指定，进入提示与危险区间后统一改为橙与红，
    /// 让状态本身先被看见。
    public static func color(for percent: Double?, base: Color) -> Color {
        guard let percent else { return base }
        if percent >= dangerThreshold { return .red }
        if percent >= warningThreshold { return .orange }
        return base
    }
}
