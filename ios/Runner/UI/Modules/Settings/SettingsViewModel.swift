import Foundation
import UIKit

enum UIRenderMode: String {
    case native
    case md3
    case liquidGlass

    static let preferenceKey = "flutter.app_ui_render_mode"

    static var stored: Self {
        let defaults = UserDefaults.standard
        return resolve(defaults.string(forKey: preferenceKey),
                       appLockEnabled: defaults.bool(forKey: SecurityViewModel.appLockDefaultsKey))
    }

    static func resolve(_ storedValue: String?, appLockEnabled: Bool) -> Self {
        if let storedValue, let mode = Self(rawValue: storedValue) {
            return mode
        }
        return appLockEnabled ? .liquidGlass : .native
    }
}

class SettingsViewModel: ObservableObject {
    private static let localePreferenceKey = "flutter.app_locale"

    @Published private(set) var renderMode: UIRenderMode
    @Published var selectedLanguage: String = "system"
    @Published var selectedTheme: String = "system"
    @Published var appLockEnabled: Bool = false
    @Published var isClearingCache: Bool = false
    @Published var cacheClearMessage: String?

    let appVersion: String
    let buildNumber: String
    private let initialRenderMode: UIRenderMode

    var showRestartHint: Bool { renderMode != initialRenderMode }

    init() {
        let mode = UIRenderMode.stored
        self.renderMode = mode
        self.initialRenderMode = mode
        let locale = UserDefaults.standard.string(forKey: Self.localePreferenceKey)
        self.selectedLanguage = locale.flatMap { $0.isEmpty ? nil : $0 } ?? "system"
        self.selectedTheme = UserDefaults.standard.string(forKey: "flutter.app_theme_mode") ?? "system"
        self.appLockEnabled = UserDefaults.standard.bool(forKey: "flutter.app_lock_enabled")

        let info = Bundle.main.infoDictionary
        self.appVersion = info?["CFBundleShortVersionString"] as? String ?? "--"
        self.buildNumber = info?["CFBundleVersion"] as? String ?? "--"
    }

    func updateRenderMode(_ mode: UIRenderMode) {
        guard renderMode != mode else { return }
        renderMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: UIRenderMode.preferenceKey)
    }

    func updateLanguage(_ lang: String) {
        selectedLanguage = lang
        if lang == "system" {
            UserDefaults.standard.removeObject(forKey: Self.localePreferenceKey)
        } else {
            UserDefaults.standard.set(lang, forKey: Self.localePreferenceKey)
        }
        UserDefaults.standard.synchronize()
        // 语言切换立即生效：Dart 侧读取该键后重新下发翻译字典。
        TranslationsManager.shared.load { }
    }

    func updateTheme(_ theme: String) {
        selectedTheme = theme
        ThemeManager.shared.setAppearance(theme)
    }

    func toggleAppLock(_ enabled: Bool) {
        appLockEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "flutter.app_lock_enabled")
        UserDefaults.standard.synchronize()
    }

    func clearCache() {
        guard !isClearingCache else { return }
        isClearingCache = true
        cacheClearMessage = nil
        ChannelManager.shared.invokeDataMethod("clearCache") { [weak self] result in
            DispatchQueue.main.async {
                self?.isClearingCache = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.cacheClearMessage = dict["error"] as? String ?? "Failed to clear cache"
                } else {
                    self?.cacheClearMessage = "✓ Cache cleared"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.cacheClearMessage = nil
                }
            }
        }
    }

    func openIssues() {
        if let url = URL(string: "https://github.com/1Panel-dev/1Panel-Client/issues") {
            UIApplication.shared.open(url)
        }
    }
}
