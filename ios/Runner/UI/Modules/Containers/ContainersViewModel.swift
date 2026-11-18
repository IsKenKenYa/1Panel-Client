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
    @Published private(set) var loadFailed = false

    /// 容器日志（getContainerLogs 通道，尾部 200 行）。
    @Published var logs: String = ""
    @Published var isLoadingLogs = false
    @Published private(set) var logsFailed = false
    /// 容器 inspect（getContainerInspect 通道，格式化 JSON）。
    @Published var inspectText: String = ""
    @Published var isLoadingInspect = false
    @Published private(set) var inspectFailed = false

    func fetchLogs(name: String, tail: String = "200") {
        guard !isLoadingLogs else { return }
        isLoadingLogs = true
        logsFailed = false
        ChannelManager.shared.invokeDataMethod(
            "getContainerLogs",
            arguments: ["name": name, "tail": tail]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingLogs = false
                guard let text = result as? String else {
                    self.logsFailed = true
                    return
                }
                self.logs = text
            }
        }
    }

    func fetchInspect(name: String) {
        guard !isLoadingInspect else { return }
        isLoadingInspect = true
        inspectFailed = false
        ChannelManager.shared.invokeDataMethod(
            "getContainerInspect",
            arguments: ["name": name]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingInspect = false
                guard let text = result as? String else {
                    self.inspectFailed = true
                    return
                }
                self.inspectText = text
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
        loadFailed = false
        ChannelManager.shared.invokeDataMethod("getContainers") { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                guard let dictArray = result as? [[String: Any]] else {
                    self.loadFailed = true
                    return
                }
                self.containers = dictArray.compactMap { dict in
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
