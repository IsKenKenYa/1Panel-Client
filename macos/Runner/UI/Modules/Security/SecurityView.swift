import AppleSharedUI
import SwiftUI

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

/// macOS 安全页：SSH 服务状态与操作、面板 SSL 信息。
struct SecurityView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var ssh: SshInfoModel?
    @State private var panelSsl: PanelSslModel?
    @State private var isLoading = false
    @State private var sshLoadFailed = false
    @State private var pendingOperation: String?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(translations.get("sshServiceTitle", fallback: "SSH Service")) {
                if sshLoadFailed {
                    Text(translations.get("sshLoadFailedHint",
                                           fallback: "SSH information is unavailable"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let ssh, ssh.isExist {
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: ssh.isActive
                                ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                    InfoLine(label: translations.get("sshPortLabel", fallback: "Port"),
                             value: ssh.port.isEmpty ? "--" : ssh.port)
                    if !ssh.listenAddress.isEmpty {
                        InfoLine(label: translations.get("sshListenAddressLabel",
                                                         fallback: "Listen Address"),
                                 value: ssh.listenAddress)
                    }
                    HStack(spacing: 12) {
                        Button(translations.get("sshStartAction", fallback: "Start")) {
                            pendingOperation = "start"
                        }
                        Button(translations.get("sshStopAction", fallback: "Stop")) {
                            pendingOperation = "stop"
                        }
                        Button(translations.get("sshRestartAction", fallback: "Restart")) {
                            pendingOperation = "restart"
                        }
                    }
                    .disabled(isLoading)
                } else if isLoading {
                    ProgressView().controlSize(.small)
                } else {
                    Text(translations.get("sshNotInstalled", fallback: "SSH service is not installed"))
                        .foregroundStyle(.secondary)
                }
            }

            Section(translations.get("panelSslTitle", fallback: "Panel SSL")) {
                if let panelSsl {
                    InfoLine(label: translations.get("websitesPrimaryDomainLabel",
                                                     fallback: "Domain"),
                             value: panelSsl.domain.isEmpty ? "--" : panelSsl.domain)
                    InfoLine(label: translations.get("websitesTabSsl", fallback: "SSL"),
                             value: panelSsl.hasCertificate
                                ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                } else {
                    Text(translations.get("panelSslUnavailable", fallback: "Panel SSL information is unavailable"))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(translations.get("navSecurity", fallback: "Security"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await fetch() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .confirmationDialog(
            operationLabel(pendingOperation ?? ""),
            isPresented: Binding(
                get: { pendingOperation != nil },
                set: { if !$0 { pendingOperation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let operation = pendingOperation {
                Button(operationLabel(operation), role: operation == "stop" ? .destructive : nil) {
                    Task { await operate(operation) }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingOperation = nil
                }
            }
        } message: {
            Text(translations.get("sshOperationConfirm", fallback: "Apply this SSH service operation?"))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await fetch()
        }
    }

    private func fetch() async {
        isLoading = true
        do {
            let sshRaw = try await ChannelManager.shared.invokeDataMethodAsync("getSshInfo")
            if let dict = sshRaw as? [String: Any],
               dict["loadFailed"] as? Bool != true,
               dict["isExist"] != nil {
                ssh = SshInfoModel(
                    isExist: dict["isExist"] as? Bool ?? false,
                    isActive: dict["isActive"] as? Bool ?? false,
                    port: dict["port"] as? String ?? "",
                    listenAddress: dict["listenAddress"] as? String ?? ""
                )
                sshLoadFailed = false
            } else {
                sshLoadFailed = true
            }
            let sslRaw = try await ChannelManager.shared.invokeDataMethodAsync("getPanelSslInfo")
            if let dict = sslRaw as? [String: Any] {
                panelSsl = PanelSslModel(
                    domain: dict["domain"] as? String ?? "",
                    hasCertificate: dict["enabled"] as? Bool ?? false
                )
            } else {
                panelSsl = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func operate(_ operation: String) async {
        pendingOperation = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "operateSsh",
                arguments: ["operation": operation]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await fetch()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func operationLabel(_ operation: String) -> String {
        switch operation {
        case "start": return translations.get("sshStartAction", fallback: "Start")
        case "stop": return translations.get("sshStopAction", fallback: "Stop")
        case "restart": return translations.get("sshRestartAction", fallback: "Restart")
        default: return operation
        }
    }
}