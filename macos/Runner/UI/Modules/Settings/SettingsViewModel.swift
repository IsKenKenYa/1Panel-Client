import Foundation
import AppKit
import FlutterMacOS

enum MacOSRenderMode: String {
    static let preferenceKey = "flutter.app_ui_render_mode"

    case native
    case md3
    case liquidGlass

    static var stored: Self {
        Self(storedValue: UserDefaults.standard.string(forKey: preferenceKey))
    }

    init(storedValue: String?) {
        self = storedValue.flatMap(Self.init(rawValue:)) ?? .native
    }

    var usesNativeShell: Bool {
        self == .native
    }
}

class SettingsViewModel: ObservableObject {
    // ── 通用 ──────────────────────────────────────────────────────────────────
    @Published private(set) var renderMode: MacOSRenderMode
    @Published var selectedLanguage: String = "system"   // "system" | "zh" | "en"
    @Published var selectedTheme: String = "system"      // "system" | "light" | "dark"

    // ── 缓存 ──────────────────────────────────────────────────────────────────
    @Published var isClearingCache: Bool = false
    @Published private(set) var cacheCleared = false
    @Published private(set) var cacheClearError: String?

    // ── 应用信息 ──────────────────────────────────────────────────────────────
    let appVersion: String
    let buildNumber: String
    private let initialRenderMode: MacOSRenderMode
    private var initialLanguage: String

    var showRenderModeRestartHint: Bool {
        renderMode != initialRenderMode
    }

    var showLanguageRestartHint: Bool {
        selectedLanguage != initialLanguage
    }

    init() {
        let mode = MacOSRenderMode.stored
        self.renderMode = mode
        self.initialRenderMode = mode
        let language = UserDefaults.standard.string(forKey: "flutter.app_locale") ?? "system"
        let selectedLanguage = language.isEmpty ? "system" : language
        self.selectedLanguage = selectedLanguage
        self.initialLanguage = selectedLanguage
        self.selectedTheme = UserDefaults.standard.string(forKey: "flutter.app_theme_mode") ?? "system"

        let info = Bundle.main.infoDictionary
        self.appVersion = info?["CFBundleShortVersionString"] as? String ?? "--"
        self.buildNumber = info?["CFBundleVersion"] as? String ?? "--"
    }

    // ── 通用操作 ──────────────────────────────────────────────────────────────

    func updateRenderMode(_ mode: MacOSRenderMode) {
        renderMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: MacOSRenderMode.preferenceKey)
    }

    func updateLanguage(_ lang: String) {
        selectedLanguage = lang
        UserDefaults.standard.set(lang, forKey: "flutter.app_locale")
        // Dart 侧写入同一偏好键并重载原生文案，切换语言无需重启应用。
        ChannelManager.shared.invokeDataMethod(
            "updateSetting",
            arguments: ["key": "language", "value": lang]
        ) { result in
            let succeeded = (result as? [String: Any])?["success"] as? Bool ?? false
            DispatchQueue.main.async {
                if succeeded {
                    TranslationsManager.shared.load {}
                    self.initialLanguage = lang
                }
            }
        }
    }

    func updateTheme(_ theme: String) {
        selectedTheme = theme
        UserDefaults.standard.set(theme, forKey: "flutter.app_theme_mode")
        Self.applyTheme(theme)
    }

    static func applyTheme(_ theme: String?) {
        switch theme {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":  NSApp.appearance = NSAppearance(named: .darkAqua)
        default:      NSApp.appearance = nil
        }
    }

    // ── 缓存操作 ──────────────────────────────────────────────────────────────

    func clearCache() {
        guard !isClearingCache else { return }
        isClearingCache = true
        cacheCleared = false
        cacheClearError = nil
        ChannelManager.shared.invokeDataMethod("clearCache") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isClearingCache = false
                let response = result as? [String: Any]
                if response?["success"] as? Bool == true {
                    self.cacheCleared = true
                } else {
                    self.cacheClearError = response?["error"] as? String
                        ?? (result as? FlutterError)?.message
                        ?? TranslationsManager.shared.get("commonOperationFailed", fallback: "Operation failed")
                }
            }
        }
    }

    // ── 应用操作 ──────────────────────────────────────────────────────────────

    func openGitHub() {
        if let url = URL(string: "https://github.com/IsKenKenYa/1Panel-Client") {
            NSWorkspace.shared.open(url)
        }
    }

    func openIssues() {
        if let url = URL(string: "https://github.com/IsKenKenYa/1Panel-Client/issues") {
            NSWorkspace.shared.open(url)
        }
    }

    func openWebsite() {
        if let url = URL(string: "https://1panel.cn") {
            NSWorkspace.shared.open(url)
        }
    }
}
