import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var appLock: MacOSAppLockController
    @EnvironmentObject var translations: TranslationsManager
    let onOpenServers: () -> Void

    @State private var showCacheClearConfirm = false
    @State private var showAbout = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                settingsContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: 680, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .navigationTitle(translations.get("navSettings", fallback: "Settings"))
        .sheet(isPresented: $showAbout) {
            SettingsAboutSheet(viewModel: viewModel, translations: translations)
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        // ── 通用 ────────────────────────────────────────────────────────────
        sectionHeader(translations.get("settingsGeneral", fallback: "General"))

        settingsCard {
            // 主题
            settingsRow(
                icon: "paintpalette",
                iconColor: .purple,
                title: translations.get("settingsTheme", fallback: "Theme")
            ) {
                Picker(translations.get("settingsTheme", fallback: "Theme"), selection: Binding(
                    get: { viewModel.selectedTheme },
                    set: { viewModel.updateTheme($0) }
                )) {
                    Text(translations.get("themeSystem", fallback: "System")).tag("system")
                    Text(translations.get("themeLight", fallback: "Light")).tag("light")
                    Text(translations.get("themeDark", fallback: "Dark")).tag("dark")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Divider().padding(.leading, 44)

            // 语言
            settingsRow(
                icon: "globe",
                iconColor: .blue,
                title: translations.get("settingsLanguage", fallback: "Language")
            ) {
                Picker(translations.get("settingsLanguage", fallback: "Language"), selection: Binding(
                    get: { viewModel.selectedLanguage },
                    set: { viewModel.updateLanguage($0) }
                )) {
                    Text(translations.get("languageSystem", fallback: "System")).tag("system")
                    Text(translations.get("languageZh", fallback: "Chinese")).tag("zh")
                    Text(translations.get("languageEn", fallback: "English")).tag("en")
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if viewModel.showLanguageRestartHint {
                Text(translations.get("settingsLanguageRestartHint",
                                      fallback: "Restart the app to apply the language change."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 44)
                    .padding(.bottom, 8)
            }

            Divider().padding(.leading, 44)

            settingsRow(
                icon: "lock.fill",
                iconColor: .red,
                title: translations.get("settingsAppLock", fallback: "App Lock"),
                subtitle: translations.get("appLockEnableDesc",
                                           fallback: "Prompt for local authentication before opening protected content")
            ) {
                Toggle(translations.get("settingsAppLock", fallback: "App Lock"), isOn: Binding(
                    get: { appLock.isEnabled },
                    set: { appLock.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .disabled(appLock.isAuthenticating)
            }

            if let error = appLock.errorMessage {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 44)
                    .padding(.bottom, 8)
            }
        }

        sectionHeader(translations.get("settingsUIRenderMode", fallback: "UI Render Mode"))

        settingsCard {
            VStack(alignment: .leading, spacing: 8) {
                Picker(translations.get("settingsUIRenderMode", fallback: "UI Render Mode"), selection: Binding(
                    get: { viewModel.renderMode },
                    set: { viewModel.updateRenderMode($0) }
                )) {
                    if #available(macOS 26, *) {
                        Text(translations.get("settingsUIRenderModeAppleGlass", fallback: "Apple UI with Liquid Glass"))
                            .tag(MacOSRenderMode.native)
                    } else {
                        Text(translations.get("settingsUIRenderModeNative", fallback: "Native"))
                            .tag(MacOSRenderMode.native)
                    }
                    Text(translations.get("settingsUIRenderModeMD3", fallback: "MDUI3"))
                        .tag(MacOSRenderMode.md3)
                    Text(translations.get("settingsUIRenderModeLiquidGlass", fallback: "MDUI3 with Liquid Glass"))
                        .tag(MacOSRenderMode.liquidGlass)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accessibilityIdentifier("macos.settings.renderMode")

                if #available(macOS 26, *), viewModel.renderMode == .native {
                    Text(translations.get("settingsUIRenderModeAppleGlassDesc",
                                          fallback: "Uses the system Liquid Glass material in navigation and controls."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if viewModel.showRenderModeRestartHint {
                    Text(translations.get("settingsUIRenderModeRestartHint",
                                          fallback: "Restart the app to apply the UI render mode change."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }

        // ── 存储 ────────────────────────────────────────────────────────────
        sectionHeader(translations.get("settingsStorage", fallback: "Storage"))

        settingsCard {
            VStack(alignment: .leading, spacing: 8) {
                settingsRow(
                    icon: "internaldrive",
                    iconColor: .teal,
                    title: translations.get("settingsCacheTitle", fallback: "Cache Settings")
                ) {
                    if viewModel.isClearingCache {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Button(translations.get("settingsCacheClear", fallback: "Clear Cache")) {
                            showCacheClearConfirm = true
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.red)
                    }
                }

                if viewModel.cacheCleared {
                    Label(translations.get("settingsCacheCleared", fallback: "Cache cleared"), systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 44)
                } else if let error = viewModel.cacheClearError {
                    Label(error, systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.leading, 44)
                }
            }
        }
        .confirmationDialog(
            translations.get("settingsCacheClearConfirm", fallback: "Clear Cache?"),
            isPresented: $showCacheClearConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("settingsCacheClear", fallback: "Clear"), role: .destructive) {
                viewModel.clearCache()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("settingsCacheClearConfirmMessage",
                                  fallback: "This will remove all memory and disk caches."))
        }

        // ── 支持与反馈 ──────────────────────────────────────────────────────
        sectionHeader(translations.get("settingsSupport", fallback: "Support & Feedback"))

        settingsCard {
            // 反馈中心 (GitHub Issues)
            settingsNavRow(
                icon: "bubble.left.and.bubble.right",
                iconColor: .indigo,
                title: translations.get("settingsFeedbackCenterTitle", fallback: "Feedback Center"),
                subtitle: translations.get("settingsFeedbackCenterSubtitle",
                                           fallback: "Log management and issue reporting")
            ) {
                viewModel.openIssues()
            }

            Divider().padding(.leading, 44)

            // 法律文件
            settingsNavRow(
                icon: "doc.text",
                iconColor: .gray,
                title: translations.get("settingsLegalCenterTitle", fallback: "Legal"),
                subtitle: translations.get("settingsLegalCenterSubtitle",
                                           fallback: "Privacy, terms and open-source licenses")
            ) {
                if let url = URL(string: "https://1panel.cn") {
                    NSWorkspace.shared.open(url)
                }
            }

            Divider().padding(.leading, 44)

            // 关于
            Button(action: { showAbout = true }) {
                settingsRowContent(
                    icon: "info.circle",
                    iconColor: .blue,
                    title: translations.get("settingsAbout", fallback: "About"),
                    subtitle: "KenPanel v\(viewModel.appVersion)",
                    trailingView: AnyView(
                        Image(systemName: "chevron.right").foregroundColor(.secondary).font(.caption)
                    )
                )
            }
            .buttonStyle(.plain)
        }

        // ── 应用 ────────────────────────────────────────────────────────────
        sectionHeader(translations.get("settingsAppSectionTitle", fallback: "App"))

        settingsCard {
            settingsNavRow(
                icon: "server.rack",
                iconColor: .green,
                title: translations.get("settingsServerManagement", fallback: "Server Management"),
                subtitle: translations.get("settingsServerManagementSubtitle",
                                           fallback: "Manage connected servers"),
                indicator: "chevron.right",
                action: onOpenServers
            )

            Divider().padding(.leading, 44)

            // GitHub
            settingsNavRow(
                icon: "chevron.left.forwardslash.chevron.right",
                iconColor: .primary,
                title: "GitHub",
                subtitle: "1Panel-dev/1Panel-Client"
            ) {
                viewModel.openGitHub()
            }
        }

        Spacer(minLength: 32)
    }

    // ── 子组件辅助 ─────────────────────────────────────────────────────────────

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundColor(.secondary)
            .accessibilityAddTraits(.isHeader)
            .padding(.top, 16)
            .padding(.bottom, 6)
            .padding(.leading, 4)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }

    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let sub = subtitle {
                    Text(sub).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    private func settingsNavRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        indicator: String = "arrow.up.right.square",
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            settingsRowContent(
                icon: icon,
                iconColor: iconColor,
                title: title,
                subtitle: subtitle,
                trailingView: AnyView(
                    Image(systemName: indicator)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .accessibilityHidden(true)
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func settingsRowContent(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        trailingView: AnyView
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(iconColor)
                .frame(width: 18)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                if let sub = subtitle {
                    Text(sub).font(.caption).foregroundColor(.secondary)
                }
            }

            Spacer()
            trailingView
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// ── 关于 Sheet ──────────────────────────────────────────────────────────────

struct SettingsAboutSheet: View {
    let viewModel: SettingsViewModel
    let translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .padding()
            }

            ScrollView {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 10) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("KenPanel")
                            .font(.title.bold())
                        Text("v\(viewModel.appVersion) (\(viewModel.buildNumber))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // 版本信息
                    aboutCard {
                        aboutRow(label: translations.get("settingsAbout", fallback: "Version"),
                                 value: viewModel.appVersion)
                        Divider()
                        aboutRow(label: "Build", value: viewModel.buildNumber)
                        Divider()
                        aboutRow(label: "Website", value: "1panel.cn")
                    }

                    // 项目链接
                    aboutCard {
                        Button(action: { viewModel.openGitHub() }) {
                            HStack {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                Text("GitHub Repository")
                                Spacer()
                                Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: { viewModel.openIssues() }) {
                            HStack {
                                Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                Text(translations.get("settingsFeedbackCenterTitle", fallback: "Submit Issue"))
                                Spacer()
                                Image(systemName: "arrow.up.right.square").foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("KenPanel is open source under GPL-3.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .frame(width: 420, height: 480)
    }

    private func aboutCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.horizontal, 14)
        .background(
            Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }

    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).foregroundColor(.primary)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
    }
}
