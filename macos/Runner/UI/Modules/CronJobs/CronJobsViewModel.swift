import Foundation

struct CronJobModel: Identifiable {
    let originalId: String
    let name: String
    let schedule: String
    let status: String
    let type: String
    let lastRecordStatus: String
    let nextHandle: String

    var id: String { originalId }
}

class CronJobsViewModel: ObservableObject {
    @Published var cronJobs: [CronJobModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchCronJobs() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getCronJobs") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self?.errorMessage = "Failed to parse cron jobs"
                    return
                }
                self?.cronJobs = dictArray.compactMap { dict in
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    return CronJobModel(
                        originalId: idStr,
                        name: dict["name"] as? String ?? "",
                        schedule: dict["spec"] as? String ?? "",
                        status: dict["status"] as? String ?? "",
                        type: dict["type"] as? String ?? "",
                        lastRecordStatus: dict["lastRecordStatus"] as? String ?? "",
                        nextHandle: dict["nextHandle"] as? String ?? ""
                    )
                }
            }
        }
    }

    func toggleCronJobStatus(id: String, currentStatus: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod(
            "toggleCronJobStatus",
            arguments: ["id": id, "currentStatus": currentStatus]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Toggle failed"
                }
                self?.fetchCronJobs()
            }
        }
    }

    func deleteCronJob(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteCronJob", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchCronJobs()
            }
        }
    }
}
