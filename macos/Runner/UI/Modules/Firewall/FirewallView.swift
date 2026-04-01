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
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.rules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "network.badge.shield.half.filled")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(translations.get("noFirewallRules", fallback: "No firewall rules"))
                        .foregroundColor(.secondary)
                    Button(translations.get("addRule", fallback: "Add Rule")) {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.rules) {
                    TableColumn(translations.get("firewall_port", fallback: "Port")) { rule in
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
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("firewall_protocol", fallback: "Protocol")) { rule in
                        Text(rule.protocolType.isEmpty ? "--" : rule.protocolType.uppercased())
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("firewall_address", fallback: "Address")) { rule in
                        Text(rule.address.isEmpty ? "--" : rule.address)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("firewall_action", fallback: "Action")) { rule in
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
                    .help("Refresh")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help("Add Rule")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFirewallRuleSheet(isPresented: $showAddSheet) { port, proto, address, strategy in
                Task { await viewModel.addRule(port: port, protocol: proto, address: address, strategy: strategy) }
            }
        }
        .confirmationDialog(
            "Delete rule for \"\(ruleToDelete?.port ?? ruleToDelete?.address ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let r = ruleToDelete { Task { await viewModel.deleteRule(r) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
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

    @State private var port = ""
    @State private var proto = "tcp"
    @State private var address = ""
    @State private var strategy = "accept"

    private let protocols = ["tcp", "udp", "tcp/udp"]
    private let strategies = ["accept", "drop"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Firewall Rule")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Port (e.g. 80, 8080-9090)", text: $port)
                    .autocorrectionDisabled()
                Picker("Protocol", selection: $proto) {
                    ForEach(protocols, id: \.self) { Text($0.uppercased()) }
                }
                .pickerStyle(.segmented)
                TextField("Source Address (optional)", text: $address)
                    .autocorrectionDisabled()
                Picker("Action", selection: $strategy) {
                    Text("Accept").tag("accept")
                    Text("Drop").tag("drop")
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
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
