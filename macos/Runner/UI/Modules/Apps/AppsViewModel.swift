import Foundation

struct AppModel: Identifiable {
    let id = UUID()
    let originalId: String
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
                        let originalId = dict["id"] as? String ?? ""
                        return AppModel(originalId: originalId, name: name, status: status, version: version)
                    }
                }
            }
        }
    }
    
    func toggleAppStatus(id: String, currentStatus: String) async {
        let action = currentStatus.lowercased() == "running" ? "stopApp" : "startApp"
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync(action, arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchApps()
            }
        } catch {
            print("Failed to toggle app status: \(error)")
        }
    }
    
    func uninstallApp(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("uninstallApp", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchApps()
            }
        } catch {
            print("Failed to uninstall app: \(error)")
        }
    }
}
