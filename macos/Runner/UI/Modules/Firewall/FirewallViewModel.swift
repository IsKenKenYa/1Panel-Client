import Foundation

struct FirewallRuleModel: Identifiable {
    let id = UUID()
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
                        return FirewallRuleModel(port: port, protocolType: protocolType, action: action)
                    }
                }
            }
        }
    }
}
