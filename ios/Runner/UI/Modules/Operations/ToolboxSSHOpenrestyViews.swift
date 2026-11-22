import AppleSharedUI
import SwiftUI

/// 工具箱入口：设备快照与 DNS 校验。
struct ToolboxView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var snapshot: [String: String] = [:]
    @State private var dns = ""
    @State private var isLoading = true
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && snapshot.isEmpty {
                LoadingView()
            } else {
                List {
                    Section(translations.get("toolboxDeviceOverviewTitle", fallback: "Device Overview")) {
                        ForEach(snapshot.sorted(by: { $0.key < $1.key }), id: \.key) { item in
                            InfoLine(label: item.key, value: item.value)
                        }
                    }
                    Section(translations.get("toolboxDeviceDnsCheckTitle", fallback: "DNS Check")) {
                        TextField(translations.get("toolboxDeviceDnsLabel", fallback: "DNS server"),
                                  text: $dns)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            Task { await verifyDns() }
                        } label: {
                            if isVerifying {
                                ProgressView().controlSize(.small)
                            } else {
                                Label(translations.get("toolboxDeviceDnsCheckAction",
                                                       fallback: "Verify DNS"),
                                      systemImage: "checkmark.shield")
                            }
                        }
                        .disabled(isVerifying || dns.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if let errorMessage {
                        Section {
                            Text(errorMessage).font(.caption).foregroundStyle(.red)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("toolboxCenterTitle", fallback: "Toolbox"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .operationNotice(toastText)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getDeviceSnapshot"
            )
            let payload = raw as? [String: Any] ?? [:]
            snapshot = payload.reduce(into: [String: String]()) { result, item in
                let value = item.value
                if let text = value as? String {
                    result[item.key] = text
                } else if let flag = value as? Bool {
                    result[item.key] = flag ? "true" : "false"
                } else if let number = value as? NSNumber {
                    result[item.key] = number.stringValue
                } else if let array = value as? [Any] {
                    result[item.key] = "\(array.count)"
                }
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func verifyDns() async {
        isVerifying = true
        let server = dns.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "verifyToolboxDns",
                arguments: ["dns": server]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                showToast(translations.get("toolboxDeviceDnsReachable", fallback: "DNS reachable"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("toolboxDeviceDnsUnreachable",
                                         fallback: "DNS is unreachable")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isVerifying = false
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

/// SSH 服务入口：状态、操作与原始配置。
struct SSHModuleView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var isExist = false
    @State private var isActive = false
    @State private var port = ""
    @State private var listenAddress = ""
    @State private var config = ""
    @State private var originalConfig = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var pendingOperation: String?
    @State private var errorMessage: String?
    @State private var toastText: String?

    var body: some View {
        Form {
            Section(translations.get("sshSettingsServiceSectionTitle", fallback: "Service")) {
                if isLoading {
                    ProgressView().controlSize(.small)
                } else if isExist {
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: isActive
                                ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                    InfoLine(label: translations.get("sshPortLabel", fallback: "Port"),
                             value: port.isEmpty ? "--" : port)
                    if !listenAddress.isEmpty {
                        InfoLine(label: translations.get("sshListenAddressLabel",
                                                         fallback: "Listen Address"),
                                 value: listenAddress)
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
                } else {
                    Text(translations.get("sshNotInstalled", fallback: "SSH service is not installed"))
                        .foregroundStyle(.secondary)
                }
            }

            Section(translations.get("sshSettingsRawFileSectionTitle", fallback: "Raw File")) {
                TextEditor(text: $config)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 220)
                HStack {
                    Spacer()
                    Button {
                        Task { await saveConfig() }
                    } label: {
                        if isSaving {
                            ProgressView().controlSize(.small)
                        } else {
                            Text(translations.get("commonSave", fallback: "Save"))
                        }
                    }
                    .disabled(isSaving || config == originalConfig || config.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(translations.get("serverModuleSsh", fallback: "SSH Service"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
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
                Button(operationLabel(operation),
                       role: operation == "stop" ? .destructive : nil) {
                    Task { await operate(operation) }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingOperation = nil
                }
            }
        } message: {
            Text(translations.get("sshOperationConfirm",
                                  fallback: "Apply this SSH service operation?"))
        }
        .operationNotice(toastText)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let infoRaw = try await ChannelManager.shared.invokeDataMethodAsync("getSshInfo")
            let info = infoRaw as? [String: Any] ?? [:]
            isExist = info["isExist"] as? Bool ?? false
            isActive = info["isActive"] as? Bool ?? false
            port = info["port"] as? String ?? ""
            listenAddress = info["listenAddress"] as? String ?? ""
            let configRaw = try await ChannelManager.shared.invokeDataMethodAsync("getSshConfig")
            config = configRaw as? String ?? ""
            originalConfig = config
            errorMessage = nil
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
                await load()
                showToast(translations.get("commonOperationSuccess", fallback: "Operation succeeded"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func saveConfig() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "saveSshConfig",
                arguments: ["value": config]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                originalConfig = config
                showToast(translations.get("commonSaveSuccess", fallback: "Saved"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func operationLabel(_ operation: String) -> String {
        switch operation {
        case "start": return translations.get("sshStartAction", fallback: "Start")
        case "stop": return translations.get("sshStopAction", fallback: "Stop")
        case "restart": return translations.get("sshRestartAction", fallback: "Restart")
        default: return operation
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

/// OpenResty 网关入口：状态、模块、HTTPS 与配置内容。
struct OpenrestyView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var status = ""
    @State private var configContent = ""
    @State private var modulesText = ""
    @State private var httpsText = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && status.isEmpty && configContent.isEmpty {
                LoadingView()
            } else if let errorMessage, status.isEmpty, configContent.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else {
                List {
                    Section(translations.get("openrestyPageTitle", fallback: "OpenResty")) {
                        InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                                 value: status.isEmpty ? "--" : status)
                    }
                    if !modulesText.isEmpty {
                        Section(translations.get("openrestyModulesTitle", fallback: "Modules")) {
                            Text(modulesText)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    if !httpsText.isEmpty {
                        Section(translations.get("websitesHttpsTitle", fallback: "HTTPS")) {
                            Text(httpsText)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                    if !configContent.isEmpty {
                        Section(translations.get("openrestyConfigTitle", fallback: "Configuration")) {
                            Text(configContent)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("openrestyPageTitle", fallback: "OpenResty"))
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
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getOpenrestySnapshot"
            )
            let payload = raw as? [String: Any] ?? [:]
            status = payload["status"] as? String ?? ""
            configContent = payload["configContent"] as? String ?? ""
            modulesText = stringify(payload["modules"])
            httpsText = stringify(payload["https"])
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func stringify(_ value: Any?) -> String {
        guard let value else { return "" }
        if let text = value as? String { return text }
        if JSONSerialization.isValidJSONObject(value),
           let data = try? JSONSerialization.data(withJSONObject: value,
                                                  options: [.prettyPrinted]),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        return "\(value)"
    }
}