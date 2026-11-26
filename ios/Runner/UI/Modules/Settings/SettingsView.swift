import SwiftUI

/// 设置页：外观、语言、渲染模式、缓存与应用信息。
struct SettingsView: View {
    @Binding var path: NavigationPath
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var translations: TranslationsManager
    @State private var launchHookApplied = false

    var body: some View {
        Form {
            Section {
                Picker(selection: Binding(
                        get: { viewModel.renderMode },
                        set: { viewModel.updateRenderMode($0) }
                       )) {
                    if #available(iOS 26.0, *) {
                        Text(translations.get("settingsUIRenderModeAppleGlass",
                                              fallback: "Apple UI with Liquid Glass")).tag(UIRenderMode.native)
                    } else {
                        Text(translations.get("settingsUIRenderModeNative", fallback: "Native")).tag(UIRenderMode.native)
                    }
                    Text(translations.get("settingsUIRenderModeMD3", fallback: "MDUI3")).tag(UIRenderMode.md3)
                    Text(translations.get("settingsUIRenderModeLiquidGlass",
                                          fallback: "MDUI3 with Liquid Glass")).tag(UIRenderMode.liquidGlass)
                } label: {
                    Label(translations.get("settingsUIRenderMode", fallback: "UI Render Mode"),
                          systemImage: "rectangle.3.group")
                }
                .accessibilityIdentifier("settings-render-mode")

                Picker(selection: Binding(
                        get: { viewModel.selectedTheme },
                        set: { viewModel.updateTheme($0) }
                       )) {
                    Text(translations.get("themeSystem", fallback: "System")).tag("system")
                    Text(translations.get("themeLight", fallback: "Light")).tag("light")
                    Text(translations.get("themeDark", fallback: "Dark")).tag("dark")
                } label: {
                    Label(translations.get("settingsTheme", fallback: "Theme"), systemImage: "circle.lefthalf.filled")
                }
            } header: {
                Text(translations.get("settingsAppearance", fallback: "Appearance"))
            } footer: {
                if viewModel.showRestartHint {
                    Text(translations.get("settingsUIRenderModeRestartHint",
                                          fallback: "Restart the app to apply the selected interface."))
                } else if #available(iOS 26.0, *) {
                    Text(translations.get("settingsUIRenderModeAppleGlassDesc",
                                          fallback: "Apple UI uses system Liquid Glass on navigation and controls."))
                }
            }

            Section {
                Picker(selection: Binding(
                        get: { viewModel.selectedLanguage },
                        set: { viewModel.updateLanguage($0) }
                       )) {
                    Text(translations.get("languageSystem", fallback: "System")).tag("system")
                    Text(translations.get("languageZh", fallback: "Chinese")).tag("zh")
                    Text(translations.get("languageEn", fallback: "English")).tag("en")
                } label: {
                    Label(translations.get("settingsLanguage", fallback: "Language"), systemImage: "globe")
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
                    Label {
                        Text(msg)
                    } icon: {
                        Image(systemName: viewModel.cacheClearSucceeded
                              ? "checkmark.circle"
                              : "exclamationmark.circle")
                    }
                    .font(.footnote)
                    .foregroundStyle(viewModel.cacheClearSucceeded ? Color.secondary : Color.red)
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
                        Text(translations.get("aboutPageTitle", fallback: "About KenPanel"))
                        Text(translations.get("settingsAboutSubtitle",
                                              fallback: "Version, project info and official links"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                NavigationLink(value: SettingsPageRoute.legal) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(translations.get("settingsLegalCenterTitle", fallback: "Legal"))
                        Text(translations.get("settingsLegalCenterSubtitle",
                                              fallback: "Privacy, terms and open source licenses"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
