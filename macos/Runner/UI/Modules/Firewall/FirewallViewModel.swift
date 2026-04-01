import Foundation

struct FirewallRuleModel: Identifiable {
    let originalId: String
    let port: String
    let protocolType: String
    let action: String
    
    var id: String { originalId }
}

class FirewallViewModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    
    func fetchRules() {
        isLoading = true
        // The Dart NativeChannelManager currently does not implement "getFirewallRules".
        // Mock data to prevent runtime errors.
        print("getFirewallRules is currently not supported: missing Dart handler.")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.rules = [
                FirewallRuleModel(originalId: "1", port: "80", protocolType: "TCP", action: "ALLOW"),
                FirewallRuleModel(originalId: "2", port: "443", protocolType: "TCP", action: "ALLOW")
            ]
        }
    }
    
    func deleteRule(id: String) async {
        // The Dart-side handler for deleting a firewall rule is not implemented.
        print("deleteFirewallRule is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchRules()
        }
    }
}
