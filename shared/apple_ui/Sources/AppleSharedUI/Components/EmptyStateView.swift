import SwiftUI

/// 空态占位：图标 + 标题 + 可选描述与可选操作。
///
/// iOS 17 与 macOS 14 起使用系统的 ContentUnavailableView，
/// 更早的系统版本使用同一份纵向布局。
public struct EmptyStateView<Actions: View>: View {
    public let icon: String
    public let message: String
    public let description: String?
    private let actions: Actions

    public init(
        icon: String,
        message: String,
        description: String? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.icon = icon
        self.message = message
        self.description = description
        self.actions = actions()
    }

    public var body: some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, *) {
                if let description {
                    ContentUnavailableView {
                        Label(message, systemImage: icon)
                    } description: {
                        Text(description)
                    } actions: {
                        actions
                    }
                } else {
                    ContentUnavailableView {
                        Label(message, systemImage: icon)
                    } actions: {
                        actions
                    }
                }
            } else {
                legacyBody
            }
        }
    }

    private var legacyBody: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            actions
        }
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension EmptyStateView where Actions == EmptyView {
    /// 不带操作的空态。
    public init(icon: String, message: String, description: String? = nil) {
        self.init(icon: icon, message: message, description: description) {
            EmptyView()
        }
    }
}
