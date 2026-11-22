import SwiftUI
import AppleSharedUI

struct FirewallRuleModel: Identifiable {
    let id: String
    let protocolName: String
    let port: String
    let address: String
    let strategy: String
    let description: String
    let family: String
    let chain: String
    let supportsLegacyChanges: Bool
    let serverId: String?
    let inventoryId: String?
    let canDelete: Bool?

    init?(payload: [String: Any]) {
        let rawId = payload["id"]
        guard let id = rawId as? String ?? (rawId as? Int).map(String.init) else { return nil }
        self.id = id
        protocolName = payload["protocol"] as? String ?? ""
        port = payload["port"] as? String ?? ""
        address = payload["address"] as? String ?? ""
        strategy = payload["strategy"] as? String ?? ""
        description = payload["description"] as? String ?? ""
        family = payload["family"] as? String ?? ""
        chain = payload["chain"] as? String ?? ""
        supportsLegacyChanges = payload["supportsLegacyChanges"] as? Bool == true
        serverId = payload["serverId"] as? String
        inventoryId = payload["inventoryId"] as? String
        canDelete = payload["canDelete"] as? Bool
    }

    var deletionArguments: [String: String]? {
        if let inventoryId {
            guard canDelete == true, !inventoryId.isEmpty, let serverId, !serverId.isEmpty else { return nil }
            return ["inventoryId": inventoryId, "serverId": serverId]
        }
        guard supportsLegacyChanges, canDelete != false else { return nil }
        var args = ["port": port, "protocol": protocolName, "strategy": strategy, "address": address]
        if let serverId { args["serverId"] = serverId }
        return args
    }
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    @Published var hasLoadError = false
    @Published private(set) var isDeleting = false

    func fetch() {
        guard !isLoading, !isDeleting else { return }
        isLoading = true
        hasLoadError = false
        ChannelManager.shared.invokeDataMethod("getFirewallRules") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else {
                    self?.hasLoadError = true
                    return
                }
                self?.rules = items.compactMap(FirewallRuleModel.init(payload:))
            }
        }
    }

    func delete(rule: FirewallRuleModel, completion: @escaping (Bool, String?) -> Void) {
        guard !isLoading, !isDeleting, let args = rule.deletionArguments else { return }
        isDeleting = true
        ChannelManager.shared.invokeDataMethod(
            "deleteFirewallRule",
            arguments: args
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isDeleting = false
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool == true
                if success { self.fetch() }
                completion(success, dict?["error"] as? String)
            }
        }
    }

    func addRule(
        port: String,
        protocolName: String,
        address: String,
        strategy: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        ChannelManager.shared.invokeDataMethod(
            "addFirewallRule",
            arguments: [
                "port": port,
                "protocol": protocolName,
                "address": address,
                "strategy": strategy,
            ]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(dict?["success"] as? Bool ?? false, dict?["error"] as? String)
            }
        }
    }
}

/// 防火墙端口规则列表：端口、协议、来源与策略，支持删除。
struct FirewallView: View {
    @StateObject private var viewModel = FirewallViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: FirewallRuleModel?
    @State private var showAddSheet = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rules.isEmpty {
                LoadingView()
            } else if viewModel.hasLoadError && viewModel.rules.isEmpty {
                ErrorView(message: loadFailureMessage, onRetry: viewModel.fetch)
            } else if viewModel.rules.isEmpty {
                EmptyStateView(
                    icon: "shield.lefthalf.filled",
                    message: translations.get("firewallPortsEmptyTitle", fallback: "No port rules"),
                    description: translations.get("firewallPortsEmptyHint",
                                                  fallback: "Tap Add in the top toolbar to open a port.")
                )
            } else {
                List {
                    ForEach(viewModel.rules) { rule in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(portLine(rule))
                                    .font(.headline)
                                Spacer()
                                StatusBadge(
                                    text: rule.strategy.uppercased(),
                                    color: rule.strategy.lowercased() == "accept" ? .green : .red
                                )
                            }
                            Text(addressLine(rule))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !rule.description.isEmpty {
                                Text(rule.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if rule.deletionArguments != nil && !viewModel.isLoading && !viewModel.isDeleting {
                                Button(role: .destructive) {
                                    pendingDelete = rule
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleFirewall", fallback: "Firewall"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .firewall)
                Button {
                    showAddSheet = true
                } label: {
                    Label(translations.get("firewallCreatePortRuleAction", fallback: "Create Port Rule"),
                          systemImage: "plus")
                }
                .disabled(viewModel.isDeleting)
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isDeleting)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            FirewallAddSheet(viewModel: viewModel)
                .environmentObject(translations)
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { rule in
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                viewModel.delete(rule: rule) { success, message in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : message ?? translations.get("commonDeleteFailed", fallback: "Delete failed"))
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { rule in
            let source = rule.address.isEmpty
                ? translations.get("firewallSourceAnywhere", fallback: "Anywhere") : rule.address
            let target = [rule.port.isEmpty ? rule.protocolName : portLine(rule), source, rule.family,
                          rule.chain, rule.strategy, rule.description]
                .filter { !$0.isEmpty }
                .joined(separator: " · ")
            Text("\(target)\n\(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))")
        }
        .operationNotice(toastText)
        .onChange(of: viewModel.hasLoadError) { hasError in
            if hasError && !viewModel.rules.isEmpty {
                showToast(loadFailureMessage)
            }
        }
        .onAppear {
            viewModel.fetch()
            if ProcessInfo.processInfo.environment["ONEPANEL_OPEN_ADD_FIREWALL_RULE"] == "1" {
                showAddSheet = true
            }
        }
    }

    private var loadFailureMessage: String {
        translations.get("commonLoadFailedTitle", fallback: "Failed to load firewall rules")
    }

    private func portLine(_ rule: FirewallRuleModel) -> String {
        if rule.port.isEmpty { return rule.address }
        if rule.protocolName.isEmpty { return rule.port }
        return "\(rule.port)/\(rule.protocolName)"
    }

    private func addressLine(_ rule: FirewallRuleModel) -> String {
        rule.address.isEmpty ? "--" : rule.address
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
