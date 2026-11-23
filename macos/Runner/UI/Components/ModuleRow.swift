import SwiftUI

/// 列表行尾的可见操作按钮。
///
/// macOS 上把操作只放进 `.contextMenu` 时，`Table` 单元格内的右键菜单
/// 经常不弹出，用户也看不出行能做什么。运维列表每行字段少、动作明确，
/// 按 HIG 用列表行表达，并把动作直接渲染成可见按钮。
struct RowActionButton: View {
    private let title: String
    private let systemImage: String
    private let destructive: Bool
    private let action: () -> Void

    @State private var isHovered = false

    init(
        title: String,
        systemImage: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.destructive = destructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovered ? Color.secondary.opacity(0.16) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(destructive ? Color.red : Color.secondary)
        .help(title)
        .onHover { isHovered = $0 }
    }
}

/// 列表右侧的操作按钮组，统一间距与禁用态。
struct RowActions<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 4) { content }
    }
}

/// 列表行通用骨架：左侧图标、两行文本与右侧操作。
///
/// 与 iOS 设置、Finder 的列表节奏一致：一行一个对象，标题行突出，
/// 次要信息用 `.secondary`，操作靠右对齐。
struct ModuleRow<Trailing: View>: View {
    private let icon: String
    private let iconColor: Color
    private let title: String
    private let subtitle: String
    private let badge: (text: String, color: Color)?
    private let trailing: Trailing
    private let onOpen: (() -> Void)?

    init(
        icon: String,
        iconColor: Color = .secondary,
        title: String,
        subtitle: String,
        badge: (text: String, color: Color)? = nil,
        onOpen: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.badge = badge
        self.onOpen = onOpen
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                    if let badge {
                        Text(badge.text)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.14), in: Capsule())
                            .foregroundStyle(badge.color)
                    }
                }
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            Spacer(minLength: 12)
            trailing
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .modifier(DoubleClickOpen(handler: onOpen))
    }
}

private struct DoubleClickOpen: ViewModifier {
    let handler: (() -> Void)?

    func body(content: Content) -> some View {
        if let handler {
            content.onTapGesture(count: 2, perform: handler)
        } else {
            content
        }
    }
}