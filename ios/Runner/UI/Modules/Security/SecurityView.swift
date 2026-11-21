import SwiftUI
import AppleSharedUI

/// 安全页：应用锁、SSH 服务状态与操作、面板 SSL 信息。
struct SecurityView: View {
    @StateObject private var viewModel = SecurityViewModel()
    @StateObject private var serverViewModel = SecurityServerViewModel()
    @EnvironmentObject var translations: TranslationsManager
    @State private var pendingSshOperation: String?

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.appLockEnabled },
                    set: { enabled in
                        if enabled {
                            viewModel.enableAppLock()
                        } else {
                            viewModel.disableAppLock()
                        }
                    }
                )) {
                    Label(translations.get("appLockEnable", fallback: "Enable App Lock"),
                          systemImage: "lock.shield")
                }
                .disabled(viewModel.isAuthenticating || !SecurityViewModel.deviceAuthSupported())
            } header: {
                Text(translations.get("appLockTitle", fallback: "App Lock"))
            } footer: {
                Text(translations.get("appLockEnableDesc", fallback: "Local authentication is required before opening protected content."))
            }

            if let error = viewModel.authErrorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            sshSection
            panelSslSection
        }
        .navigationTitle(translations.get("navSecurity", fallback: "Security"))
        .confirmationDialog(
            sshOperationConfirmTitle,
            isPresented: Binding(
                get: { pendingSshOperation != nil },
                set: { if !$0 { pendingSshOperation = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(sshOperationLabel(pendingSshOperation) ?? "") {
                performSshOperation()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingSshOperation = nil
            }
        }
        .onAppear {
            serverViewModel.fetch()
        }
    }

    @ViewBuilder
    private var sshSection: some View {
        Section {
            if let ssh = serverViewModel.ssh, ssh.isExist {
                InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                         value: ssh.isActive
                            ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                            : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                InfoLine(label: translations.get("sshPortLabel", fallback: "Port"),
                         value: ssh.port.isEmpty ? "--" : ssh.port)
                if !ssh.listenAddress.isEmpty {
                    InfoLine(label: translations.get("sshListenAddressLabel", fallback: "Listen Address"),
                             value: ssh.listenAddress)
                }
                HStack(spacing: 12) {
                    Button {
                        pendingSshOperation = "start"
                    } label: {
                        Label(translations.get("containerActionStart", fallback: "Start"),
                              systemImage: "play.fill")
                    }
                    .disabled(ssh.isActive)

                    Button {
                        pendingSshOperation = "restart"
                    } label: {
                        Label(translations.get("containerActionRestart", fallback: "Restart"),
                              systemImage: "arrow.clockwise")
                    }

                    Button {
                        pendingSshOperation = "stop"
                    } label: {
                        Label(translations.get("containerActionStop", fallback: "Stop"),
                              systemImage: "stop.fill")
                    }
                    .disabled(!ssh.isActive)
                }
                .buttonStyle(.borderless)

                NavigationLink {
                    SSHConfigView()
                        .environmentObject(translations)
                } label: {
                    Label(translations.get("hostHostSshConfigFileTitle",
                                           fallback: "Config File (/etc/ssh/sshd_config)"),
                          systemImage: "doc.text")
                }
            } else if serverViewModel.isLoading {
                ProgressView()
            } else if serverViewModel.sshLoadFailed {
                HStack {
                    Text(translations.get("commonLoadFailedTitle", fallback: "Failed to load"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(translations.get("commonRetry", fallback: "Retry")) {
                        serverViewModel.fetch()
                    }
                }
            } else {
                Text(translations.get("hostHostSshNotInstalled",
                                      fallback: "SSH is not installed on this server."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(translations.get("sshSettingsServiceSectionTitle", fallback: "Service"))
        }
    }

    @ViewBuilder
    private var panelSslSection: some View {
        Section {
            if let ssl = serverViewModel.panelSsl {
                InfoLine(label: translations.get("sslSettingsDomain", fallback: "Domain"),
                         value: ssl.domain.isEmpty
                            ? translations.get("websiteSiteSslNoCertificateBound", fallback: "No certificate bound")
                            : ssl.domain)
                InfoLine(label: translations.get("sslSettingsStatus", fallback: "Status"),
                         value: ssl.hasCertificate
                            ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                            : translations.get("systemSettingsDisabled", fallback: "Disabled"))
            } else if serverViewModel.isLoading {
                ProgressView()
            } else {
                Text(translations.get("commonEmpty", fallback: "No data"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(translations.get("panelSslSectionTitle", fallback: "Panel SSL"))
        }
    }

    private var sshOperationConfirmTitle: String {
        let operation = sshOperationLabel(pendingSshOperation) ?? ""
        let template = translations.get("sshOperateConfirm", fallback: "Perform SSH operation: {operation}?")
        return template.replacingOccurrences(of: "{operation}", with: operation)
    }

    private func sshOperationLabel(_ operation: String?) -> String? {
        switch operation {
        case "start":
            return translations.get("containerActionStart", fallback: "Start")
        case "stop":
            return translations.get("containerActionStop", fallback: "Stop")
        case "restart":
            return translations.get("containerActionRestart", fallback: "Restart")
        default:
            return nil
        }
    }

    private func performSshOperation() {
        guard let operation = pendingSshOperation else { return }
        pendingSshOperation = nil
        serverViewModel.operateSsh(operation) { success in
            if !success {
                serverViewModel.errorMessage = translations.get("commonSaveFailed", fallback: "Save failed")
            }
            serverViewModel.fetch()
        }
    }
}

/// 启动门禁：应用锁开启时阻塞内容，本机认证通过后解锁。
struct AppLockGateView: View {
    let onUnlock: () -> Void
    @StateObject private var viewModel = SecurityViewModel()
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(translations.get("appLockUnlockReasonAppOpen",
                                  fallback: "Authenticate to open KenPanel"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if viewModel.isAuthenticating {
                ProgressView()
            } else {
                Button(translations.get("commonRetry", fallback: "Retry")) {
                    viewModel.unlockApp(onSuccess: onUnlock)
                }
                .buttonStyle(.borderedProminent)
            }
            if let error = viewModel.authErrorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            viewModel.unlockApp(onSuccess: onUnlock)
        }
    }
}

/// 服务器侧安全状态：SSH 服务与面板 SSL。
struct SshInfoModel {
    let isExist: Bool
    let isActive: Bool
    let port: String
    let listenAddress: String
}

struct PanelSslModel {
    let domain: String
    let hasCertificate: Bool
}

class SecurityServerViewModel: ObservableObject {
    @Published var ssh: SshInfoModel?
    @Published var panelSsl: PanelSslModel?
    @Published var isLoading = false
    @Published var sshLoadFailed = false
    @Published var errorMessage: String?

    func fetch() {
        isLoading = true
        sshLoadFailed = false
        let group = DispatchGroup()
        group.enter()
        ChannelManager.shared.invokeDataMethod("getSshInfo") { [weak self] result in
            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    if dict["loadFailed"] as? Bool == true || dict["isExist"] == nil {
                        self?.sshLoadFailed = true
                    } else {
                        self?.ssh = SshInfoModel(
                            isExist: dict["isExist"] as? Bool ?? false,
                            isActive: dict["isActive"] as? Bool ?? false,
                            port: dict["port"] as? String ?? "",
                            listenAddress: dict["listenAddress"] as? String ?? ""
                        )
                    }
                } else {
                    self?.sshLoadFailed = true
                }
                group.leave()
            }
        }
        group.enter()
        ChannelManager.shared.invokeDataMethod("getPanelSslInfo") { [weak self] result in
            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    self?.panelSsl = PanelSslModel(
                        domain: dict["domain"] as? String ?? "",
                        hasCertificate: dict["enabled"] as? Bool ?? false
                    )
                } else {
                    self?.panelSsl = nil
                }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }

    func operateSsh(_ operation: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "operateSsh",
            arguments: ["operation": operation]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }
}

/// SSH 配置文件编辑：读取原始配置，保存前二次确认。
struct SSHConfigView: View {
    @EnvironmentObject var translations: TranslationsManager
    @State private var content = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var showSaveConfirm = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && content.isEmpty {
                LoadingView()
            } else {
                TextEditor(text: $content)
                    .font(.system(.caption, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 4)
            }
        }
        .navigationTitle(translations.get("hostHostSshConfigFileTitle",
                                          fallback: "Config File (/etc/ssh/sshd_config)"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isSaving {
                    ProgressView()
                } else {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        showSaveConfirm = true
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .confirmationDialog(
            translations.get("hostHostSshSaveMessage",
                             fallback: "The edited content will overwrite /etc/ssh/sshd_config."),
            isPresented: $showSaveConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonSave", fallback: "Save")) {
                save()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        }
        .operationNotice(toastText)
        .onAppear {
            load()
        }
    }

    private func load() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getSshConfig") { result in
            DispatchQueue.main.async {
                isLoading = false
                if let text = result as? String {
                    content = text
                }
            }
        }
    }

    private func save() {
        isSaving = true
        ChannelManager.shared.invokeDataMethod(
            "saveSshConfig",
            arguments: ["value": content]
        ) { result in
            DispatchQueue.main.async {
                isSaving = false
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}
