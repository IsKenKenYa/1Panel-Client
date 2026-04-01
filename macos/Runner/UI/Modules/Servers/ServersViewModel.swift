import Foundation

struct ServerModel: Identifiable {
    let originalId: String
    let name: String
    let url: String
    let isCurrent: Bool

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
                    return ServerModel(originalId: originalId, name: name, url: url, isCurrent: isCurrent)
                }
            }
        }
    }

    func addServer(name: String, url: String, token: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        let args: [String: Any] = ["name": name, "url": url, "apiKey": token]
        ChannelManager.shared.invokeDataMethod("addServer", arguments: args) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Add failed"
                } else {
                    self?.fetchServers()
                }
            }
        }
    }

    func deleteServer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteServer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchServers()
            }
        }
    }

    func connectServer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("connectServer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Connect failed"
                } else {
                    self?.fetchServers()
                }
            }
        }
    }
}
