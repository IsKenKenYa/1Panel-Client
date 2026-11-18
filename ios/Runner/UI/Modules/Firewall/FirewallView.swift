import SwiftUI

struct FirewallRuleModel: Identifiable {
    let id: Int
    let protocolName: String
    let port: String
    let address: String
    let strategy: String
    let description: String
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false

    func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getFirewallRules") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.rules = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return FirewallRuleModel(
                        id: id,
                        protocolName: item["protocol"] as? String ?? "",
                        port: item["port"] as? String ?? "",
                        address: item["address"] as? String ?? "",
                        strategy: item["strategy"] as? String ?? "",
                        description: item["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    func delete(rule: FirewallRuleModel, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteFirewallRule",
            arguments: [
                "port": rule.port,
                "protocol": rule.protocolName,
                "strategy": rule.strategy,
                "address": rule.address,
            ]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
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
    @State private var showDeleteConfirm = false
    @State private var showAddSheet = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rules.isEmpty {
                LoadingView()
            } else if viewModel.rules.isEmpty {
                EmptyStateView(
                    icon: "shield.lefthalf.filled",
                    message: translations.get("firewallPortsEmptyTitle", fallback: "No port rules")
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
                            Button(role: .destructive) {
                                pendingDelete = rule
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
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
                    Image(systemName: "plus")
                }
                Button {
                    viewModel.fetch()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            FirewallAddSheet(viewModel: viewModel)
                .environmentObject(translations)
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let rule = pendingDelete else { return }
                pendingDelete = nil
                viewModel.delete(rule: rule) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetch()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .overlay(alignment: .bottom) {
            if let toastText {
                Text(toastText)
                    .font(.footnote)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            viewModel.fetch()
            if ProcessInfo.processInfo.environment["ONEPANEL_OPEN_ADD_FIREWALL_RULE"] == "1" {
                showAddSheet = true
            }
        }
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