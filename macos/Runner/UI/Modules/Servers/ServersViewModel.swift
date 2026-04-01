import Foundation

struct ServerModel: Identifiable {
    let id = UUID()
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
                        return ServerModel(name: name, url: url)
                    }
                }
            }
        }
    }
}
