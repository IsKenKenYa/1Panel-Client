import AppleSharedUI
import SwiftUI

@MainActor
final class FirewallRuleListModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch(kind: FirewallRuleKind) async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                kind == .port ? "getFirewallRules" : "getFirewallIpRules"
            )
            rules = (raw as? [[String: Any]] ?? []).compactMap(FirewallRuleModel.init(payload:))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ rule: FirewallRuleModel) async -> String? {
        guard let arguments = rule.deletionArguments else { return nil }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteFirewallRule",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                return nil
            }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

@MainActor
final class FirewallBaseModel: ObservableObject {
    @Published var name = ""
    @Published var isExist = false
    @Published var isActive = false
    @Published var isInit = false
    @Published var isBound = false
    @Published var version = ""
    @Published var pingStatus = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getFirewallBaseInfo"
            )
            let payload = raw as? [String: Any] ?? [:]
            name = payload["name"] as? String ?? ""
            isExist = payload["isExist"] as? Bool ?? false
            isActive = payload["isActive"] as? Bool ?? false
            isInit = payload["isInit"] as? Bool ?? false
            isBound = payload["isBind"] as? Bool ?? false
            version = payload["version"] as? String ?? ""
            pingStatus = payload["pingStatus"] as? String ?? ""
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
final class FirewallFlatModel: ObservableObject {
    @Published var values: [FirewallFlatRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch(method: String) async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(method)
            let payload = raw as? [String: Any] ?? [:]
            values = payload
                .map { FirewallFlatRow(label: $0.key, value: "\($0.value)") }
                .sorted { $0.label < $1.label }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// iOS 防火墙：状态、端口规则、IP 规则、转发、Docker 与设置。
struct FirewallModuleView: View {
    @StateObject private var portRules = FirewallRuleListModel()
    @StateObject private var ipRules = FirewallRuleListModel()
    @StateObject private var base = FirewallBaseModel()
    @StateObject private var forward = FirewallFlatModel()
    @StateObject private var docker = FirewallFlatModel()
    @StateObject private var settings = FirewallFlatModel()

    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = ProcessInfo.processInfo.environment["ONEPANEL_FIREWALL_TAB"]
        ?? "status"
    @State private var editor: FirewallRuleEditor?
    @State private var pendingDelete: FirewallRuleModel?
    @State private var pendingOperation: String?
    @State private var toastText: String?
    @State private var hasLoaded = false

    var body: some View {
        Group {
            switch section {
            case "ports":
                rulesContent(kind: .port, model: portRules)
            case "ips":
                rulesContent(kind: .ip, model: ipRules)
            case "forward":
                flatContent(model: forward)
            case "docker":
                flatContent(model: docker)
            case "settings":
                flatContent(model: settings)
            default:
                statusContent
            }
        }
        .navigationTitle(translations.get("serverModuleFirewall", fallback: "Firewall"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(Self.sections, id: \.key) { item in
                        Button {
                            section = item.key
                            Task { await loadSection() }
                        } label: {
                            if section == item.key {
                                Label(sectionTitle(item.key), systemImage: "checkmark")
                            } else {
                                Text(sectionTitle(item.key))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sectionTitle(section))
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityIdentifier("firewall-section-menu")
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
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
                Button {
                    Task { await loadSection() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                ModuleSwitcherMenu(current: .firewall)
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await loadSection()
        }
        .sheet(item: $editor) { item in
            FirewallRuleFormSheet(kind: item.kind, rule: item.rule) {
                Task { await loadSection() }
            }
        }
        .confirmationDialog(
            pendingDelete?.id ?? "",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await deletePending() }
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
        .operationNotice(toastText)
    }

    private var statusContent: some View {
        Group {
            if base.isLoading && base.name.isEmpty {
                LoadingView()
            } else if let error = base.errorMessage, base.name.isEmpty {
                ErrorView(message: error) {
                    Task { await base.fetch() }
                }
            } else {
                List {
                    Section(translations.get("firewallTabStatus", fallback: "Status")) {
                        InfoLine(label: translations.get("firewallNameLabel", fallback: "Name"),
                                 value: base.name.isEmpty ? "--" : base.name)
                        InfoLine(label: translations.get("firewallVersionLabel", fallback: "Version"),
                                 value: base.version.isEmpty ? "--" : base.version)
                        InfoLine(label: translations.get("firewallActiveLabel", fallback: "Active"),
                                 value: boolText(base.isActive))
                        InfoLine(label: translations.get("firewallInitLabel", fallback: "Initialized"),
                                 value: boolText(base.isInit))
                        InfoLine(label: translations.get("firewallBoundLabel", fallback: "Bound"),
                                 value: boolText(base.isBound))
                    }
                    Section(translations.get("firewallTabRules", fallback: "Rules")) {
                        Button {
                            pendingOperation = "start"
                        } label: {
                            Label(translations.get("commonStart", fallback: "Start"),
                                  systemImage: "play.fill")
                        }
                        Button {
                            pendingOperation = "stop"
                        } label: {
                            Label(translations.get("commonStop", fallback: "Stop"),
                                  systemImage: "stop.fill")
                        }
                        Button {
                            pendingOperation = "restart"
                        } label: {
                            Label(translations.get("commonRestart", fallback: "Restart"),
                                  systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(base.isLoading)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await base.fetch()
                }
            }
        }
    }

    private func rulesContent(kind: FirewallRuleKind, model: FirewallRuleListModel) -> some View {
        Group {
            if model.isLoading && model.rules.isEmpty {
                LoadingView()
            } else if let error = model.errorMessage, model.rules.isEmpty {
                ErrorView(message: error) {
                    Task { await model.fetch(kind: kind) }
                }
            } else if model.rules.isEmpty {
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
                        ForEach(model.rules) { rule in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(kind == .port
                                         ? "\(rule.port)/\(rule.protocolName)"
                                         : rule.address)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
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
                            .padding(.vertical, 2)
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                if rule.supportsLegacyChanges {
                                    Button {
                                        editor = FirewallRuleEditor(kind: kind, rule: rule)
                                    } label: {
                                        Label(translations.get("commonEdit", fallback: "Edit"),
                                              systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if rule.deletionArguments != nil {
                                    Button(role: .destructive) {
                                        pendingDelete = rule
                                    } label: {
                                        Label(translations.get("commonDelete", fallback: "Delete"),
                                              systemImage: "trash")
                                    }
                                }
                            }
                            .contextMenu {
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
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await model.fetch(kind: kind)
                }
            }
        }
    }

    private func flatContent(model: FirewallFlatModel) -> some View {
        Group {
            if model.isLoading && model.values.isEmpty {
                LoadingView()
            } else if let error = model.errorMessage, model.values.isEmpty {
                ErrorView(message: error) {
                    Task { await loadSection() }
                }
            } else if model.values.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("firewallV2Empty", fallback: "No data")
                )
            } else {
                List {
                    Section(sectionTitle(section)) {
                        ForEach(model.values) { item in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(item.value)
                                    .font(.subheadline)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await loadSection()
                }
            }
        }
    }

    private func loadSection() async {
        switch section {
        case "ports":
            await portRules.fetch(kind: .port)
        case "ips":
            await ipRules.fetch(kind: .ip)
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

    private func deletePending() async {
        guard let rule = pendingDelete else { return }
        pendingDelete = nil
        let model = section == "ips" ? ipRules : portRules
        if let error = await model.delete(rule) {
            showToast(error)
        } else {
            await model.fetch(kind: section == "ips" ? .ip : .port)
            showToast(translations.get("commonDeleted", fallback: "Deleted"))
        }
    }

    private func runOperation(_ operation: String) async {
        pendingOperation = nil
        if let error = await base.operate(operation) {
            showToast(error)
        } else {
            showToast(translations.get("commonOperationSuccess", fallback: "Operation succeeded"))
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

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }

    private static let sections: [(key: String, title: String)] = [
        ("status", ""),
        ("ports", ""),
        ("ips", ""),
        ("forward", ""),
        ("docker", ""),
        ("settings", ""),
    ]
}

struct FirewallRuleEditor: Identifiable {
    let id = UUID()
    let kind: FirewallRuleKind
    let rule: FirewallRuleModel?
}