import Foundation

struct DatabaseModel: Identifiable {
    let originalId: String
    let name: String
    let type: String
    let status: String
    
    var id: String { originalId }
}

class DatabasesViewModel: ObservableObject {
    @Published var databases: [DatabaseModel] = []
    @Published var isLoading = false
    
    func fetchDatabases() {
        isLoading = true
        print("getDatabases is currently not supported: missing Dart handler.")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.databases = [
                DatabaseModel(originalId: "1", name: "main_db", type: "MySQL", status: "Running")
            ]
        }
    }
    
    func deleteDatabase(id: String) async {
        print("deleteDatabase is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchDatabases()
        }
    }
}
