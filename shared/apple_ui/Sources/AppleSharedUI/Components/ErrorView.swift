import SwiftUI

/// 首屏加载失败占位：说明文字 + 重试按钮。
///
/// iOS 17 与 macOS 14 起使用系统的 ContentUnavailableView，
/// 更早的系统版本使用居中的图标 / 文案 / 按钮纵向布局，
/// 两者共用同一插槽与文案来源。
public struct ErrorView: View {
    public let message: String
    public let onRetry: () -> Void

    @Environment(\.translationsProvider) private var translations

    public init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
    }

    public var body: some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, *) {
                ContentUnavailableView {
                    Label(message, systemImage: "exclamationmark.triangle")
                } actions: {
                    retryButton
                }
            } else {
                legacyBody
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var legacyBody: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            retryButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var retryButton: some View {
        Button(translations?.get("commonRetry", fallback: "Retry") ?? "Retry", action: onRetry)
            .prominentActionButton()
    }
}
