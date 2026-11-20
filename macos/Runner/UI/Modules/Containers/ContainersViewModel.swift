import AppleSharedUI
import Combine
import Foundation

/// 容器行沿用共享包的模型定义，列表与详情共用同一份字段语义。
typealias ContainerModel = ContainerSummary

/// macOS 容器模块的视图模型：加载与写操作全部委托给共享包的
/// `ContainerListLoader`，本文件只保留通道注入与文案兜底。
@MainActor
final class ContainersViewModel: ObservableObject {
    let loader: ContainerListLoader
    private var loaderSubscription: AnyCancellable?

    init(channel: any DataChannel = MacOSDataChannel(channelManager: .shared)) {
        let loader = ContainerListLoader(channel: channel)
        self.loader = loader
        // 共享加载器自身发布变化，转交给本视图模型避免 SwiftUI 漏掉刷新。
        loaderSubscription = loader.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var containers: [ContainerSummary] { loader.containers }
    var isLoading: Bool { loader.isLoading }
    var isProcessing: Bool { loader.isProcessing }
    var isBusy: Bool { loader.isBusy }

    var errorMessage: String? {
        get { loader.errorMessage }
        set { loader.errorMessage = newValue }
    }

    func fetchLogs(name: String, tail: String = "500") async throws -> String {
        try await loader.loadLogs(name: name, tail: tail)
    }

    func fetchContainers() async {
        await loader.fetchContainers(loadFailedFallback: fallback("commonLoadFailedTitle"))
    }

    func toggleContainerState(id: String, currentState: String) async {
        await loader.toggleContainerState(
            id: id,
            currentState: currentState,
            failureFallback: fallback("commonOperationFailed")
        )
    }

    func restartContainer(id: String) async {
        await loader.restartContainer(
            id: id,
            failureFallback: fallback("commonOperationFailed")
        )
    }

    func deleteContainer(id: String) async {
        await loader.deleteContainer(
            id: id,
            failureFallback: fallback("commonOperationFailed")
        )
    }

    private func fallback(_ key: String) -> String {
        TranslationsManager.shared.get(key, fallback: "Operation failed")
    }
}
