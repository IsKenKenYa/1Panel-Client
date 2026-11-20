import SwiftUI

/// 应用图标：远程 logo 用 AsyncImage 加载，缺图或加载中显示占位方块。
/// 1Panel 的图标是 apps-assets.fit2cloud.com 上的 PNG 直链，
/// 该站点会拒绝空 User-Agent，AsyncImage 默认 UA 可以正常取图。
struct AppIconView: View {
    let url: String
    var size: CGFloat = 40
    var fallbackSymbol: String = "app.fill"
    var fallbackColor: Color = .blue

    var body: some View {
        Group {
            if let target = URL(string: url), !url.isEmpty {
                AsyncImage(url: target) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        placeholder
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }

    private var placeholder: some View {
        Image(systemName: fallbackSymbol)
            .font(.system(size: size * 0.5))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(fallbackColor, in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}
