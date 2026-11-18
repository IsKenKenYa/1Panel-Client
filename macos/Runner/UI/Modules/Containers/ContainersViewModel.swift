import Foundation

struct ContainerModel: Identifiable {
    let originalId: String
    let name: String
    let image: String
    let state: String
    let status: String

    var id: String { originalId }
}

@MainActor
final class ContainersViewModel: ObservableObject {
    @Published private(set) var containers: [ContainerModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    var isBusy: Bool { isLoading || isProcessing }

    /// 容器日志（getContainerLogs 通道，尾部 500 行）。
    func fetchLogs(name: String, tail: String = "500") async throws -> String {
        let result = try await ChannelManager.shared.invokeDataMethodAsync(
            "getContainerLogs",
            arguments: ["name": name, "tail": tail]
        )
        guard let logs = result as? String else {
            throw CocoaError(.coderInvalidValue)
        }
        return logs
    }

    func fetchContainers() async {
        guard !isBusy else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await ChannelManager.shared.invokeDataMethodAsync("getContainers")
            guard let rows = result as? [[String: Any]] else {
                errorMessage = TranslationsManager.shared.get("commonLoadFailedTitle", fallback: "Failed to load")
                return
            }
            containers = rows.compactMap { row in
                guard let id = row["id"] as? String, !id.isEmpty,
                      let name = row["name"] as? String,
                      let image = row["image"] as? String,
                      let state = row["state"] as? String else { return nil }
                let status = row["status"] as? String ?? ""
                return ContainerModel(originalId: id, name: name, image: image, state: state, status: status)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleContainerState(id: String, currentState: String) async {
        await performWrite(
            "toggleContainerState",
            arguments: ["id": id, "state": currentState]
        )
    }

    func restartContainer(id: String) async {
        await performWrite("restartContainer", arguments: ["id": id])
    }

    func deleteContainer(id: String) async {
        await performWrite("deleteContainer", arguments: ["id": id])
    }

    private func performWrite(_ method: String, arguments: [String: Any]) async {
        guard !isBusy else { return }
        errorMessage = nil
        do {
            isProcessing = true
            defer { isProcessing = false }
            let result = try await ChannelManager.shared.invokeDataMethodAsync(method, arguments: arguments) as? [String: Any]
            guard result?["success"] as? Bool == true else {
                errorMessage = result?["error"] as? String ?? TranslationsManager.shared.get(
                    "commonOperationFailed",
                    fallback: "Operation failed"
                )
                return
            }
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        await fetchContainers()
    }
}
