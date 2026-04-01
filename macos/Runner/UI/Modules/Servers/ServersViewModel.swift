import Foundation

struct ServerModel: Identifiable {
    let originalId: String
    let name: String
    let url: String
    
    var id: String { originalId }
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
        // The corresponding Dart-side handler for deleting servers is not implemented yet.
        print("deleteServer is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchServers()
        }
    }
    
    func connectServer(id: String) async {
        // The corresponding Dart-side handler for connecting servers is not implemented yet.
        print("connectServer is currently not supported: missing Dart handler.")
    }
}
