import Foundation

struct DatabaseModel: Identifiable {
    let recordId: Int?
    let serverId: String
    let scope: String
    let name: String
    let type: String
    let version: String
    let status: String
    let description: String

    var id: String { "\(serverId):\(scope):\(recordId.map(String.init) ?? name)" }

    var unbindArguments: [String: Any]? {
        guard scope == "remote", let recordId, recordId > 0, !serverId.isEmpty else { return nil }
        return ["id": recordId, "serverId": serverId]
    }
}

@MainActor
class DatabasesViewModel: ObservableObject {
    @Published var databases: [DatabaseModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var databaseToUnbind: DatabaseModel?

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
                    let scope = dict["type"] as? String ?? ""
                    return DatabaseModel(
                        recordId: dict["id"] as? Int,
                        serverId: dict["serverId"] as? String ?? "",
                        scope: scope,
                        name: name,
                        type: dict["engine"] as? String ?? scope,
                        version: dict["version"] as? String ?? "",
                        status: dict["status"] as? String ?? "",
                        description: dict["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    func unbind(_ database: DatabaseModel, confirmed: Bool) async {
        guard !isProcessing, let arguments = database.unbindArguments else { return }
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }
        let translations = TranslationsManager.shared
        do {
            let result = try await ChannelManager.shared.invokeDataMethodAsync(
                confirmed ? "unbindRemoteDatabase" : "checkRemoteDatabaseUnbind",
                arguments: arguments
            )
            let reply = result as? [String: Any]
            if let apps = reply?["dependentApps"] as? [String], !apps.isEmpty {
                errorMessage = translations.get("databaseRemoteUnbindInUse", fallback: "Applications still use this connection:")
                    + "\n" + apps.joined(separator: "\n")
            } else if reply?["serverChanged"] as? Bool == true {
                errorMessage = translations.get("databaseRemoteUnbindServerChanged", fallback: "The active server changed. Refresh the database list and try again.")
            } else {
                switch NativeMutationOutcome(result) {
                case .succeeded:
                    if confirmed {
                        fetchDatabases()
                    } else {
                        databaseToUnbind = database
                    }
                case .failed(let message):
                    errorMessage = message ?? translations.get("commonOperationFailed", fallback: "Operation failed")
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
