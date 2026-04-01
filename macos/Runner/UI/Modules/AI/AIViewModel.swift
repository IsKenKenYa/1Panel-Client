import Foundation

struct AIModel: Identifiable {
    let originalId: String
    let name: String
    let size: String
    let modified: String

    var id: String { originalId }
}

class AIViewModel: ObservableObject {
    @Published var models: [AIModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchModels() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getAIModels") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self?.errorMessage = "Failed to parse AI models"
                    return
                }
                self?.models = dictArray.compactMap { dict in
                    let rawId = dict["id"]
                    let idStr: String
                    if let intId = rawId as? Int { idStr = String(intId) }
                    else { idStr = rawId as? String ?? "" }
                    return AIModel(
                        originalId: idStr,
                        name: dict["name"] as? String ?? "",
                        size: dict["size"] as? String ?? "",
                        modified: dict["modified"] as? String ?? ""
                    )
                }
            }
        }
    }

    func deleteModel(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteAIModel", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchModels()
            }
        }
    }
}
