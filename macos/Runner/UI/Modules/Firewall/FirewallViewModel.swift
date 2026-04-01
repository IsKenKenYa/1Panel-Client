import Foundation

struct FirewallRuleModel: Identifiable {
    let originalId: String
    let port: String
    let protocolType: String
    let address: String
    let strategy: String
    let description: String

    var id: String { originalId }
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchRules() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getFirewallRules") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self?.errorMessage = "Failed to parse firewall rules"
                    return
                }
                self?.rules = dictArray.compactMap { dict in
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    return FirewallRuleModel(
                        originalId: idStr,
                        port: dict["port"] as? String ?? "",
                        protocolType: dict["protocol"] as? String ?? "",
                        address: dict["address"] as? String ?? "",
                        strategy: dict["strategy"] as? String ?? "",
                        description: dict["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    func deleteRule(_ rule: FirewallRuleModel) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        let args: [String: Any] = [
            "port": rule.port,
            "protocol": rule.protocolType,
            "address": rule.address,
            "strategy": rule.strategy,
        ]
        ChannelManager.shared.invokeDataMethod("deleteFirewallRule", arguments: args) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchRules()
            }
        }
    }
}
