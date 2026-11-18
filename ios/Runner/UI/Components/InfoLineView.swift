import SwiftUI

/// 标签 + 值的信息行，服务器首页与各详情页共用。
struct InfoLine: View {
    let label: String
    let value: String

    var body: some View {
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