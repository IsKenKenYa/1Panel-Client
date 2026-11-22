import SwiftUI

/// macOS 防火墙规则创建与编辑表单。
struct FirewallRuleEditSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let kind: FirewallRuleKind
    let rule: FirewallRuleModel?
    let onSaved: () -> Void

    @State private var selectedKind: FirewallRuleKind
    @State private var port: String
    @State private var protocolName: String
    @State private var address: String
    @State private var strategy: String
    @State private var description: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(kind: FirewallRuleKind,
         rule: FirewallRuleModel?,
         onSaved: @escaping () -> Void) {
        self.kind = kind
        self.rule = rule
        self.onSaved = onSaved
        _selectedKind = State(initialValue: kind)
        _port = State(initialValue: rule?.port ?? "")
        _protocolName = State(initialValue: rule?.protocolType.isEmpty == false
                              ? rule!.protocolType : "tcp")
        _address = State(initialValue: rule?.address ?? "")
        _strategy = State(initialValue: rule?.strategy.isEmpty == false
                          ? rule!.strategy : "accept")
        _description = State(initialValue: rule?.description ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                if rule == nil {
                    Picker(translations.get("firewallRuleKindLabel", fallback: "Rule type"),
                           selection: $selectedKind) {
                        Text(translations.get("firewallTabPorts", fallback: "Port"))
                            .tag(FirewallRuleKind.port)
                        Text(translations.get("firewallTabIps", fallback: "IP"))
                            .tag(FirewallRuleKind.ip)
                    }
                    .pickerStyle(.segmented)
                }
                if selectedKind == .port {
                    TextField(translations.get("firewallPortLabel", fallback: "Port"),
                              text: $port)
                    Picker(translations.get("firewallProtocolLabel", fallback: "Protocol"),
                           selection: $protocolName) {
                        Text("TCP").tag("tcp")
                        Text("UDP").tag("udp")
                    }
                }
                TextField(translations.get("firewallAddressLabel", fallback: "Address"),
                          text: $address)
                Picker(translations.get("firewallStrategyLabel", fallback: "Strategy"),
                       selection: $strategy) {
                    Text(translations.get("firewallStrategyAccept", fallback: "Accept"))
                        .tag("accept")
                    Text(translations.get("firewallStrategyDrop", fallback: "Drop"))
                        .tag("drop")
                }
                TextField(translations.get("firewallDescriptionLabel", fallback: "Description"),
                          text: $description)
            }
            .formStyle(.grouped)
            .navigationTitle(rule == nil
                             ? translations.get("firewallCreateRuleAction", fallback: "Create Rule")
                             : translations.get("commonEdit", fallback: "Edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || !canSave)
                }
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
            .frame(minWidth: 480, minHeight: 360)
        }
    }

    private var canSave: Bool {
        switch selectedKind {
        case .port: return !port.trimmingCharacters(in: .whitespaces).isEmpty
        case .ip: return !address.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let name = port.trimmingCharacters(in: .whitespacesAndNewlines)
        let addr = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = description.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let method: String
            let arguments: [String: Any]
            if let rule {
                let oldRule: [String: Any]
                let newRule: [String: Any]
                if selectedKind == .port {
                    oldRule = [
                        "operation": "edit",
                        "address": rule.address,
                        "port": rule.port,
                        "source": rule.address.isEmpty ? "anyWhere" : "address",
                        "protocol": rule.protocolType,
                        "strategy": rule.strategy,
                        "description": rule.description,
                        "chain": rule.chain,
                    ]
                    newRule = [
                        "operation": "edit",
                        "address": addr,
                        "port": name,
                        "source": addr.isEmpty ? "anyWhere" : "address",
                        "protocol": protocolName,
                        "strategy": strategy,
                        "description": note,
                        "chain": rule.chain,
                    ]
                    method = "updateFirewallPortRule"
                } else {
                    oldRule = [
                        "operation": "edit",
                        "address": rule.address,
                        "strategy": rule.strategy,
                        "description": rule.description,
                    ]
                    newRule = [
                        "operation": "edit",
                        "address": addr,
                        "strategy": strategy,
                        "description": note,
                    ]
                    method = "updateFirewallIpRule"
                }
                arguments = ["oldRule": oldRule, "newRule": newRule]
            } else {
                method = "addFirewallRule"
                arguments = [
                    "port": selectedKind == .port ? name : "",
                    "protocol": protocolName,
                    "address": addr,
                    "strategy": strategy,
                    "description": note,
                ]
            }
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onSaved()
                dismiss()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}