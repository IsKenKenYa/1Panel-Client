import Foundation

struct FirewallRuleModel: Identifiable {
    let originalId: String
    let port: String
    let protocolType: String
    let address: String
    let strategy: String
    let description: String
    let family: String
    let chain: String
    let supportsLegacyChanges: Bool
    let serverId: String?
    let inventoryId: String?
    let canDelete: Bool?

    var id: String { originalId }

    init?(payload: [String: Any]) {
        let rawId = payload["id"]
        guard let id = rawId as? String ?? (rawId as? Int).map(String.init) else { return nil }
        originalId = id
        protocolType = payload["protocol"] as? String ?? ""
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
        var args = ["port": port, "protocol": protocolType, "strategy": strategy, "address": address]
        if let serverId { args["serverId"] = serverId }
        return args
    }
}

enum FirewallRuleKind: String {
    case port
    case ip
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?
    @Published var hasLoadError = false
    private(set) var kind: FirewallRuleKind = .port

    func fetchRules(kind: FirewallRuleKind = .port) {
        guard !isLoading, !isProcessing else { return }
        self.kind = kind
        isLoading = true
        errorMessage = nil
        hasLoadError = false
        let method = kind == .port ? "getFirewallRules" : "getFirewallIpRules"
        ChannelManager.shared.invokeDataMethod(method) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    guard let self else { return }
                    self.hasLoadError = true
                    if !self.rules.isEmpty {
                        self.errorMessage = TranslationsManager.shared.get(
                            "commonLoadFailedTitle", fallback: "Failed to load firewall rules"
                        )
                    }
                    return
                }
                self?.rules = dictArray.compactMap(FirewallRuleModel.init(payload:))
            }
        }
    }

    @MainActor
    func addRule(port: String, protocol proto: String, address: String, strategy: String) async -> NativeMutationOutcome {
        let args: [String: Any] = [
            "port": port,
            "protocol": proto,
            "address": address,
            "strategy": strategy,
        ]
        let outcome = await ChannelManager.shared.invokeMutation("addFirewallRule", arguments: args)
        if outcome == .succeeded {
            fetchRules(kind: kind)
        }
        return outcome
    }

    @MainActor
    func deleteRule(_ rule: FirewallRuleModel) async {
        guard !isLoading, !isProcessing, let args = rule.deletionArguments else { return }
        isProcessing = true
        errorMessage = nil
        let outcome = await ChannelManager.shared.invokeMutation("deleteFirewallRule", arguments: args)
        isProcessing = false
        switch outcome {
        case .succeeded:
            fetchRules(kind: kind)
        case .failed(let message):
            errorMessage = message ?? TranslationsManager.shared.get("commonDeleteFailed", fallback: "Delete failed")
        }
    }
}
