import Combine
import Foundation

/// 容器日志页的会话状态机。
///
/// 负责三件事，让 iOS 页面与 macOS 弹窗共用同一套行为：
/// - 跟随意愿（`wantsFollow`）与连接状态分离，暂时离开不改变意愿
/// - 已收到的跟随文本优先于快照：停止后的快照加载、失败都不覆盖它
/// - 生命周期：可见时恢复跟随，离开只终止连接，对象永久结束时关闭流
@MainActor
public final class ContainerLogsSession: ObservableObject {
    public let store: ContainerLogStreamStore

    /// 用户的跟随意愿。
    @Published public private(set) var wantsFollow = true
    /// 停止跟随后回放的日志快照。
    @Published public private(set) var snapshot: String?
    @Published public private(set) var snapshotError: String?
    @Published public private(set) var isLoadingSnapshot = false

    private let container: String
    private let fetchSnapshot: @MainActor () async throws -> String
    private var snapshotRequest = 0
    private var visible = false
    private var closed = false
    /// 转发共享状态的变更，让观察会话的视图在日志追加、结束与失败时重建。
    private var storeObservation: AnyCancellable?

    public init(
        container: String,
        store: ContainerLogStreamStore,
        fetchSnapshot: @escaping @MainActor () async throws -> String
    ) {
        self.container = container
        self.store = store
        self.fetchSnapshot = fetchSnapshot
        // 会话本身不复制 store 的字段，也不修改 store，转发不会形成回环。
        storeObservation = store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    /// 停止跟随状态下的显示文本：跟随文本优先，快照只作补充。
    public var displayText: String {
        if !store.text.isEmpty { return store.text }
        return snapshot ?? ""
    }

    /// 页面出现或回到前台：恢复跟随意愿对应的连接。
    public func appear() async {
        visible = true
        await resumeIfWanted()
    }

    /// 页面暂时离开（切换标签、返回上一级、进入后台）：只结束连接。
    public func leave() async {
        visible = false
        snapshotRequest += 1
        await store.stopFollowing()
    }

    /// 页面永久结束（关闭弹窗、组件销毁）：终止订阅并拒绝后续开始。
    public func finish() async {
        visible = false
        closed = true
        snapshotRequest += 1
        await store.close()
    }

    /// 切换跟随意愿。
    ///
    /// 开启时重新建立订阅并清除过期快照状态；关闭时停止订阅并回放快照。
    public func setFollow(_ enabled: Bool) async {
        wantsFollow = enabled
        if enabled {
            snapshot = nil
            snapshotError = nil
            isLoadingSnapshot = false
            snapshotRequest += 1
            await store.follow(container: container)
        } else {
            await stopAndLoadSnapshot()
        }
    }

    /// 错误与结束后的重试入口：恢复跟随并重新建立连接。
    public func retry() async {
        wantsFollow = true
        snapshot = nil
        snapshotError = nil
        isLoadingSnapshot = false
        snapshotRequest += 1
        await store.follow(container: container)
    }

    private func resumeIfWanted() async {
        guard !closed, visible, wantsFollow, !store.isActive else { return }
        snapshot = nil
        snapshotError = nil
        isLoadingSnapshot = false
        snapshotRequest += 1
        await store.follow(container: container)
    }

    private func stopAndLoadSnapshot() async {
        let request = snapshotRequest + 1
        snapshotRequest = request
        isLoadingSnapshot = true
        snapshotError = nil
        await store.stopFollowing()
        guard request == snapshotRequest else { return }
        do {
            let text = try await fetchSnapshot()
            guard request == snapshotRequest else { return }
            snapshot = text
        } catch {
            guard request == snapshotRequest else { return }
            snapshotError = error.localizedDescription
        }
        if request == snapshotRequest {
            isLoadingSnapshot = false
        }
    }
}