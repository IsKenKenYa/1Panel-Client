import Foundation

struct AppModel: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let version: String
}

class AppsViewModel: ObservableObject {
    @Published var apps: [AppModel] = []
    @Published var isLoading = false
    
    func fetchApps() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getApps") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.apps = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let status = dict["status"] as? String,
                              let version = dict["version"] as? String else {
                            return nil
                        }
                        return AppModel(name: name, status: status, version: version)
                    }
                }
            }
        }
    }
}
