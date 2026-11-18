import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var isDarkMode: Bool = false
    @Published var primaryColor: Color = .blue
    @Published var backgroundColor: Color = Color(UIColor.systemBackground)
    @Published var surfaceColor: Color = Color(UIColor.secondarySystemBackground)
    /// 外观偏好：system / light / dark，与 MDUI3 设置页共用同一个键。
    @Published var appearance: String

    let cardCornerRadius: CGFloat = 16.0
    let buttonCornerRadius: CGFloat = 20.0

    private init() {
        appearance = UserDefaults.standard.string(forKey: "flutter.app_theme_mode") ?? "system"
    }

    var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    func setAppearance(_ value: String) {
        appearance = value
        UserDefaults.standard.set(value, forKey: "flutter.app_theme_mode")
        UserDefaults.standard.synchronize()
        isDarkMode = value == "dark"
    }

    func updateTheme(from dict: [String: Any]) {
        if let dark = dict["isDarkMode"] as? Bool {
            self.isDarkMode = dark
        }
        if let primaryHex = dict["primaryColor"] as? String {
            self.primaryColor = Color(hex: primaryHex)
        }
        if let bgHex = dict["backgroundColor"] as? String {
            self.backgroundColor = Color(hex: bgHex)
        }
        if let surfaceHex = dict["surfaceColor"] as? String {
            self.surfaceColor = Color(hex: surfaceHex)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
