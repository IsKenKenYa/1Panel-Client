import SwiftUI

/// 首屏加载失败占位：说明文字 + 重试按钮。
/// iOS 用系统的 ContentUnavailableView，macOS 用居中的
/// 图标 / 文案 / 按钮纵向布局，两者共用同一插槽与文案来源。
public struct ErrorView: View {
    public let message: String
    public let onRetry: () -> Void

    @Environment(\.translationsProvider) private var translations

    public init(message: String, onRetry: @escaping () -> Void) {
        self.message = message
        self.onRetry = onRetry
    }

    public var body: some View {
        #if os(iOS)
        Group {
            if #available(iOS 17.0, *) {
                ContentUnavailableView {
                    Label(message, systemImage: "exclamationmark.triangle")
                } actions: {
                    retryButton
                }
            } else {
                VStack(spacing: 16) {
                    Label(message, systemImage: "exclamationmark.triangle")
                        .multilineTextAlignment(.center)
                    retryButton
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #else
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            retryButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        #endif
    }

    private var retryButton: some View {
        Button(translations?.get("commonRetry", fallback: "Retry") ?? "Retry", action: onRetry)
            .buttonStyle(.borderedProminent)
    }
}
