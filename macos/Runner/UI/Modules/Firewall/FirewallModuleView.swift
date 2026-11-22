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

struct FirewallFlatRow: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}

@MainActor
final class FirewallFlatStore: ObservableObject {
    @Published var rows: [FirewallFlatRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch(method: String) async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(method)
            let payload = raw as? [String: Any] ?? [:]
            rows = payload
                .map { FirewallFlatRow(label: $0.key, value: "\($0.value)") }
                .sorted { $0.label < $1.label }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// macOS 防火墙：状态、端口规则、IP 规则、转发、Docker 与设置。
struct FirewallModuleView: View {
    @StateObject private var rules = FirewallViewModel()
    @StateObject private var base = FirewallBaseStore()
    @StateObject private var forward = FirewallFlatStore()
    @StateObject private var docker = FirewallFlatStore()
    @StateObject private var settings = FirewallFlatStore()

    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = ProcessInfo.processInfo.environment["ONEPANEL_FIREWALL_TAB"]
        ?? "status"
    @State private var editor: FirewallRuleEditor?
    @State private var pendingDelete: FirewallRuleModel?
    @State private var pendingOperation: String?
    @State private var actionError: String?

    var body: some View {
        VStack(spacing: 0) {
            switch section {
            case "ports":
                ruleContent(kind: .port)
            case "ips":
                ruleContent(kind: .ip)
            case "forward":
                flatContent(forward)
            case "docker":
                flatContent(docker)
            case "settings":
                flatContent(settings)
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

    private func flatContent(_ store: FirewallFlatStore) -> some View {
        Group {
            if store.isLoading && store.rows.isEmpty {
                LoadingView()
            } else if let error = store.errorMessage, store.rows.isEmpty {
                ErrorView(message: error) {
                    Task { await loadSection() }
                }
            } else if store.rows.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("firewallV2Empty", fallback: "No data")
                )
            } else {
                List {
                    Section(sectionTitle(section)) {
                        ForEach(store.rows) { row in
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
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await loadSection()
                }
            }
        }
    }

    private func loadSection() async {
        switch section {
        case "ports":
            rules.fetchRules(kind: .port)
        case "ips":
            rules.fetchRules(kind: .ip)
        case "forward":
            await forward.fetch(method: "getFirewallV2Forward")
        case "docker":
            await docker.fetch(method: "getFirewallV2Docker")
        case "settings":
            await settings.fetch(method: "getFirewallV2Settings")
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