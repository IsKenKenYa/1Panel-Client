import Foundation

struct AppModel: Identifiable {
    let originalId: String
    let name: String
    let status: String
    let version: String
    
    var id: String { originalId }
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
                        let originalId = dict["appId"] as? String ?? ""
                        return AppModel(originalId: originalId, name: name, status: status, version: version)
                    }
                }
            }
        }
    }
    
    func toggleAppStatus(id: String, currentStatus: String) async {
        // Note: The Dart NativeChannelManager currently does not implement "startApp"/"stopApp".
        // To avoid invoking unsupported method-channel handlers, we no-op here and log instead.
        print("toggleAppStatus called for id=\(id), currentStatus=\(currentStatus), but start/stop operations are not supported by the current channel implementation.")
    }
    
    func uninstallApp(id: String) async {
        // Note: The Dart NativeChannelManager currently does not implement "uninstallApp".
        // To avoid invoking an unsupported method-channel handler, we no-op here and log instead.
        print("uninstallApp called for id=\(id), but uninstall operations are not supported by the current channel implementation.")
    }
}
