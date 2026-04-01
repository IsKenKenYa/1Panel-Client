import Foundation

struct ServerModel: Identifiable {
    let id = UUID()
    let originalId: String
    let name: String
    let url: String
}

class ServersViewModel: ObservableObject {
    @Published var servers: [ServerModel] = []
    @Published var isLoading = false
    
    func fetchServers() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getServers") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.servers = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let url = dict["url"] as? String else {
                            return nil
                        }
                        let originalId = dict["id"] as? String ?? ""
                        return ServerModel(originalId: originalId, name: name, url: url)
                    }
                }
            }
        }
    }
    
    func deleteServer(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("deleteServer", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchServers()
            }
        } catch {
            print("Failed to delete server: \(error)")
        }
    }
    
    func connectServer(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("connectServer", arguments: ["id": id])
        } catch {
            print("Failed to connect to server: \(error)")
        }
    }
}
