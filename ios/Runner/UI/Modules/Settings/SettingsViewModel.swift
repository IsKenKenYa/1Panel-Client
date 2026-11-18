import Foundation
import UIKit

class SettingsViewModel: ObservableObject {
    @Published var renderMode: String
    @Published var showRestartHint: Bool = false
    @Published var selectedLanguage: String = "system"
    @Published var selectedTheme: String = "system"
    @Published var appLockEnabled: Bool = false
    @Published var isClearingCache: Bool = false
    @Published var cacheClearMessage: String?

    let appVersion: String
    let buildNumber: String

    init() {
        self.renderMode = UserDefaults.standard.string(forKey: "flutter.app_ui_render_mode") ?? "native"
        self.selectedLanguage = UserDefaults.standard.string(forKey: "flutter.app_locale") ?? "system"
        self.selectedTheme = UserDefaults.standard.string(forKey: "flutter.app_theme_mode") ?? "system"
        self.appLockEnabled = UserDefaults.standard.bool(forKey: "flutter.app_lock_enabled")

        let info = Bundle.main.infoDictionary
        self.appVersion = info?["CFBundleShortVersionString"] as? String ?? "--"
        self.buildNumber = info?["CFBundleVersion"] as? String ?? "--"
    }

    func updateRenderMode(_ mode: String) {
        renderMode = mode
        UserDefaults.standard.set(mode, forKey: "flutter.app_ui_render_mode")
        UserDefaults.standard.synchronize()
        showRestartHint = true
    }

    func updateLanguage(_ lang: String) {
        selectedLanguage = lang
        let value = lang == "system" ? "" : lang
        UserDefaults.standard.set(value, forKey: "flutter.app_locale")
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
