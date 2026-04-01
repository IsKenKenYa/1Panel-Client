import Foundation

struct ContainerModel: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let state: String
}

class ContainersViewModel: ObservableObject {
    @Published var containers: [ContainerModel] = []
    @Published var isLoading = false
    
    func fetchContainers() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getContainers") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dictArray = result as? [[String: Any]] {
                    self?.containers = dictArray.compactMap { dict in
                        guard let name = dict["name"] as? String,
                              let image = dict["image"] as? String,
                              let state = dict["state"] as? String else {
                            return nil
                        }
                        return ContainerModel(name: name, image: image, state: state)
                    }
                }
            }
        }
    }
}
