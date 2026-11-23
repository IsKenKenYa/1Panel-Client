import Foundation

struct ServerModel: Identifiable, Hashable {
    let originalId: String
    let revision: String
    let name: String
    let url: String
    let isCurrent: Bool
    let cpu: Double
    let memory: Double
    let tokenValidity: Int
    let allowInsecureTls: Bool

    var id: String { originalId }

    init(
        originalId: String,
        revision: String,
        name: String,
        url: String,
        isCurrent: Bool,
        cpu: Double,
        memory: Double,
        tokenValidity: Int = 0,
        allowInsecureTls: Bool = false
    ) {
        self.originalId = originalId
        self.revision = revision
        self.name = name
        self.url = url
        self.isCurrent = isCurrent
        self.cpu = cpu
        self.memory = memory
        self.tokenValidity = tokenValidity
        self.allowInsecureTls = allowInsecureTls
    }
}

class ServersViewModel: ObservableObject {
    @Published var servers: [ServerModel] = []
    @Published var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    func selectServer(id: String, completion: @escaping (Bool) -> Void) {
        guard !isProcessing else { return }
        isProcessing = true
        ChannelManager.shared.invokeDataMethod("connectServer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isProcessing = false
                let success = (result as? [String: Any])?["success"] as? Bool == true
                completion(success)
            }
        }
    }

    /// 新增服务器配置（addServer 通道），成功后由调用方刷新列表。
    func addServer(
        name: String,
        url: String,
        apiKey: String,
        tokenValidity: Int,
        allowInsecureTls: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        ChannelManager.shared.invokeDataMethod(
            "addServer",
            arguments: [
                "panelType": "1panel",
                "name": name,
                "url": url,
                "apiKey": apiKey,
                "tokenValidity": tokenValidity,
                "allowInsecureTls": allowInsecureTls,
            ]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    /// 删除服务器配置（deleteServer 通道）。
    func deleteServer(
        id: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        ChannelManager.shared.invokeDataMethod(
            "deleteServer",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    /// 更新服务器配置（updateServer 通道）。
    func updateServer(
        server: ServerModel,
        name: String,
        url: String,
        apiKey: String,
        tokenValidity: Int,
        allowInsecureTls: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        ChannelManager.shared.invokeDataMethod(
            "updateServer",
            arguments: [
                "id": server.originalId,
                "revision": server.revision,
                "name": name,
                "url": url,
                "apiKey": apiKey,
                "tokenValidity": tokenValidity,
                "allowInsecureTls": allowInsecureTls,
            ]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    func fetchServers(completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getServers") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    completion?()
                    return
                }
                self?.servers = dictArray.compactMap { dict in
                    guard let originalId = dict["id"] as? String,
                          let revision = dict["revision"] as? String,
                          let name = dict["name"] as? String,
                          let url = dict["url"] as? String else { return nil }
                    let isCurrent = dict["isCurrent"] as? Bool ?? false
                    let cpu = dict["cpu"] as? Double ?? 0
                    let memory = dict["memory"] as? Double ?? 0
                    return ServerModel(
                        originalId: originalId, revision: revision,
                        name: name, url: url, isCurrent: isCurrent,
                        cpu: cpu, memory: memory,
                        tokenValidity: dict["tokenValidity"] as? Int ?? 0,
                        allowInsecureTls: dict["allowInsecureTls"] as? Bool ?? false
                    )
                }
                completion?()
            }
        }
    }
}
