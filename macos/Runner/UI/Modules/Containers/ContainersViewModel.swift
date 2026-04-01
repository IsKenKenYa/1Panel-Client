import Foundation

struct ContainerModel: Identifiable {
    let originalId: String
    let name: String
    let image: String
    let state: String
    
    var id: String { originalId }
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
                        let originalId = dict["id"] as? String ?? ""
                        return ContainerModel(originalId: originalId, name: name, image: image, state: state)
                    }
                }
            }
        }
    }
    
    func toggleContainerState(id: String, currentState: String) async {
        // The corresponding Dart-side handlers for starting/stopping containers
        // are not implemented yet. Avoid invoking unsupported method-channel
        // actions and simply refresh the container list instead.
        print("toggleContainerState is currently not supported: missing Dart handler for container state change.")
        DispatchQueue.main.async {
            self.fetchContainers()
        }
    }
    
    func restartContainer(id: String) async {
        // The Dart-side handler for restarting a container is not implemented.
        // Do not attempt to call an unsupported method-channel action.
        print("restartContainer is currently not supported: missing Dart handler for restarting containers.")
        DispatchQueue.main.async {
            self.fetchContainers()
        }
    }
    
    func deleteContainer(id: String) async {
        // The Dart-side handler for deleting a container is not implemented.
        // Do not attempt to call an unsupported method-channel action.
        print("deleteContainer is currently not supported: missing Dart handler for deleting containers.")
        DispatchQueue.main.async {
            self.fetchContainers()
        }
    }
}
