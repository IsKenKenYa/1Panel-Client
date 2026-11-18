import Foundation

struct ServerModel: Identifiable {
    let originalId: String
    let name: String
    let url: String
    let isCurrent: Bool
    let cpu: Double
    let memory: Double

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
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.servers = dictArray.compactMap { dict in
                    guard let name = dict["name"] as? String,
                          let url = dict["url"] as? String else { return nil }
                    let rawId = dict["id"]
                    let originalId: String
                    if let intId = rawId as? Int { originalId = String(intId) }
                    else { originalId = rawId as? String ?? "" }
                    let isCurrent = dict["isCurrent"] as? Bool ?? false
                    let cpu = dict["cpu"] as? Double ?? 0
                    let memory = dict["memory"] as? Double ?? 0
                    return ServerModel(originalId: originalId, name: name, url: url, isCurrent: isCurrent, cpu: cpu, memory: memory)
                }
            }
        }
    }

    @MainActor
    func addServer(name: String, url: String, token: String) async -> NativeMutationOutcome {
        let args: [String: Any] = ["name": name, "url": url, "apiKey": token]
        let outcome = await ChannelManager.shared.invokeMutation("addServer", arguments: args)
        if outcome == .succeeded {
            fetchServers()
        }
        return outcome
    }

    /// 更新服务器配置（updateServer 通道：apiKey 留空沿用原值）。
    @MainActor
    func updateServer(id: String, name: String, url: String, token: String) async -> NativeMutationOutcome {
        let args: [String: Any] = [
            "id": id,
            "name": name,
            "url": url,
            "apiKey": token,
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
