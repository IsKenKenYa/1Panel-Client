import SwiftUI

/// 状态胶囊徽章：统一各模块列表的状态展示（HIG 推荐 Capsule 形状 + 语义色）。
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

/// 状态 → 系统语义色映射，供容器 / 应用 / 网站等模块共用。
enum StatusPalette {
    static func containerState(_ state: String) -> Color {
        switch state.lowercased() {
        case "running": return .green
        case "exited", "stopped", "dead": return .red
        case "paused": return .orange
        case "created", "restarting": return .blue
        default: return .gray
        }
    }

    static func appStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "running", "installed", "active": return .green
        case "error", "failed": return .red
        case "stopped", "uninstalled": return .gray
        default: return .gray
        }
    }

    static func websiteStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "running", "active": return .green
        case "stopped": return .red
        default: return .gray
        }
    }
}
