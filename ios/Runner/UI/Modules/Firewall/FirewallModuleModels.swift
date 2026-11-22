import AppleSharedUI
import Foundation

@MainActor
final class FirewallRuleListModel: ObservableObject {
    @Published var rules: [FirewallRuleModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch(kind: FirewallRuleKind) async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                kind == .port ? "getFirewallRules" : "getFirewallIpRules"
            )
            rules = (raw as? [[String: Any]] ?? []).compactMap(FirewallRuleModel.init(payload:))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ rule: FirewallRuleModel) async -> String? {
        guard let arguments = rule.deletionArguments else { return nil }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteFirewallRule",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                return nil
            }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

@MainActor
final class FirewallBaseModel: ObservableObject {
    @Published var name = ""
    @Published var isExist = false
    @Published var isActive = false
    @Published var isInit = false
    @Published var isBound = false
    @Published var version = ""
    @Published var pingStatus = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getFirewallBaseInfo"
            )
            let payload = raw as? [String: Any] ?? [:]
            name = payload["name"] as? String ?? ""
            isExist = payload["isExist"] as? Bool ?? false
            isActive = payload["isActive"] as? Bool ?? false
            isInit = payload["isInit"] as? Bool ?? false
            isBound = payload["isBind"] as? Bool ?? false
            version = payload["version"] as? String ?? ""
            pingStatus = payload["pingStatus"] as? String ?? ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func operate(_ operation: String) async -> String? {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "operateFirewall",
                arguments: ["operation": operation]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await fetch()
                return nil
            }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}