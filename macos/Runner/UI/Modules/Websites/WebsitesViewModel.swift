import Foundation

struct WebsiteModel: Identifiable {
    let originalId: String
    let primaryDomain: String
    let status: String
    let remark: String

    var id: String { originalId }
}

class WebsitesViewModel: ObservableObject {
    @Published var websites: [WebsiteModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchWebsites() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getWebsites") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.websites = dictArray.compactMap { dict in
                    guard let primaryDomain = dict["primaryDomain"] as? String,
                          let status = dict["status"] as? String,
                          let remark = dict["remark"] as? String else { return nil }
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    return WebsiteModel(
                        originalId: idStr,
                        primaryDomain: primaryDomain,
                        status: status,
                        remark: remark
                    )
                }
            }
        }
    }

    func toggleWebsiteStatus(id: String, currentStatus: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod(
            "toggleWebsiteStatus",
            arguments: ["id": id, "currentStatus": currentStatus]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Toggle failed"
                }
                self?.fetchWebsites()
            }
        }
    }

    func deleteWebsite(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteWebsite", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchWebsites()
            }
        }
    }
}
