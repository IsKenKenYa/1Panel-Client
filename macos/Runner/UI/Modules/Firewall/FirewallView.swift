import SwiftUI

struct FirewallView: View {
    @StateObject private var viewModel = FirewallViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var showAddSheet = false
    @State private var ruleToDelete: FirewallRuleModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.rules.isEmpty {
                EmptyStateView(
                    icon: "network.badge.shield.half.filled",
                    message: translations.get("firewallRulesEmptyTitle", fallback: "No firewall rules")
                )
            } else {
                Table(viewModel.rules) {
                    TableColumn(translations.get("firewallPortLabel", fallback: "Port")) { rule in
                        HStack {
                            Image(systemName: "network.badge.shield.half.filled")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(rule.port.isEmpty ? "--" : rule.port)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                ruleToDelete = rule
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("firewallProtocolLabel", fallback: "Protocol")) { rule in
                        Text(rule.protocolType.isEmpty ? "--" : rule.protocolType.uppercased())
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("firewallAddressLabel", fallback: "Address")) { rule in
                        Text(rule.address.isEmpty ? "--" : rule.address)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("firewallStrategyLabel", fallback: "Action")) { rule in
                        let isAllow = rule.strategy.lowercased() == "allow" || rule.strategy.lowercased() == "accept"
                        Text(rule.strategy.isEmpty ? "--" : rule.strategy)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isAllow ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                            .foregroundColor(isAllow ? .green : .red)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleFirewall", fallback: "Firewall"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchRules() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help(translations.get("firewallCreatePortRuleAction", fallback: "Add Rule"))
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFirewallRuleSheet(isPresented: $showAddSheet) { port, proto, address, strategy in
                Task { await viewModel.addRule(port: port, protocol: proto, address: address, strategy: strategy) }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete rule for \"\(ruleToDelete?.port ?? ruleToDelete?.address ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let r = ruleToDelete { Task { await viewModel.deleteRule(r) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchRules() }
    }
}

// ── Add Rule Sheet ────────────────────────────────────────────────────────────

struct AddFirewallRuleSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String, String, String) -> Void
    @EnvironmentObject var translations: TranslationsManager

    @State private var port = ""
    @State private var proto = "tcp"
    @State private var address = ""
    @State private var strategy = "accept"

    private let protocols = ["tcp", "udp", "tcp/udp"]
    private let strategies = ["accept", "drop"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(translations.get("firewallCreatePortRuleAction", fallback: "Add Firewall Rule"))
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField(translations.get("firewallPortRequired", fallback: "Port (e.g. 80, 8080-9090)"), text: $port)
                    .autocorrectionDisabled()
                Picker(translations.get("firewallProtocolLabel", fallback: "Protocol"), selection: $proto) {
                    ForEach(protocols, id: \.self) { Text($0.uppercased()) }
                }
                .pickerStyle(.segmented)
                TextField(translations.get("firewallAddressRequired", fallback: "Source Address (optional)"), text: $address)
                    .autocorrectionDisabled()
                Picker(translations.get("firewallStrategyLabel", fallback: "Action"), selection: $strategy) {
                    Text("Accept").tag("accept")
                    Text("Drop").tag("drop")
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(translations.get("commonAdd", fallback: "Add")) {
                    onAdd(port, proto, address, strategy)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(port.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}
