import Foundation

struct AIModel: Identifiable {
    let id = UUID()
    let originalId: String
    let name: String
    let status: String
    let description: String
}

class AIViewModel: ObservableObject {
    @Published var models: [AIModel] = []
    @Published var isLoading = false
    
    func fetchModels() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getAIModels") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.models = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let status = dict["status"] as? String,
                              let desc = dict["description"] as? String else {
                            return nil
                        }
                        let originalId = dict["id"] as? String ?? ""
                        return AIModel(originalId: originalId, name: name, status: status, description: desc)
                    }
                }
            }
        }
    }
    
    func toggleModelStatus(id: String, currentStatus: String) async {
        let action = currentStatus.lowercased() == "ready" || currentStatus.lowercased() == "running" ? "stopAIModel" : "startAIModel"
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync(action, arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchModels()
            }
        } catch {
            print("Failed to toggle AI model status: \(error)")
        }
    }
}
