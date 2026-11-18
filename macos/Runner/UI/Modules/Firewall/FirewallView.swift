import SwiftUI

struct FirewallView: View {
    @StateObject private var viewModel = FirewallViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var showAddSheet = false
    @State private var ruleToDelete: FirewallRuleModel?

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.rules.isEmpty {
                LoadingView()
            } else if viewModel.hasLoadError && viewModel.rules.isEmpty {
                ErrorView(
                    message: translations.get("commonLoadFailedTitle", fallback: "Failed to load firewall rules"),
                    onRetry: viewModel.fetchRules
                )
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
                            if rule.deletionArguments != nil && !viewModel.isLoading && !viewModel.isProcessing {
                                Button(role: .destructive) {
                                    ruleToDelete = rule
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                                }
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
                    .disabled(viewModel.isLoading)
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help(translations.get("firewallCreatePortRuleAction", fallback: "Add Rule"))
                .disabled(viewModel.isProcessing)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddFirewallRuleSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { ruleToDelete != nil },
                set: { if !$0 { ruleToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: ruleToDelete
        ) { rule in
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await viewModel.deleteRule(rule) }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { rule in
            let endpoint = [rule.port, rule.protocolType].filter { !$0.isEmpty }.joined(separator: "/")
            let source = rule.address.isEmpty
                ? translations.get("firewallSourceAnywhere", fallback: "Anywhere") : rule.address
            let target = [endpoint, source, rule.family, rule.chain, rule.strategy, rule.description]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            Text("\(target)\n\(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))")
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
    let viewModel: FirewallViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var port = ""
    @State private var proto = "tcp"
    @State private var address = ""
    @State private var strategy = "accept"
    @State private var submission = NativeFormSubmission.idle

    private let protocols = ["tcp", "udp", "tcp/udp"]
    private var trimmedPort: String { port.trimmingCharacters(in: .whitespacesAndNewlines) }

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
                    Text(translations.get("firewallStrategyAccept", fallback: "Accept")).tag("accept")
                    Text(translations.get("firewallStrategyDrop", fallback: "Drop")).tag("drop")
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)
            .disabled(submission.isSubmitting)

            NativeFormSubmissionFeedback(
                submission: submission,
                errorFallback: translations.get("commonOperationFailed", fallback: "Operation failed")
            )

            HStack {
                Spacer()
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(submission.isSubmitting)
                Button(translations.get("commonAdd", fallback: "Add"), action: submit)
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmedPort.isEmpty || submission.isSubmitting)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 440)
        .interactiveDismissDisabled(submission.isSubmitting)
    }

    private func submit() {
        let port = trimmedPort
        guard !port.isEmpty, submission.begin() else { return }
        let proto = proto
        let address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let strategy = strategy
        Task {
            let outcome = await viewModel.addRule(port: port, protocol: proto, address: address, strategy: strategy)
            if submission.finish(outcome) {
                dismiss()
            }
        }
    }
}
