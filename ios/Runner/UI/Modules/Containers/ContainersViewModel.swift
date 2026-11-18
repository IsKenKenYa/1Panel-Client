import Foundation

struct ContainerModel: Identifiable, Hashable {
    let originalId: String
    let name: String
    let image: String
    let state: String
    let cpuUsage: Double?
    let memoryUsage: Double?

    var id: String { originalId }
}

class ContainersViewModel: ObservableObject {
    @Published var containers: [ContainerModel] = []
    @Published var isLoading = false
    @Published var isProcessing = false
    @Published var errorMessage: String?

    /// 容器日志（getContainerLogs 通道，尾部 200 行）。
    @Published var logs: String = ""
    @Published var isLoadingLogs = false
    /// 容器 inspect（getContainerInspect 通道，格式化 JSON）。
    @Published var inspectText: String = ""
    @Published var isLoadingInspect = false

    func fetchLogs(name: String, tail: String = "200") {
        isLoadingLogs = true
        ChannelManager.shared.invokeDataMethod(
            "getContainerLogs",
            arguments: ["name": name, "tail": tail]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingLogs = false
                if let text = result as? String {
                    self?.logs = text
                }
            }
        }
    }

    func fetchInspect(name: String) {
        isLoadingInspect = true
        ChannelManager.shared.invokeDataMethod(
            "getContainerInspect",
            arguments: ["name": name]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingInspect = false
                if let text = result as? String {
                    self?.inspectText = text
                }
            }
        }
    }

    /// 启动/停止容器（toggleContainerState 通道：id + 目标 state）。
    func toggleState(id: String, to state: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "toggleContainerState",
            arguments: ["id": id, "state": state]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 重启容器（restartContainer 通道）。
    func restart(id: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "restartContainer",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

    /// 删除容器（deleteContainer 通道）。
    func deleteContainer(id: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteContainer",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                completion(success)
            }
        }
    }

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
                    let cpuUsage = dict["cpuUsage"] as? Double
                    let memoryUsage = dict["memoryUsage"] as? Double
                    return ContainerModel(originalId: originalId, name: name, image: image, state: state, cpuUsage: cpuUsage, memoryUsage: memoryUsage)
                }
            }
        }
    }
}
