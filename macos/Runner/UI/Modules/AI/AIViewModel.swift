import Foundation

struct AIModel: Identifiable {
    let id = UUID()
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
                        return AIModel(name: name, status: status, description: desc)
                    }
                }
            }
        }
    }
}
