import Foundation

struct BackupModel: Identifiable {
    let id = UUID()
    let name: String
    let type: String
    let size: String
    let date: String
}

class BackupsViewModel: ObservableObject {
    @Published var backups: [BackupModel] = []
    @Published var isLoading = false
    
    func fetchBackups() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getBackups") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.backups = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let type = dict["type"] as? String,
                              let size = dict["size"] as? String,
                              let date = dict["date"] as? String else {
                            return nil
                        }
                        return BackupModel(name: name, type: type, size: size, date: date)
                    }
                }
            }
        }
    }
}
