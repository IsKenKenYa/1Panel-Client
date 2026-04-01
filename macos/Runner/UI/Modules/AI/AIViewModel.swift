import Foundation

struct AIModel: Identifiable {
    let originalId: String
    let name: String
    let status: String
    let description: String
    
    var id: String { originalId }
}

class AIViewModel: ObservableObject {
    @Published var models: [AIModel] = []
    @Published var isLoading = false
    
    func fetchModels() {
        isLoading = true
        print("getAIModels is currently not supported: missing Dart handler.")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.models = [
                AIModel(originalId: "1", name: "GPT-4", status: "Ready", description: "OpenAI GPT-4 model")
            ]
        }
    }
    
    func toggleModelStatus(id: String, currentStatus: String) async {
        print("toggleModelStatus is currently not supported: missing Dart handler.")
        DispatchQueue.main.async {
            self.fetchModels()
        }
    }
}
