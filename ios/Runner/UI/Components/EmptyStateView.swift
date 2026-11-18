import SwiftUI

/// 空态视图：图标 + 标题 + 可选描述，iOS 17 起使用系统的 ContentUnavailableView。
struct EmptyStateView: View {
    let icon: String
    let message: String
    var description: String? = nil

    var body: some View {
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
                VStack(spacing: 8) {
                    Label(message, systemImage: icon)
                        .font(.headline)
                    if let description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .multilineTextAlignment(.center)
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
