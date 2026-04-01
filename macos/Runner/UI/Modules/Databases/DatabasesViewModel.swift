import Foundation

struct DatabaseModel: Identifiable {
    let originalId: String
    let name: String
    let type: String
    let version: String
    let status: String
    let description: String

    var id: String { originalId }
}

class DatabasesViewModel: ObservableObject {
    @Published var databases: [DatabaseModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchDatabases() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getDatabases") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self?.errorMessage = "Failed to parse databases data"
                    return
                }
                self?.databases = dictArray.compactMap { dict in
                    guard let name = dict["name"] as? String else { return nil }
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int {
                        idStr = String(intId)
                    } else {
                        idStr = rawId as? String ?? ""
                    }
                    return DatabaseModel(
                        originalId: idStr,
                        name: name,
                        type: dict["type"] as? String ?? "",
                        version: dict["version"] as? String ?? "",
                        status: dict["status"] as? String ?? "",
                        description: dict["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    func deleteDatabase(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteDatabase", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchDatabases()
            }
        }
    }
}
