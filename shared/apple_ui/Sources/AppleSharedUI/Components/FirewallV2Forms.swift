import SwiftUI

/// 转发规则创建表单，两端共用。
public struct ForwardRuleFormView: View {
    @ObservedObject private var store: FirewallV2Store

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var protocolName = "tcp"
    @State private var port = ""
    @State private var targetIP = ""
    @State private var targetPort = ""
    @State private var interfaceName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(t("firewallProtocolLabel", "Protocol"), selection: $protocolName) {
                        ForEach(["tcp", "udp", "tcp/udp"], id: \.self) { value in
                            Text(value).tag(value)
                        }
                    }
                    TextField(t("firewallPortLabel", "Port"), text: $port)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                    TextField(t("firewallTargetIPLabel", "Target IP"), text: $targetIP)
                    TextField(t("firewallTargetPortLabel", "Target port"), text: $targetPort)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField(t("firewallInterfaceLabel", "Interface"), text: $interfaceName)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(t("firewallV2Forward", "Port Forwarding"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func submit() async {
        let trimmedPort = port.trimmingCharacters(in: .whitespaces)
        let trimmedTargetPort = targetPort.trimmingCharacters(in: .whitespaces)
        guard !trimmedPort.isEmpty, !trimmedTargetPort.isEmpty else {
            errorMessage = t("firewallV2RequiredFields", "Fill in the required fields.")
            return
        }
        isSaving = true
        do {
            try await store.addForwardRule(
                port: trimmedPort,
                protocolName: protocolName,
                targetIP: targetIP.trimmingCharacters(in: .whitespaces),
                targetPort: trimmedTargetPort,
                interfaceName: interfaceName.trimmingCharacters(in: .whitespaces)
            )
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func actionMessage(_ error: Error) -> String {
        if let message = (error as? FirewallV2ActionError)?.errorDescription,
           !message.isEmpty {
            return message
        }
        return t("commonOperationFailed", "Operation failed")
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

/// Docker 端口防护策略创建表单，两端共用。
public struct DockerPolicyFormView: View {
    @ObservedObject private var store: FirewallV2Store

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var family = "ipv4"
    @State private var hostIP = "0.0.0.0"
    @State private var hostPort = ""
    @State private var protocolName = "tcp"
    @State private var mode = "deny_sources"
    @State private var sources = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(t("firewallFamilyLabel", "Family"), selection: $family) {
                        Text("ipv4").tag("ipv4")
                        Text("ipv6").tag("ipv6")
                    }
                    TextField(t("firewallV2HostIPLabel", "Host IP"), text: $hostIP)
                    TextField(t("firewallPortLabel", "Port"), text: $hostPort)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Picker(t("firewallProtocolLabel", "Protocol"), selection: $protocolName) {
                        Text("tcp").tag("tcp")
                        Text("udp").tag("udp")
                    }
                    Picker(t("firewallV2PolicyModeLabel", "Policy mode"), selection: $mode) {
                        ForEach(Self.modes, id: \.self) { value in
                            Text(modeTitle(value)).tag(value)
                        }
                    }
                    TextField(t("firewallV2SourcesLabel", "Sources"), text: $sources)
                } footer: {
                    Text(t("firewallV2SourcesHint",
                           "Separate multiple addresses with commas."))
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(t("firewallV2AddDockerPolicy", "Add Docker policy"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func submit() async {
        let trimmedPort = hostPort.trimmingCharacters(in: .whitespaces)
        guard let portValue = Int(trimmedPort), portValue > 0, portValue <= 65535 else {
            errorMessage = t("firewallV2RequiredFields", "Fill in the required fields.")
            return
        }
        isSaving = true
        do {
            try await store.addDockerPolicy(
                family: family,
                hostIP: hostIP.trimmingCharacters(in: .whitespaces),
                hostPort: portValue,
                mode: mode,
                protocolName: protocolName,
                sources: Self.splitSources(sources)
            )
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func modeTitle(_ value: String) -> String {
        switch value {
        case "allow_sources":
            return t("firewallV2ModeAllowSources", "Allow listed sources")
        case "deny_all":
            return t("firewallV2ModeDenyAll", "Deny all")
        case "accept_sources":
            return t("firewallV2ModeAcceptSources", "Accept listed sources")
        case "accept_all":
            return t("firewallV2ModeAcceptAll", "Accept all")
        default:
            return t("firewallV2ModeDenySources", "Deny listed sources")
        }
    }

    private func actionMessage(_ error: Error) -> String {
        if let message = (error as? FirewallV2ActionError)?.errorDescription,
           !message.isEmpty {
            return message
        }
        return t("commonOperationFailed", "Operation failed")
    }

    private static let modes = [
        "deny_sources",
        "allow_sources",
        "deny_all",
        "accept_sources",
        "accept_all",
    ]

    static func splitSources(_ value: String) -> [String] {
        value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

/// 端口白名单创建与编辑表单，两端共用。
public struct WhitelistRuleFormView: View {
    @ObservedObject private var store: FirewallV2Store
    private let editor: WhitelistRuleEditor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var port: String
    @State private var protocolName: String
    @State private var type: String
    @State private var sources: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store, editor: WhitelistRuleEditor = WhitelistRuleEditor()) {
        self.store = store
        self.editor = editor
        let rule = editor.rule
        _port = State(initialValue: rule?.port ?? "")
        _protocolName = State(initialValue: rule.map {
            $0.protocolName.isEmpty ? "tcp" : $0.protocolName
        } ?? "tcp")
        _type = State(initialValue: rule?.type ?? "")
        _sources = State(initialValue: rule?.sources.joined(separator: ", ") ?? "")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(t("firewallPortLabel", "Port"), text: $port)
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        #endif
                    Picker(t("firewallProtocolLabel", "Protocol"), selection: $protocolName) {
                        Text("tcp").tag("tcp")
                        Text("udp").tag("udp")
                    }
                    Picker(t("firewallV2WhitelistTypeLabel", "Type"), selection: $type) {
                        Text(t("firewallV2WhitelistTypeNone", "None")).tag("")
                        Text(t("firewallV2WhitelistTypePanel", "Panel")).tag("panel")
                        Text(t("firewallV2WhitelistTypeSSH", "SSH")).tag("ssh")
                    }
                    TextField(t("firewallV2SourcesLabel", "Sources"), text: $sources)
                } footer: {
                    Text(t("firewallV2SourcesHint",
                           "Separate multiple addresses with commas."))
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(editor.rule == nil
                ? t("firewallV2AddWhitelist", "Add whitelist rule")
                : t("firewallV2EditWhitelist", "Edit whitelist rule"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func submit() async {
        let trimmedPort = port.trimmingCharacters(in: .whitespaces)
        guard !trimmedPort.isEmpty else {
            errorMessage = t("firewallPortRequired", "Port is required.")
            return
        }
        isSaving = true
        do {
            let sourceList = DockerPolicyFormView.splitSources(sources)
            if let rule = editor.rule {
                try await store.updateWhitelist(
                    old: rule,
                    port: trimmedPort,
                    protocolName: protocolName,
                    type: type,
                    sources: sourceList
                )
            } else {
                try await store.createWhitelist(
                    port: trimmedPort,
                    protocolName: protocolName,
                    type: type,
                    sources: sourceList
                )
            }
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func actionMessage(_ error: Error) -> String {
        if let message = (error as? FirewallV2ActionError)?.errorDescription,
           !message.isEmpty {
            return message
        }
        return t("commonOperationFailed", "Operation failed")
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

/// 防火墙后端选择表单，两端共用。
public struct FirewallBackendFormView: View {
    @ObservedObject private var store: FirewallV2Store

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var subsystem = "system"
    @State private var pendingBackend: String?
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(t("firewallV2SubsystemLabel", "Subsystem"), selection: $subsystem) {
                        ForEach(store.backendGroups) { group in
                            Text(subsystemTitle(group.subsystem)).tag(group.subsystem)
                        }
                    }
                }
                Section(t("firewallV2BackendLabel", "Backend")) {
                    ForEach(options) { option in
                        Button {
                            pendingBackend = option.name
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.name)
                                    Text(statusText(option))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if option.name == selected {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        .disabled(isSaving || !option.supported)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(t("firewallV2SwitchBackend", "Switch backend"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
            }
            .confirmationDialog(
                backendConfirmTitle,
                isPresented: Binding(
                    get: { pendingBackend != nil },
                    set: { if !$0 { pendingBackend = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(t("firewallV2ConfirmBackend", "Switch backend")) {
                    Task { await submit() }
                }
                Button(t("commonCancel", "Cancel"), role: .cancel) {
                    pendingBackend = nil
                }
            } message: {
                Text(t("firewallV2ConfirmTitle", "Confirm the firewall change"))
            }
        }
    }

    private var group: FirewallBackendGroup? {
        store.backendGroups.first { $0.subsystem == subsystem }
    }

    private var options: [FirewallBackendOption] {
        group?.options ?? []
    }

    private var selected: String {
        group?.selected ?? ""
    }

    private var backendConfirmTitle: String {
        guard let pendingBackend else { return "" }
        return "\(subsystemTitle(subsystem)): \(pendingBackend)"
    }

    private func submit() async {
        guard let backend = pendingBackend else { return }
        pendingBackend = nil
        isSaving = true
        do {
            try await store.selectBackend(subsystem: subsystem, backend: backend)
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func subsystemTitle(_ value: String) -> String {
        switch value {
        case "forwarding":
            return t("firewallV2SubsystemForwarding", "Forwarding")
        case "docker":
            return t("firewallV2SubsystemDocker", "Docker")
        default:
            return t("firewallV2SubsystemSystem", "System")
        }
    }

    private func statusText(_ option: FirewallBackendOption) -> String {
        var parts: [String] = []
        if option.active { parts.append(t("firewallV2BackendActive", "Active")) }
        if option.installed { parts.append(t("firewallV2BackendInstalled", "Installed")) }
        if option.bound { parts.append(t("firewallBoundLabel", "Bound")) }
        if !option.supported {
            parts.append(t("firewallV2BackendUnsupported", "Unsupported"))
        }
        return parts.isEmpty ? "--" : parts.joined(separator: " · ")
    }

    private func actionMessage(_ error: Error) -> String {
        if let message = (error as? FirewallV2ActionError)?.errorDescription,
           !message.isEmpty {
            return message
        }
        return t("commonOperationFailed", "Operation failed")
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}