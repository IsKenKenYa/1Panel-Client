import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// 转发规则创建表单，两端共用。
public struct ForwardRuleFormView: View {
    @ObservedObject private var store: FirewallV2Store
    private let editor: ForwardRuleEditor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var protocolName: String
    @State private var port: String
    @State private var targetIP: String
    @State private var targetPort: String
    @State private var interfaceName: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store, editor: ForwardRuleEditor = ForwardRuleEditor()) {
        self.store = store
        self.editor = editor
        let rule = editor.rule
        _protocolName = State(initialValue: rule.map {
            $0.protocolName.isEmpty ? "tcp" : $0.protocolName
        } ?? "tcp")
        _port = State(initialValue: rule?.port ?? "")
        _targetIP = State(initialValue: rule?.targetIP ?? "")
        _targetPort = State(initialValue: rule?.targetPort ?? "")
        _interfaceName = State(initialValue: rule?.interfaceName ?? "")
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
            .navigationTitle(editor.rule == nil
                ? t("firewallV2Forward", "Port Forwarding")
                : t("commonEdit", "Edit"))
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
            if let rule = editor.rule {
                try await store.updateForwardRule(
                    rule,
                    port: trimmedPort,
                    protocolName: protocolName,
                    targetIP: targetIP.trimmingCharacters(in: .whitespaces),
                    targetPort: trimmedTargetPort,
                    interfaceName: interfaceName.trimmingCharacters(in: .whitespaces)
                )
            } else {
                try await store.addForwardRule(
                    port: trimmedPort,
                    protocolName: protocolName,
                    targetIP: targetIP.trimmingCharacters(in: .whitespaces),
                    targetPort: trimmedTargetPort,
                    interfaceName: interfaceName.trimmingCharacters(in: .whitespaces)
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

/// Docker 端口防护策略创建表单，两端共用。
public struct DockerPolicyFormView: View {
    @ObservedObject private var store: FirewallV2Store
    private let editor: DockerPolicyEditor

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var family: String
    @State private var hostIP: String
    @State private var hostPort: String
    @State private var protocolName: String
    @State private var mode: String
    @State private var sources: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store, editor: DockerPolicyEditor = DockerPolicyEditor()) {
        self.store = store
        self.editor = editor
        let policy = editor.policy
        _family = State(initialValue: policy.map {
            $0.family.isEmpty ? "ipv4" : $0.family
        } ?? "ipv4")
        _hostIP = State(initialValue: policy.map {
            $0.hostIP.isEmpty ? "0.0.0.0" : $0.hostIP
        } ?? "0.0.0.0")
        _hostPort = State(initialValue: policy?.hostPort ?? "")
        _protocolName = State(initialValue: policy.map {
            $0.protocolName.isEmpty ? "tcp" : $0.protocolName
        } ?? "tcp")
        _mode = State(initialValue: policy.map {
            $0.mode.isEmpty ? "deny_sources" : $0.mode
        } ?? "deny_sources")
        _sources = State(initialValue: policy?.sources.joined(separator: ", ") ?? "")
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
            .navigationTitle(editor.policy == nil
                ? t("firewallV2AddDockerPolicy", "Add Docker policy")
                : t("commonEdit", "Edit"))
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
            if let policy = editor.policy {
                try await store.updateDockerPolicy(
                    policy,
                    mode: mode,
                    sources: Self.splitSources(sources)
                )
            } else {
                try await store.addDockerPolicy(
                    family: family,
                    hostIP: hostIP.trimmingCharacters(in: .whitespaces),
                    hostPort: portValue,
                    mode: mode,
                    protocolName: protocolName,
                    sources: Self.splitSources(sources)
                )
            }
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

/// Docker 端口策略导入行：按端点标识去重后的预览条目。
public struct DockerPolicyImportRow: Identifiable {
    public let id: String
    public let family: String
    public let hostIP: String
    public let hostPort: Int
    public let protocolName: String
    public let mode: String
    public let sources: [String]

    public var hostText: String {
        "\(hostIP.isEmpty ? "*" : hostIP):\(hostPort)/\(protocolName)"
    }

    public var payload: [String: Any] {
        [
            "family": family,
            "hostIP": hostIP,
            "hostPort": hostPort,
            "protocol": protocolName,
            "mode": mode,
            "sources": sources,
        ]
    }

    init?(payload: [String: Any]) {
        let family = firewallText(payload["family"])
        let hostIP = firewallText(payload["hostIP"])
        let protocolName = firewallText(payload["protocol"])
        let mode = firewallText(payload["mode"])
        let hostPort = Int(firewallText(payload["hostPort"])) ?? 0
        let validModes = [
            "deny_sources", "allow_sources", "deny_all",
            "accept_sources", "accept_all",
        ]
        guard !hostIP.isEmpty, (1...65535).contains(hostPort),
              ["tcp", "udp"].contains(protocolName),
              validModes.contains(mode) else {
            return nil
        }
        let normalizedFamily = family.isEmpty
            ? (hostIP.contains(":") ? "ipv6" : "ipv4")
            : family
        guard ["ipv4", "ipv6"].contains(normalizedFamily) else {
            return nil
        }
        let sources = (payload["sources"] as? [Any] ?? []).map {
            firewallText($0)
        }.filter { !$0.isEmpty }
        self.id = "\(normalizedFamily)|\(hostIP)|\(hostPort)|\(protocolName)"
        self.family = normalizedFamily
        self.hostIP = hostIP
        self.hostPort = hostPort
        self.protocolName = protocolName
        self.mode = mode
        self.sources = sources
    }
}

/// Docker 端口策略批量修改与 JSON 导入，两端共用。
public struct DockerPolicyBatchFormView: View {
    @ObservedObject private var store: FirewallV2Store

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var selectedIDs: Set<String> = []
    @State private var mode = "deny_sources"
    @State private var sources = ""
    @State private var importRows: [DockerPolicyImportRow] = []
    @State private var importSelection: Set<String> = []
    @State private var importFileName = ""
    @State private var showFileImporter = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: FirewallV2Store) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(t("firewallV2DockerSelectPolicies", "Select policies")) {
                    if store.dockerPolicies.isEmpty {
                        Text(t("firewallV2Empty", "No records"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(store.dockerPolicies) { policy in
                            Button {
                                toggle(policy.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(policy.hostText)
                                        Text(policy.mode)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedIDs.contains(policy.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else {
                                        Image(systemName: "circle")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Section {
                    Picker(t("firewallV2PolicyModeLabel", "Policy mode"), selection: $mode) {
                        ForEach(Self.modes, id: \.self) { value in
                            Text(modeTitle(value)).tag(value)
                        }
                    }
                    TextField(t("firewallV2SourcesLabel", "Sources"), text: $sources)
                    Button {
                        Task { await applySelection() }
                    } label: {
                        Text(t("firewallV2DockerBatchApply", "Apply to selected"))
                    }
                    .disabled(isSaving || selectedIDs.isEmpty)
                } footer: {
                    Text(t("firewallV2SourcesHint",
                           "Separate multiple addresses with commas."))
                }
                Section {
                    Button {
                        showFileImporter = true
                    } label: {
                        Label(t("firewallV2DockerChooseFile", "Choose JSON file"),
                              systemImage: "doc.badge.plus")
                    }
                    if !importFileName.isEmpty {
                        Text(importFileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if !importRows.isEmpty {
                        Text("\(t("firewallV2DockerPreview", "Preview")): \(importRows.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(importRows) { row in
                            Button {
                                toggleImport(row.id)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.hostText)
                                        Text(modeTitle(row.mode))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if !row.sources.isEmpty {
                                            Text(row.sources.joined(separator: ", "))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if importSelection.contains(row.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else {
                                        Image(systemName: "circle")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        Task { await importSelected() }
                    } label: {
                        Text(t("firewallV2DockerImportAction", "Import JSON"))
                    }
                    .disabled(isSaving || importSelection.isEmpty)
                } header: {
                    Text(t("firewallV2DockerImportAction", "Import JSON"))
                } footer: {
                    Text(t("firewallV2DockerImportHint",
                           "Select a JSON policy file; duplicate endpoints are removed in the preview."))
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(t("firewallV2BatchDockerAction", "Batch modify"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileResult(result)
            }
        }
    }

    private func toggle(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func applySelection() async {
        let policies = store.dockerPolicies.filter { selectedIDs.contains($0.id) }
        guard !policies.isEmpty else {
            errorMessage = t("firewallV2NoSelection", "Select at least one policy.")
            return
        }
        isSaving = true
        do {
            try await store.updateDockerPolicies(
                policies,
                mode: mode,
                sources: DockerPolicyFormView.splitSources(sources)
            )
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func toggleImport(_ id: String) {
        if importSelection.contains(id) {
            importSelection.remove(id)
        } else {
            importSelection.insert(id)
        }
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let error):
            if (error as NSError).code == NSUserCancelledError {
                return
            }
            errorMessage = error.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            loadImportFile(url)
        }
    }

    private func loadImportFile(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        do {
            let data = try Data(contentsOf: url)
            guard let rows = Self.parseImportRows(data) else {
                errorMessage = t("firewallV2DockerImportInvalid", "Invalid JSON.")
                return
            }
            guard !rows.isEmpty else {
                errorMessage = t("firewallV2NoSelection", "Select at least one policy.")
                return
            }
            importRows = rows
            importSelection = Set(rows.map(\.id))
            importFileName = url.lastPathComponent
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importSelected() async {
        let policies = importRows
            .filter { importSelection.contains($0.id) }
            .map(\.payload)
        guard !policies.isEmpty else {
            errorMessage = t("firewallV2NoSelection", "Select at least one policy.")
            return
        }
        isSaving = true
        do {
            try await store.importDockerPolicies(policies)
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    public static func parseImportRows(_ data: Data) -> [DockerPolicyImportRow]? {
        guard let object = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        let policies: [[String: Any]]
        if let array = object as? [[String: Any]] {
            policies = array
        } else if let dict = object as? [String: Any],
                  let list = dict["policies"] as? [[String: Any]] {
            policies = list
        } else {
            return nil
        }
        var seen = Set<String>()
        return policies.compactMap { policy in
            guard let row = DockerPolicyImportRow(payload: policy),
                  seen.insert(row.id).inserted else {
                return nil
            }
            return row
        }
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
    @State private var pendingOperation: String?
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
                            backendRow(option)
                        }
                        .disabled(isSaving || !option.supported)
                    }
                }
                Section {
                    Button {
                        pendingOperation = "initialize"
                    } label: {
                        Text(t("firewallV2BackendInitializeAction", "Initialize backend"))
                    }
                    .disabled(isSaving || selected.isEmpty)
                    Button {
                        pendingOperation = "cleanup"
                    } label: {
                        Text(t("firewallV2BackendCleanupAction", "Cleanup backend"))
                    }
                    .disabled(isSaving || selected.isEmpty)
                } header: {
                    Text(t("firewallV2BackendActions", "Backend actions"))
                } footer: {
                    Text(t("firewallV2BackendActionsHint",
                           "Operations apply to the selected backend and can change firewall rules."))
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
            .confirmationDialog(
                operationConfirmTitle,
                isPresented: Binding(
                    get: { pendingOperation != nil },
                    set: { if !$0 { pendingOperation = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button(operationConfirmTitle) {
                    Task { await runBackendOperation() }
                }
                Button(t("commonCancel", "Cancel"), role: .cancel) {
                    pendingOperation = nil
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

    private var operationConfirmTitle: String {
        guard let pendingOperation else { return "" }
        let label = pendingOperation == "initialize"
            ? t("firewallV2BackendInitializeAction", "Initialize backend")
            : t("firewallV2BackendCleanupAction", "Cleanup backend")
        return "\(subsystemTitle(subsystem)): \(label)"
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

    private func runBackendOperation() async {
        guard let operation = pendingOperation else { return }
        pendingOperation = nil
        guard !selected.isEmpty else {
            errorMessage = t("firewallV2NoSelection", "Select at least one policy.")
            return
        }
        isSaving = true
        do {
            try await store.operateBackend(
                subsystem: subsystem,
                backend: selected,
                operation: operation
            )
            dismiss()
        } catch {
            errorMessage = actionMessage(error)
        }
        isSaving = false
    }

    private func backendRow(_ option: FirewallBackendOption) -> some View {
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