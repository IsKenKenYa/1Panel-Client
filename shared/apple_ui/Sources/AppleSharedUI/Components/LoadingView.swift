import SwiftUI

/// 加载态占位：整块区域居中显示进度环。
public struct LoadingView: View {
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
