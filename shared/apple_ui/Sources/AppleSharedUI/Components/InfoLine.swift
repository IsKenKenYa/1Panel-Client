import SwiftUI

/// 标签 + 值的信息行，服务器首页与各详情页共用。
public struct InfoLine: View {
    public let label: String
    public let value: String

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    public var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "--" : value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
