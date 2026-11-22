import AppleSharedUI
import SwiftUI

struct FirewallBaseInfoModel {
    let name: String
    let isExist: Bool
    let isActive: Bool
    let isInit: Bool
    let isBound: Bool
    let version: String
}

@MainActor
final class FirewallBaseStore: ObservableObject {
    @Published var info = FirewallBaseInfoModel(
        name: "", isExist: false, isActive: false, isInit: false,
        isBound: false, version: ""
    )
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync("getFirewallBaseInfo")
            let payload = raw as? [String: Any] ?? [:]
            info = FirewallBaseInfoModel(
                name: payload["name"] as? String ?? "",
                isExist: payload["isExist"] as? Bool ?? false,
                isActive: payload["isActive"] as? Bool ?? false,
                isInit: payload["isInit"] as? Bool ?? false,
                isBound: payload["isBind"] as? Bool ?? false,
                version: payload["version"] as? String ?? ""
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func operate(_ operation: String) async -> String? {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "operateFirewall",
                arguments: ["operation": operation]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await fetch()
                return nil
            }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

/// macOS 防火墙：状态、端口规则、IP 规则、转发、Docker 与设置。
struct FirewallModuleView: View {
    @StateObject private var rules = FirewallViewModel()
    @StateObject private var base = FirewallBaseStore()
    @StateObject private var v2 = FirewallV2Store(
        channel: MacOSDataChannel(channelManager: .shared)
    )

    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = ProcessInfo.processInfo.environment["ONEPANEL_FIREWALL_TAB"]
        ?? "status"
    @State private var editor: FirewallRuleEditor?
    @State private var pendingDelete: FirewallRuleModel?
    @State private var pendingOperation: String?
    @State private var pendingFlatAction: String?
    @State private var pendingForwardDelete: FirewallForwardRule?
    @State private var pendingDockerDelete: FirewallDockerPolicy?
    @State private var pendingWhitelistDelete: FirewallWhitelistRule?
    @State private var showForwardForm = false
    @State private var showDockerForm = false
    @State private var whitelistEditor: WhitelistRuleEditor?
    @State private var showBackendForm = false
    @State private var actionError: String?

    var body: some View {
        VStack(spacing: 0) {
            switch section {
            case "ports":
                ruleContent(kind: .port)
            case "ips":
                ruleContent(kind: .ip)
            case "forward":
                forwardContent
            case "docker":
                dockerContent
            case "settings":
                settingsContent
            default:
                statusContent
            }
        }
        .navigationTitle(translations.get("serverModuleFirewall", fallback: "Firewall"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("", selection: $section) {
                    ForEach(Self.sections, id: \.self) { key in
                        Text(sectionTitle(key)).tag(key)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            ToolbarItem(placement: .automatic) {
                if section == "ports" || section == "ips" {
                    Button {
                        editor = FirewallRuleEditor(
                            kind: section == "ports" ? .port : .ip,
                            rule: nil
                        )
                    } label: {
                        Label(translations.get("commonAdd", fallback: "Add"),
                              systemImage: "plus")
                    }
                } else if section == "forward" {
                    Button {
                        showForwardForm = true
                    } label: {
                        Label(translations.get("firewallV2AddForwardRule",
                                               fallback: "Add forward rule"),
                              systemImage: "plus")
                    }
                } else if section == "docker" {
                    Button {
                        showDockerForm = true
                    } label: {
                        Label(translations.get("firewallV2AddDockerPolicy",
                                               fallback: "Add Docker policy"),
                              systemImage: "plus")
                    }
                } else if section == "settings" {
                    Button {
                        whitelistEditor = WhitelistRuleEditor()
                    } label: {
                        Label(translations.get("firewallV2AddWhitelist",
                                               fallback: "Add whitelist rule"),
                              systemImage: "plus")
                    }
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await loadSection() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(rules.isLoading || base.isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .task {
            await loadSection()
        }
        .onChange(of: section) { _ in
            Task { await loadSection() }
        }
        .sheet(item: $editor) { item in
            FirewallRuleEditSheet(kind: item.kind, rule: item.rule) {
                rules.fetchRules(kind: item.kind)
            }
        }
        .sheet(isPresented: $showForwardForm) {
            ForwardRuleFormView(store: v2)
        }
        .sheet(isPresented: $showDockerForm) {
            DockerPolicyFormView(store: v2)
        }
        .sheet(item: $whitelistEditor) { item in
            WhitelistRuleFormView(store: v2, editor: item)
        }
        .sheet(isPresented: $showBackendForm) {
            FirewallBackendFormView(store: v2)
        }
        .confirmationDialog(
            pendingDelete?.originalId ?? "",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let rule = pendingDelete {
                    pendingDelete = nil
                    Task { await rules.deleteRule(rule) }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .confirmationDialog(
            forwardDeleteTitle,
            isPresented: Binding(
                get: { pendingForwardDelete != nil },
                set: { if !$0 { pendingForwardDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await deletePendingForward() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingForwardDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .confirmationDialog(
            dockerDeleteTitle,
            isPresented: Binding(
                get: { pendingDockerDelete != nil },
                set: { if !$0 { pendingDockerDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await deletePendingDocker() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDockerDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .confirmationDialog(
            whitelistDeleteTitle,
            isPresented: Binding(
                get: { pendingWhitelistDelete != nil },
                set: { if !$0 { pendingWhitelistDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await deletePendingWhitelist() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingWhitelistDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage",
                                  fallback: "This action cannot be undone."))
        }
        .confirmationDialog(
            operationTitle(pendingOperation ?? ""),
            isPresented: Binding(
                get: { pendingOperation != nil },
                set: { if !$0 { pendingOperation = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let operation = pendingOperation {
                Button(operationTitle(operation),
                       role: operation == "stop" ? .destructive : nil) {
                    Task { await runOperation(operation) }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingOperation = nil
                }
            }
        } message: {
            Text(operationMessage(pendingOperation ?? ""))
        }
        .confirmationDialog(
            flatActionTitle,
            isPresented: Binding(
                get: { pendingFlatAction != nil },
                set: { if !$0 { pendingFlatAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingFlatAction {
                Button(flatActionTitle) {
                    Task { await runFlatAction(action) }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingFlatAction = nil
                }
            }
        } message: {
            Text(translations.get("firewallV2ConfirmTitle",
                                  fallback: "Confirm the firewall change"))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
    }

    private var statusContent: some View {
        Group {
            if base.isLoading && base.info.name.isEmpty {
                LoadingView()
            } else {
                Form {
                    Section(translations.get("firewallTabStatus", fallback: "Status")) {
                        InfoLine(label: translations.get("firewallNameLabel", fallback: "Name"),
                                 value: base.info.name.isEmpty ? "--" : base.info.name)
                        InfoLine(label: translations.get("firewallVersionLabel", fallback: "Version"),
                                 value: base.info.version.isEmpty ? "--" : base.info.version)
                        InfoLine(label: translations.get("firewallActiveLabel", fallback: "Active"),
                                 value: boolText(base.info.isActive))
                        InfoLine(label: translations.get("firewallInitLabel", fallback: "Initialized"),
                                 value: boolText(base.info.isInit))
                        InfoLine(label: translations.get("firewallBoundLabel", fallback: "Bound"),
                                 value: boolText(base.info.isBound))
                    }
                    Section(translations.get("firewallTabRules", fallback: "Rules")) {
                        HStack(spacing: 12) {
                            Button(translations.get("commonStart", fallback: "Start")) {
                                pendingOperation = "start"
                            }
                            Button(translations.get("commonStop", fallback: "Stop")) {
                                pendingOperation = "stop"
                            }
                            Button(translations.get("commonRestart", fallback: "Restart")) {
                                pendingOperation = "restart"
                            }
                        }
                        .disabled(base.isLoading)
                    }
                }
                .formStyle(.grouped)
            }
        }
    }

    private func ruleContent(kind: FirewallRuleKind) -> some View {
        Group {
            if rules.isLoading && rules.rules.isEmpty {
                LoadingView()
            } else if rules.hasLoadError && rules.rules.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle",
                                                     fallback: "Failed to load")) {
                    rules.fetchRules(kind: kind)
                }
            } else if rules.rules.isEmpty {
                EmptyStateView(
                    icon: "shield.lefthalf.filled",
                    message: kind == .port
                        ? translations.get("firewallPortsEmptyTitle", fallback: "No port rules")
                        : translations.get("firewallIpsEmptyTitle", fallback: "No IP rules")
                )
            } else {
                List {
                    Section(translations.get(
                        kind == .port ? "firewallTabPorts" : "firewallTabIps",
                        fallback: kind == .port ? "Ports" : "IPs"
                    )) {
                        ForEach(rules.rules) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(kind == .port
                                             ? "\(rule.port)/\(rule.protocolType)"
                                             : rule.address)
                                            .font(.subheadline.weight(.medium))
                                        StatusBadge(
                                            text: rule.strategy.isEmpty ? "--" : rule.strategy,
                                            color: rule.strategy == "accept" ? .green : .red
                                        )
                                    }
                                    if kind == .port, !rule.address.isEmpty {
                                        Text(rule.address)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !rule.description.isEmpty {
                                        Text(rule.description)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Menu {
                                    if rule.supportsLegacyChanges {
                                        Button {
                                            editor = FirewallRuleEditor(kind: kind, rule: rule)
                                        } label: {
                                            Label(translations.get("commonEdit", fallback: "Edit"),
                                                  systemImage: "pencil")
                                        }
                                    }
                                    if rule.deletionArguments != nil {
                                        Button(role: .destructive) {
                                            pendingDelete = rule
                                        } label: {
                                            Label(translations.get("commonDelete", fallback: "Delete"),
                                                  systemImage: "trash")
                                        }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 24)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    rules.fetchRules(kind: kind)
                }
            }
        }
    }

    private var forwardContent: some View {
        Group {
            if v2.isLoading && v2.forwardInfo.isEmpty && v2.forwardRules.isEmpty {
                LoadingView()
            } else if let error = v2.loadError,
                      v2.forwardInfo.isEmpty, v2.forwardRules.isEmpty {
                ErrorView(message: error) {
                    Task { await v2.loadForward() }
                }
            } else {
                List {
                    Section(sectionTitle(section)) {
                        Button {
                            pendingFlatAction = "forward"
                        } label: {
                            Label(translations.get("firewallV2EnableForwardAction",
                                                   fallback: "Enable forwarding"),
                                  systemImage: "arrow.left.arrow.right")
                        }
                        ForEach(v2.forwardInfo) { row in
                            infoRow(row)
                        }
                    }
                    Section(translations.get("firewallV2ForwardRules",
                                             fallback: "Forwarding rules")) {
                        if v2.forwardRules.isEmpty {
                            Text(translations.get("firewallV2Empty", fallback: "No records"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(v2.forwardRules) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(rule.sourceText)
                                            .font(.subheadline.weight(.medium))
                                        StatusBadge(
                                            text: rule.strategy.isEmpty ? "--" : rule.strategy,
                                            color: rule.strategy == "accept" ? .green : .red
                                        )
                                    }
                                    Text("→ \(rule.targetText)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !rule.description.isEmpty {
                                        Text(rule.description)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Menu {
                                    Button(role: .destructive) {
                                        pendingForwardDelete = rule
                                    } label: {
                                        Label(translations.get("commonDelete", fallback: "Delete"),
                                              systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 24)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await v2.loadForward()
                }
            }
        }
    }

    private var dockerContent: some View {
        Group {
            if v2.isLoading && v2.dockerInfo.isEmpty && v2.dockerPolicies.isEmpty {
                LoadingView()
            } else if let error = v2.loadError,
                      v2.dockerInfo.isEmpty, v2.dockerPolicies.isEmpty {
                ErrorView(message: error) {
                    Task { await v2.loadDocker() }
                }
            } else {
                List {
                    Section(sectionTitle(section)) {
                        Menu {
                            Button(translations.get("firewallV2DockerInitializeAction",
                                                    fallback: "Initialize")) {
                                pendingFlatAction = "docker:initialize"
                            }
                            Button(translations.get("firewallV2DockerBindAction",
                                                    fallback: "Bind")) {
                                pendingFlatAction = "docker:bind"
                            }
                            Button(translations.get("firewallV2DockerUnbindAction",
                                                    fallback: "Unbind")) {
                                pendingFlatAction = "docker:unbind"
                            }
                        } label: {
                            Label(translations.get("firewallV2DockerActionLabel",
                                                   fallback: "Docker guard action"),
                                  systemImage: "shield.lefthalf.filled")
                        }
                        ForEach(v2.dockerInfo) { row in
                            infoRow(row)
                        }
                    }
                    Section(translations.get("firewallV2DockerPolicies",
                                             fallback: "Docker policies")) {
                        if v2.dockerPolicies.isEmpty {
                            Text(translations.get("firewallV2Empty", fallback: "No records"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(v2.dockerPolicies) { policy in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(policy.hostText)
                                            .font(.subheadline.weight(.medium))
                                        StatusBadge(
                                            text: policy.mode.isEmpty ? "--" : policy.mode,
                                            color: policy.mode.contains("deny") ? .red : .green
                                        )
                                    }
                                    if !policy.containerName.isEmpty {
                                        Text(policy.containerName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !policy.sources.isEmpty {
                                        Text(policy.sources.joined(separator: ", "))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Menu {
                                    Button(role: .destructive) {
                                        pendingDockerDelete = policy
                                    } label: {
                                        Label(translations.get("commonDelete", fallback: "Delete"),
                                              systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 24)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    if !v2.publishedPorts.isEmpty {
                        Section(translations.get("firewallV2PublishedPorts",
                                                 fallback: "Published ports")) {
                            ForEach(v2.publishedPorts) { port in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(port.portText)
                                        .font(.subheadline)
                                    Text(port.containerName.isEmpty
                                         ? port.containerState
                                         : "\(port.containerName) · \(port.containerState)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await v2.loadDocker()
                }
            }
        }
    }

    private var settingsContent: some View {
        Group {
            if v2.isLoading && v2.settingsInfo.isEmpty && v2.whitelist.isEmpty {
                LoadingView()
            } else if let error = v2.loadError,
                      v2.settingsInfo.isEmpty, v2.whitelist.isEmpty {
                ErrorView(message: error) {
                    Task { await v2.loadSettings() }
                }
            } else {
                List {
                    Section(sectionTitle(section)) {
                        Toggle(
                            translations.get("firewallV2IPv6Enable", fallback: "Enable IPv6"),
                            isOn: Binding(
                                get: { v2.ipv6Enabled },
                                set: { value in
                                    pendingFlatAction = value ? "ipv6:true" : "ipv6:false"
                                }
                            )
                        )
                        Button {
                            showBackendForm = true
                        } label: {
                            Label(translations.get("firewallV2SwitchBackend",
                                                   fallback: "Switch backend"),
                                  systemImage: "arrow.triangle.2.circlepath")
                        }
                        ForEach(v2.settingsInfo) { row in
                            infoRow(row)
                        }
                    }
                    Section(translations.get("firewallV2Whitelist",
                                             fallback: "Port whitelist")) {
                        if v2.whitelist.isEmpty {
                            Text(translations.get("firewallV2Empty", fallback: "No records"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(v2.whitelist) { rule in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(rule.port)/\(rule.protocolName)")
                                        .font(.subheadline.weight(.medium))
                                    if !rule.type.isEmpty {
                                        Text(rule.type)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Text(rule.sourcesText)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Menu {
                                    Button {
                                        whitelistEditor = WhitelistRuleEditor(rule: rule)
                                    } label: {
                                        Label(translations.get("commonEdit", fallback: "Edit"),
                                              systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        pendingWhitelistDelete = rule
                                    } label: {
                                        Label(translations.get("commonDelete", fallback: "Delete"),
                                              systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 24)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await v2.loadSettings()
                }
            }
        }
    }

    private func infoRow(_ row: FirewallInfoRow) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(row.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(row.value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private var flatActionTitle: String {
        guard let action = pendingFlatAction else { return "" }
        if action.hasPrefix("ipv6:") {
            return translations.get("firewallV2IPv6Enable", fallback: "Enable IPv6")
        }
        if action == "forward" {
            return translations.get("firewallV2EnableForwardAction",
                                    fallback: "Enable forwarding")
        }
        if action.hasPrefix("docker:") {
            switch action.replacingOccurrences(of: "docker:", with: "") {
            case "initialize":
                return translations.get("firewallV2DockerInitializeAction",
                                        fallback: "Initialize")
            case "bind":
                return translations.get("firewallV2DockerBindAction", fallback: "Bind")
            default:
                return translations.get("firewallV2DockerUnbindAction", fallback: "Unbind")
            }
        }
        return action
    }

    private var forwardDeleteTitle: String {
        guard let rule = pendingForwardDelete else { return "" }
        return "\(rule.sourceText) → \(rule.targetText)"
    }

    private var dockerDeleteTitle: String {
        guard let policy = pendingDockerDelete else { return "" }
        return policy.containerName.isEmpty
            ? policy.hostText
            : "\(policy.containerName) · \(policy.hostText)"
    }

    private var whitelistDeleteTitle: String {
        guard let rule = pendingWhitelistDelete else { return "" }
        return "\(rule.port)/\(rule.protocolName)"
    }

    private func deletePendingForward() async {
        guard let rule = pendingForwardDelete else { return }
        pendingForwardDelete = nil
        do {
            try await v2.removeForwardRule(rule)
        } catch {
            actionError = actionMessage(error)
        }
    }

    private func deletePendingDocker() async {
        guard let policy = pendingDockerDelete else { return }
        pendingDockerDelete = nil
        do {
            try await v2.deleteDockerPolicy(policy)
        } catch {
            actionError = actionMessage(error)
        }
    }

    private func deletePendingWhitelist() async {
        guard let rule = pendingWhitelistDelete else { return }
        pendingWhitelistDelete = nil
        do {
            try await v2.deleteWhitelist(rule)
        } catch {
            actionError = actionMessage(error)
        }
    }

    private func actionMessage(_ error: Error) -> String {
        if let message = (error as? FirewallV2ActionError)?.errorDescription,
           !message.isEmpty {
            return message
        }
        return translations.get("commonOperationFailed", fallback: "Operation failed")
    }

    private func runFlatAction(_ action: String) async {
        pendingFlatAction = nil
        let method: String
        let arguments: [String: Any]
        if action.hasPrefix("ipv6:") {
            method = "updateFirewallIPv6"
            arguments = ["enabled": action.hasSuffix("true")]
        } else if action == "forward" {
            method = "enableFirewallForward"
            arguments = [:]
        } else {
            method = "operateFirewallDockerGuard"
            arguments = ["operation": action.replacingOccurrences(of: "docker:", with: "")]
        }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await loadSection()
            } else {
                actionError = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func loadSection() async {
        switch section {
        case "ports":
            rules.fetchRules(kind: .port)
        case "ips":
            rules.fetchRules(kind: .ip)
        case "forward":
            await v2.loadForward()
        case "docker":
            await v2.loadDocker()
        case "settings":
            await v2.loadSettings()
        default:
            await base.fetch()
        }
    }

    private func runOperation(_ operation: String) async {
        pendingOperation = nil
        if let error = await base.operate(operation) {
            actionError = error
        }
    }

    private func boolText(_ value: Bool) -> String {
        value
            ? translations.get("commonYes", fallback: "Yes")
            : translations.get("commonNo", fallback: "No")
    }

    private func operationTitle(_ operation: String) -> String {
        switch operation {
        case "start": return translations.get("commonStart", fallback: "Start")
        case "stop": return translations.get("commonStop", fallback: "Stop")
        case "restart": return translations.get("commonRestart", fallback: "Restart")
        default: return operation
        }
    }

    private func operationMessage(_ operation: String) -> String {
        switch operation {
        case "start":
            return translations.get("firewallStartConfirmMessage",
                                    fallback: "Start the firewall service?")
        case "stop":
            return translations.get("firewallStopConfirmMessage",
                                    fallback: "Stop the firewall service? Connections may be interrupted.")
        case "restart":
            return translations.get("firewallRestartConfirmMessage",
                                    fallback: "Restart the firewall service?")
        default:
            return translations.get("firewallOperationConfirmTitle",
                                    fallback: "Firewall operation")
        }
    }

    private func sectionTitle(_ key: String) -> String {
        switch key {
        case "status": return translations.get("firewallTabStatus", fallback: "Status")
        case "ports": return translations.get("firewallTabPorts", fallback: "Ports")
        case "ips": return translations.get("firewallTabIps", fallback: "IPs")
        case "forward": return translations.get("firewallV2Forward", fallback: "Forward")
        case "docker": return translations.get("firewallV2Docker", fallback: "Docker")
        case "settings": return translations.get("firewallV2Settings", fallback: "Settings")
        default: return key
        }
    }

    private static let sections = ["status", "ports", "ips", "forward", "docker", "settings"]
}

struct FirewallRuleEditor: Identifiable {
    let id = UUID()
    let kind: FirewallRuleKind
    let rule: FirewallRuleModel?
}