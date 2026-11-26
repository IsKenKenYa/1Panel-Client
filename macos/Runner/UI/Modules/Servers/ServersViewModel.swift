import FlutterMacOS
import Foundation

struct ServerModel: Identifiable {
    let originalId: String
    let revision: String
    let name: String
    let url: String
    let isCurrent: Bool
    let cpu: Double?
    let memory: Double?
    let tokenValidity: Int
    let allowInsecureTls: Bool

    var id: String { originalId }
}

class ServersViewModel: ObservableObject {
    @Published var servers: [ServerModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchServers() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getServers") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    // 通道返回的不是服务器数组：把原始错误留在模型里，
                    // 列表据此显示失败占位，不再渲染成「没有服务器」。
                    self?.errorMessage = (result as? FlutterError)?.message
                        ?? TranslationsManager.shared.get("commonLoadFailedTitle",
                                                           fallback: "Failed to load")
                    return
                }
                self?.servers = dictArray.compactMap { dict in
                    guard let originalId = dict["id"] as? String,
                          let revision = dict["revision"] as? String,
                          let name = dict["name"] as? String,
                          let url = dict["url"] as? String else { return nil }
                    let isCurrent = dict["isCurrent"] as? Bool ?? false
                    // 指标可能缺失：保留 nil，让列表显示占位而不是 0%。
                    let cpu = dict["cpu"] as? Double
                    let memory = dict["memory"] as? Double
                    let tokenValidity = dict["tokenValidity"] as? Int ?? 0
                    let allowInsecureTls = dict["allowInsecureTls"] as? Bool ?? false
                    return ServerModel(
                        originalId: originalId,
                        revision: revision,
                        name: name,
                        url: url,
                        isCurrent: isCurrent,
                        cpu: cpu,
                        memory: memory,
                        tokenValidity: tokenValidity,
                        allowInsecureTls: allowInsecureTls
                    )
                }
            }
        }
    }

    @MainActor
    func addServer(
        name: String,
        url: String,
        token: String,
        tokenValidity: Int,
        allowInsecureTls: Bool
    ) async -> NativeMutationOutcome {
        let args: [String: Any] = [
            "panelType": "1panel",
            "name": name,
            "url": url,
            "apiKey": token,
            "tokenValidity": tokenValidity,
            "allowInsecureTls": allowInsecureTls,
        ]
        let outcome = await ChannelManager.shared.invokeMutation("addServer", arguments: args)
        if outcome == .succeeded {
            fetchServers()
        }
        return outcome
    }

    /// 更新服务器配置（updateServer 通道：apiKey 留空沿用原值）。
    @MainActor
    func updateServer(
        server: ServerModel,
        name: String,
        url: String,
        token: String,
        tokenValidity: Int,
        allowInsecureTls: Bool
    ) async -> NativeMutationOutcome {
        let args: [String: Any] = [
            "id": server.originalId,
            "revision": server.revision,
            "name": name,
            "url": url,
            "apiKey": token,
            "tokenValidity": tokenValidity,
            "allowInsecureTls": allowInsecureTls,
        ]
        let outcome = await ChannelManager.shared.invokeMutation("updateServer", arguments: args)
        if outcome == .succeeded {
            fetchServers()
        }
        return outcome
    }

    func deleteServer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteServer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch NativeMutationOutcome(result) {
                case .succeeded:
                    self?.fetchServers()
                case .failed(let message):
                    self?.errorMessage = message ?? "Delete failed"
                }
            }
        }
    }

    func connectServer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("connectServer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                switch NativeMutationOutcome(result) {
                case .succeeded:
                    self?.fetchServers()
                case .failed(let message):
                    self?.errorMessage = message ?? "Connect failed"
                }
            }
        }
    }
}
