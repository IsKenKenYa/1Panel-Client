import Foundation
import AppKit

class SettingsViewModel: ObservableObject {
    // ── 通用 ──────────────────────────────────────────────────────────────────
    @Published var renderMode: String
    @Published var showRestartHint: Bool = false
    @Published var selectedLanguage: String = "system"   // "system" | "zh" | "en"
    @Published var selectedTheme: String = "system"      // "system" | "light" | "dark"
    @Published var appLockEnabled: Bool = false

    // ── 缓存 ──────────────────────────────────────────────────────────────────
    @Published var isClearingCache: Bool = false
    @Published var cacheClearMessage: String?

    // ── 应用信息 ──────────────────────────────────────────────────────────────
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

    // ── 通用操作 ──────────────────────────────────────────────────────────────

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
        showRestartHint = true
    }

    func updateTheme(_ theme: String) {
        selectedTheme = theme
        UserDefaults.standard.set(theme, forKey: "flutter.app_theme_mode")
        UserDefaults.standard.synchronize()
        // Propagate appearance change immediately
        switch theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }
    }

    func toggleAppLock(_ enabled: Bool) {
        appLockEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "flutter.app_lock_enabled")
        UserDefaults.standard.synchronize()
    }

    // ── 缓存操作 ──────────────────────────────────────────────────────────────

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
                // Auto-dismiss message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.cacheClearMessage = nil
                }
            }
        }
    }

    // ── 应用操作 ──────────────────────────────────────────────────────────────

    func openGitHub() {
        if let url = URL(string: "https://github.com/1Panel-dev/1Panel-Client") {
            NSWorkspace.shared.open(url)
        }
    }

    func openIssues() {
        if let url = URL(string: "https://github.com/1Panel-dev/1Panel-Client/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    func openWebsite() {
        if let url = URL(string: "https://1panel.cn") {
            NSWorkspace.shared.open(url)
        }
    }
}
