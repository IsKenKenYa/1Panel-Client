import AppleSharedUI
import SwiftUI

/// SSH 服务详情：服务状态、端口、监听地址与启停操作。
struct SSHServiceDetailView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var info: [String: Any] = [:]
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var pendingOperation: String?
    @State private var actionMessage: String?

    var body: some View {
        Group {
            if isLoading && info.isEmpty {
                LoadingView()
            } else if loadFailed && info.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle",
                                                    fallback: "Failed to load")) {
                    fetch()
                }
            } else {
                content
            }
        }
        .navigationTitle(translations.get("securitySshDetailTitle",
                                          fallback: "SSH Service Details"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if info.isEmpty {
                fetch()
            }
        }
        .confirmationDialog(
            operationConfirmTitle,
            isPresented: Binding(
                get: { pendingOperation != nil },
                set: { if !$0 { pendingOperation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let operation = pendingOperation {
                Button(operationLabel(operation)) {
                    perform(operation)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingOperation = nil
                }
            }
        }
    }

    private var content: some View {
        List {
            Section(translations.get("sshSettingsServiceSectionTitle", fallback: "Service")) {
                InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                         value: isActive
                             ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                             : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                InfoLine(label: translations.get("sshPortLabel", fallback: "Port"),
                         value: port.isEmpty ? "--" : port)
                InfoLine(label: translations.get("sshListenAddressLabel",
                                                 fallback: "Listen Address"),
                         value: listenAddress.isEmpty ? "--" : listenAddress)
            }
            Section(translations.get("websitesDetailActionsTitle", fallback: "Actions")) {
                Button {
                    pendingOperation = "start"
                } label: {
                    Label(translations.get("containerActionStart", fallback: "Start"),
                          systemImage: "play.fill")
                }
                .disabled(isActive)
                Button {
                    pendingOperation = "restart"
                } label: {
                    Label(translations.get("containerActionRestart", fallback: "Restart"),
                          systemImage: "arrow.clockwise")
                }
                Button {
                    pendingOperation = "stop"
                } label: {
                    Label(translations.get("containerActionStop", fallback: "Stop"),
                          systemImage: "stop.fill")
                }
                .disabled(!isActive)
                NavigationLink {
                    SSHConfigView()
                        .environmentObject(translations)
                } label: {
                    Label(translations.get("hostHostSshConfigFileTitle",
                                           fallback: "Config File (/etc/ssh/sshd_config)"),
                          systemImage: "doc.text")
                }
            }
            if let actionMessage {
                Section {
                    Text(actionMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            fetch()
        }
    }

    private var isActive: Bool { info["isActive"] as? Bool ?? false }
    private var port: String { info["port"] as? String ?? "" }
    private var listenAddress: String { info["listenAddress"] as? String ?? "" }

    private var operationConfirmTitle: String {
        guard let operation = pendingOperation else { return "" }
        let template = translations.get("sshOperateConfirm",
                                        fallback: "Perform SSH operation: {operation}?")
        return template.replacingOccurrences(of: "{operation}",
                                             with: operationLabel(operation))
    }

    private func operationLabel(_ operation: String) -> String {
        switch operation {
        case "start":
            return translations.get("containerActionStart", fallback: "Start")
        case "stop":
            return translations.get("containerActionStop", fallback: "Stop")
        default:
            return translations.get("containerActionRestart", fallback: "Restart")
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getSshInfo") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      dict["loadFailed"] as? Bool != true,
                      dict["isExist"] != nil else {
                    loadFailed = true
                    return
                }
                info = dict
                loadFailed = false
            }
        }
    }

    private func perform(_ operation: String) {
        pendingOperation = nil
        ChannelManager.shared.invokeDataMethod(
            "operateSsh",
            arguments: ["operation": operation]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                actionMessage = success
                    ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                    : translations.get("commonOperationFailed", fallback: "Operation failed")
                if success { fetch() }
            }
        }
    }
}

/// 面板 SSL 详情：绑定域名与证书状态。
struct PanelSslDetailView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var info: [String: Any] = [:]
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading && info.isEmpty {
                LoadingView()
            } else if info.isEmpty {
                EmptyStateView(
                    icon: "lock.shield",
                    message: translations.get("commonEmpty", fallback: "No data"),
                    description: translations.get("websiteSiteSslNoCertificateBound",
                                                  fallback: "No certificate bound")
                )
            } else {
                List {
                    Section(translations.get("panelSslSectionTitle", fallback: "Panel SSL")) {
                        InfoLine(label: translations.get("sslSettingsDomain", fallback: "Domain"),
                                 value: domain.isEmpty ? "--" : domain)
                        InfoLine(label: translations.get("sslSettingsStatus", fallback: "Status"),
                                 value: enabled
                                     ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                     : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                        if let expireDate = info["expireDate"] as? String, !expireDate.isEmpty {
                            InfoLine(
                                label: translations.get("securityPanelSslExpireDateLabel",
                                                        fallback: "Expire date"),
                                value: expireDate
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .navigationTitle(translations.get("securityPanelSslDetailTitle",
                                          fallback: "Panel SSL Details"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if info.isEmpty {
                fetch()
            }
        }
    }

    private var domain: String { info["domain"] as? String ?? "" }
    private var enabled: Bool { info["enabled"] as? Bool ?? false }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getPanelSslInfo") { result in
            DispatchQueue.main.async {
                isLoading = false
                info = result as? [String: Any] ?? [:]
            }
        }
    }
}