import SwiftUI

/// 空态占位：图标 + 标题 + 可选描述。
/// iOS 17 起用系统的 ContentUnavailableView；macOS 13.5 部署目标下
/// 使用相同的 图标 / 文案 纵向布局。
public struct EmptyStateView: View {
    public let icon: String
    public let message: String
    public let description: String?

    public init(icon: String, message: String, description: String? = nil) {
        self.icon = icon
        self.message = message
        self.description = description
    }

    public var body: some View {
        #if os(iOS)
        Group {
            if #available(iOS 17.0, *) {
                if let description {
                    ContentUnavailableView {
                        Label(message, systemImage: icon)
                    } description: {
                        Text(description)
                    }
                } else {
                    ContentUnavailableView(message, systemImage: icon)
                }
            } else {
                legacyBody
            }
        }
        #else
        legacyBody
        #endif
    }

    private var legacyBody: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
