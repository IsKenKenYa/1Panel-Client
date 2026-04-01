import Foundation

struct FirewallRuleModel: Identifiable {
    let id = UUID()
    let originalId: String
    let port: String
    let protocolType: String
    let action: String
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    
    func fetchRules() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getFirewallRules") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.rules = dictArray.compactMap { dict in
                        guard let port = dict["port"] as? String,
                              let protocolType = dict["protocol"] as? String,
                              let action = dict["action"] as? String else {
                            return nil
                        }
                        let originalId = dict["id"] as? String ?? ""
                        return FirewallRuleModel(originalId: originalId, port: port, protocolType: protocolType, action: action)
                    }
                }
            }
        }
    }
    
    func deleteRule(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("deleteFirewallRule", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchRules()
            }
        } catch {
            print("Failed to delete firewall rule: \(error)")
        }
    }
}
