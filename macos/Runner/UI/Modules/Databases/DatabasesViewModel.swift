import Foundation

struct DatabaseModel: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let status: String
}

class DatabasesViewModel: ObservableObject {
    @Published var databases: [DatabaseModel] = []
    @Published var isLoading = false
    
    func fetchDatabases() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getDatabases") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.databases = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let type = dict["type"] as? String,
                              let status = dict["status"] as? String else {
                            return nil
                        }
                        return DatabaseModel(name: name, type: type, status: status)
                    }
                }
            }
        }
    }
}
