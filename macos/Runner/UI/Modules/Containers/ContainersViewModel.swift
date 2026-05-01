import Foundation

struct ContainerModel: Identifiable {
    let originalId: String
    let name: String
    let image: String
    let state: String
    let status: String

    var id: String { originalId }
}

class ContainersViewModel: ObservableObject {
    @Published var containers: [ContainerModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    func fetchContainers() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getContainers") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dictArray = result as? [[String: Any]] else { return }
                self?.containers = dictArray.compactMap { dict in
                    guard let name = dict["name"] as? String,
                          let image = dict["image"] as? String,
                          let state = dict["state"] as? String else { return nil }
                    let originalId = dict["id"] as? String ?? ""
                    let status = dict["status"] as? String ?? ""
                    return ContainerModel(originalId: originalId, name: name, image: image, state: state, status: status)
                }
            }
        }
    }

    func toggleContainerState(id: String, currentState: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod(
            "toggleContainerState",
            arguments: ["id": id, "state": currentState]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Operation failed"
                }
                self?.fetchContainers()
            }
        }
    }

    func restartContainer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("restartContainer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Restart failed"
                }
                self?.fetchContainers()
            }
        }
    }

    func deleteContainer(id: String) async {
        await MainActor.run { isProcessing = true; errorMessage = nil }
        ChannelManager.shared.invokeDataMethod("deleteContainer", arguments: ["id": id]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                if let dict = result as? [String: Any],
                   let success = dict["success"] as? Bool, !success {
                    self?.errorMessage = dict["error"] as? String ?? "Delete failed"
                }
                self?.fetchContainers()
            }
        }
    }
}
