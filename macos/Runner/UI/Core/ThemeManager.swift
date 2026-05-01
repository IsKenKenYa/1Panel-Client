import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var isDarkMode: Bool = false
    @Published var primaryColor: Color = .blue
    @Published var backgroundColor: Color = Color(NSColor.windowBackgroundColor)
    @Published var surfaceColor: Color = Color(NSColor.controlBackgroundColor)
    
    // Material Design 3 spacing and radiuses
    let cardCornerRadius: CGFloat = 16.0
    let buttonCornerRadius: CGFloat = 20.0
    
    private init() {
        // Listen for system appearance changes if needed
        // Future: Load from Dart via ChannelManager
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
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
