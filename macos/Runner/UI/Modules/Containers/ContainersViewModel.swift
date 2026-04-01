import Foundation

struct ContainerModel: Identifiable {
    let id = UUID()
    let originalId: String
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
                        let originalId = dict["id"] as? String ?? ""
                        return ContainerModel(originalId: originalId, name: name, image: image, state: state)
                    }
                }
            }
        }
    }
    
    func toggleContainerState(id: String, currentState: String) async {
        let action = currentState.lowercased() == "running" ? "stopContainer" : "startContainer"
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync(action, arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchContainers()
            }
        } catch {
            print("Failed to toggle container state: \(error)")
        }
    }
    
    func restartContainer(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("restartContainer", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchContainers()
            }
        } catch {
            print("Failed to restart container: \(error)")
        }
    }
    
    func deleteContainer(id: String) async {
        do {
            _ = try await ChannelManager.shared.invokeDataMethodAsync("deleteContainer", arguments: ["id": id])
            DispatchQueue.main.async {
                self.fetchContainers()
            }
        } catch {
            print("Failed to delete container: \(error)")
        }
    }
}
