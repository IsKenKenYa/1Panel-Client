import SwiftUI

/// 设置页：外观、语言、渲染模式、缓存与应用信息。
struct SettingsView: View {
    @Binding var path: NavigationPath
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    @State private var launchHookApplied = false

    var body: some View {
        Form {
            Section {
                Picker(translations.get("settingsUIRenderMode", fallback: "UI Render Mode"),
                       selection: Binding(
                        get: { viewModel.renderMode },
                        set: { viewModel.updateRenderMode($0) }
                       )) {
                    Text(translations.get("settingsUIRenderModeNative", fallback: "Native")).tag("native")
                    Text(translations.get("settingsUIRenderModeMD3", fallback: "MDUI3")).tag("md3")
                }
                if viewModel.showRestartHint {
                    Text(translations.get("settingsUIRenderModeRestartHint",
                                          fallback: "Please restart the app for the UI render mode changes to take effect."))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text(translations.get("settingsGeneral", fallback: "General"))
            }

            Section {
                Picker(translations.get("settingsTheme", fallback: "Theme"),
                       selection: Binding(
                        get: { viewModel.selectedTheme },
                        set: { viewModel.updateTheme($0) }
                       )) {
                    Text(translations.get("themeSystem", fallback: "System")).tag("system")
                    Text(translations.get("themeLight", fallback: "Light")).tag("light")
                    Text(translations.get("themeDark", fallback: "Dark")).tag("dark")
                }
            } header: {
                Text(translations.get("settingsTheme", fallback: "Theme"))
            } footer: {
                Text(translations.get("settingsThemeSubtitle", fallback: "Light, dark, or follow the system."))
            }

            Section {
                Picker(translations.get("settingsLanguage", fallback: "Language"),
                       selection: Binding(
                        get: { viewModel.selectedLanguage },
                        set: { viewModel.updateLanguage($0) }
                       )) {
                    Text(translations.get("languageSystem", fallback: "System")).tag("system")
                    Text(translations.get("languageZh", fallback: "Chinese")).tag("zh")
                    Text(translations.get("languageEn", fallback: "English")).tag("en")
                }
            } header: {
                Text(translations.get("settingsLanguage", fallback: "Language"))
            } footer: {
                Text(translations.get("settingsLanguageHint",
                                      fallback: "Language changes take effect immediately; unset follows the system."))
            }

            Section(translations.get("settingsStorage", fallback: "Storage")) {
                HStack {
                    Text(translations.get("settingsCacheTitle", fallback: "Cache"))
                    Spacer()
                    if viewModel.isClearingCache {
                        ProgressView()
                    } else {
                        Button(translations.get("settingsCacheClear", fallback: "Clear Cache")) {
                            viewModel.clearCache()
                        }
                        .foregroundStyle(.red)
                    }
                }
                if let msg = viewModel.cacheClearMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(msg.hasPrefix("✓") ? Color.green : Color.red)
                }
            }

            Section(translations.get("settingsAbout", fallback: "About")) {
                HStack {
                    Text(translations.get("appInfoVersion", fallback: "Version"))
                    Spacer()
                    Text("v\(viewModel.appVersion)")
                        .foregroundStyle(.secondary)
                }
                NavigationLink(value: SettingsPageRoute.about) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(translations.get("aboutPageTitle", fallback: "About 1Panel Client"))
                        Text(translations.get("settingsAboutSubtitle",
                                              fallback: "Version, project info and official links"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                NavigationLink(value: SettingsPageRoute.legal) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(translations.get("settingsLegalCenterTitle", fallback: "Legal"))
                        Text(translations.get("settingsLegalCenterSubtitle",
                                              fallback: "Privacy, terms and open source licenses"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Button {
                    viewModel.openIssues()
                } label: {
                    HStack {
                        Text(translations.get("settingsFeedback", fallback: "Feedback"))
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(translations.get("navSettings", fallback: "Settings"))
        .onAppear {
            applyLaunchHook()
        }
    }

    /// 走查钩子：`ONEPANEL_OPEN_SETTINGS_PAGE=about|legal` 直接进入子页。
    private func applyLaunchHook() {
        guard !launchHookApplied else { return }
        guard let raw = ProcessInfo.processInfo.environment["ONEPANEL_OPEN_SETTINGS_PAGE"],
              let route = SettingsPageRoute(rawValue: raw) else { return }
        launchHookApplied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            path.append(route)
        }
    }
}
