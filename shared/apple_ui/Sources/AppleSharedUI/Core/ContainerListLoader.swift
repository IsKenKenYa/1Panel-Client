import Foundation

/// 容器列表与容器写操作的共享状态。
/// 平台 target 注入自身的 `DataChannel` 实现，因此 iOS 与 macOS 复用同一套解析与写语义。
@MainActor
public final class ContainerListLoader: ObservableObject {
    private let channel: any DataChannel

    @Published public private(set) var containers: [ContainerSummary] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var isProcessing = false
    @Published public var errorMessage: String?

    public init(channel: any DataChannel) {
        self.channel = channel
    }

    public var isBusy: Bool { isLoading || isProcessing }

    public func fetchContainers(loadFailedFallback: String = "Failed to load") async {
        guard !isBusy else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let result = try await channel.invoke("getContainers", arguments: nil)
            guard let rows = result as? [[String: Any]] else {
                errorMessage = loadFailedFallback
                return
            }
            containers = ContainerSummary.parseList(rows)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func toggleContainerState(
        id: String,
        currentState: String,
        failureFallback: String = "Operation failed"
    ) async {
        await performWrite(
            "toggleContainerState",
            arguments: ["id": id, "state": currentState],
            failureFallback: failureFallback
        )
    }

    public func restartContainer(id: String, failureFallback: String = "Operation failed") async {
        await performWrite(
            "restartContainer",
            arguments: ["id": id],
            failureFallback: failureFallback
        )
    }

    public func deleteContainer(id: String, failureFallback: String = "Operation failed") async {
        await performWrite(
            "deleteContainer",
            arguments: ["id": id],
            failureFallback: failureFallback
        )
    }

    /// 强制停止容器（`killContainer` 通道）。
    public func killContainer(id: String, failureFallback: String = "Operation failed") async {
        await performWrite(
            "killContainer",
            arguments: ["id": id],
            failureFallback: failureFallback
        )
    }

    /// 暂停容器（`pauseContainer` 通道）。
    public func pauseContainer(id: String, failureFallback: String = "Operation failed") async {
        await performWrite(
            "pauseContainer",
            arguments: ["id": id],
            failureFallback: failureFallback
        )
    }

    /// 恢复已暂停容器（`unpauseContainer` 通道）。
    public func unpauseContainer(id: String, failureFallback: String = "Operation failed") async {
        await performWrite(
            "unpauseContainer",
            arguments: ["id": id],
            failureFallback: failureFallback
        )
    }

    /// 从设备选择文件上传到容器目录（`uploadFilesToContainer` 通道）。
    /// 用户取消选择时返回 `cancelled`，不算失败。
    public func uploadFiles(
        containerId: String,
        path: String,
        failureFallback: String = "Operation failed"
    ) async -> Bool {
        guard !isBusy else { return false }
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await channel.invoke(
                "uploadFilesToContainer",
                arguments: ["containerId": containerId, "path": path]
            ) as? [String: Any]
            if result?["success"] as? Bool == true { return true }
            if result?["cancelled"] as? Bool == true { return false }
            errorMessage = result?["error"] as? String ?? failureFallback
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    /// 删除容器内文件（`deleteContainerFiles` 通道）。
    public func deleteFiles(
        containerId: String,
        paths: [String],
        failureFallback: String = "Operation failed"
    ) async {
        await performWrite(
            "deleteContainerFiles",
            arguments: ["containerId": containerId, "paths": paths],
            failureFallback: failureFallback
        )
    }

    /// 容器日志（`getContainerLogs` 通道）。
    public func loadLogs(name: String, tail: String = "500") async throws -> String {
        let result = try await channel.invoke(
            "getContainerLogs",
            arguments: ["name": name, "tail": tail]
        )
        guard let logs = result as? String else {
            throw CocoaError(.coderInvalidValue)
        }
        return logs
    }

    private func performWrite(
        _ method: String,
        arguments: [String: Any],
        failureFallback: String
    ) async {
        guard !isBusy else { return }
        errorMessage = nil
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await channel.invoke(method, arguments: arguments)
                as? [String: Any]
            guard result?["success"] as? Bool == true else {
                errorMessage = result?["error"] as? String ?? failureFallback
                return
            }
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        await fetchContainers()
    }
}
