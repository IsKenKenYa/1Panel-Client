import Foundation

struct BackupModel: Identifiable {
    let originalId: String
    let name: String
    let type: String
    let size: String
    let date: String
    
    var id: String { originalId }
}

class BackupsViewModel: ObservableObject {
    @Published var backups: [BackupModel] = []
    @Published var isLoading = false
    
    func fetchBackups() {
        isLoading = true
        print("getBackups is currently not supported: missing Dart handler.")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.backups = [
                BackupModel(originalId: "1", name: "backup_2026.zip", type: "Database", size: "100 MB", date: "2026-01-01")
            ]
        }
    }
    
    func deleteBackup(id: String) async {
        print("deleteBackup is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchBackups()
        }
    }
}
