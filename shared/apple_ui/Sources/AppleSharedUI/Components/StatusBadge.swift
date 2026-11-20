import SwiftUI

/// 状态胶囊徽章：统一各模块列表的状态展示（Capsule 形状 + 语义色）。
public struct StatusBadge: View {
    public let text: String
    public let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

/// 状态 → 语义色映射，供容器 / 应用 / 网站 / 计划任务等模块共用。
public enum StatusPalette {
    public static func containerState(_ state: String) -> Color {
        switch state.lowercased() {
        case "running": return .green
        case "exited", "stopped", "dead": return .red
        case "paused": return .orange
        case "created", "restarting": return .blue
        default: return .gray
        }
    }

    public static func appStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "running", "installed", "active": return .green
        case "error", "failed": return .red
        case "stopped", "uninstalled": return .gray
        default: return .gray
        }
    }

    public static func websiteStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "running", "active": return .green
        case "stopped": return .red
        default: return .gray
        }
    }

    /// 计划任务与任务日志状态：成功绿、失败红、执行中橙。
    public static func cronjobStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "success", "succeeded": return .green
        case "failed", "error": return .red
        case "running", "executing", "pending": return .orange
        default: return .gray
        }
    }
}
