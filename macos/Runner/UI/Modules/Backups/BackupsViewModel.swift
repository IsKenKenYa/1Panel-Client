import Foundation

struct BackupModel: Identifiable {
    let originalId: String
    let name: String
    let type: String
    let size: String
    let status: String
    let date: String

    var id: String { originalId }
}

class BackupsViewModel: ObservableObject {
    @Published var backups: [BackupModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchBackups() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getBackups") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self?.errorMessage = "Failed to parse backups"
                    return
                }
                self?.backups = dictArray.compactMap { dict in
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    let sizeBytes = dict["size"] as? Int ?? 0
                    let sizeText = sizeBytes > 0 ? ByteCountFormatter.string(
                        fromByteCount: Int64(sizeBytes),
                        countStyle: .file
                    ) : "--"
                    return BackupModel(
                        originalId: idStr,
                        name: dict["name"] as? String ?? "",
                        type: dict["type"] as? String ?? "",
                        size: sizeText,
                        status: dict["status"] as? String ?? "",
                        date: dict["backupTime"] as? String ?? dict["createdAt"] as? String ?? ""
                    )
                }
            }
        }
    }

    func deleteBackup(id: String) async {
        guard let backup = backups.first(where: { $0.originalId == id }) else { return }
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod(
            "deleteBackup",
            arguments: [
                "id": id,
                "name": backup.name,
                "type": backup.type,
                "status": backup.status
            ]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchBackups()
            }
        }
    }
}
