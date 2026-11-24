import Combine
import Foundation

/// 容器日志跟随流的共享状态。
///
/// Dart 侧订阅 SSE 后逐块回调，这里累积文本并维护连接阶段；
/// 每次跟随分配新的代次，停止后旧代次的回调即使到达也会被丢弃。
/// 跟随文本按上限保留尾部，长时间连接不会无限增长。
@MainActor
public final class ContainerLogStreamStore: ObservableObject {
    /// 日志流阶段。
    public enum Phase: Equatable {
        case idle
        case starting
        case following
        case ended
        case failed
    }

    @Published public private(set) var text = ""
    @Published public private(set) var phase: Phase = .idle
    @Published public private(set) var errorMessage: String?
    /// 文本每次变化时递增，供视图滚动到底部使用。
    @Published public private(set) var revision = 0

    /// 正在连接或已经处于跟随状态。
    public var isActive: Bool { phase == .starting || phase == .following }
    /// 流已由服务端正常结束。
    public var hasEnded: Bool { phase == .ended }
    /// 正在接收后续日志。
    public var isFollowing: Bool { phase == .following }

    private static let maxCharacters = 700_000
    private static let retainedCharacters = 500_000

    private let start: @MainActor (String, String?, @escaping (String) -> Void,
        @escaping () -> Void, @escaping (String) -> Void) async throws -> Int
    private let stop: @MainActor (Int) async -> Void

    private var generation = 0
    private var characterCount = 0
    /// 对象永久结束标记：`close()` 置位后不再接受新的跟随。
    private var isClosed = false
    /// 本次订阅的归属句柄，由 start 返回，stop 只按它终止。
    private var handle: Int?
    private var pendingStop: Task<Void, Never>?
    private var pendingStopToken = UUID()

    public init(
        start: @escaping @MainActor (
            String,
            String?,
            @escaping (String) -> Void,
            @escaping () -> Void,
            @escaping (String) -> Void
        ) async throws -> Int,
        stop: @escaping @MainActor (Int) async -> Void
    ) {
        self.start = start
        self.stop = stop
    }

    /// 开始跟随容器日志。
    ///
    /// 等上一次停止完成后才发起新的订阅，避免快速停止再恢复时
    /// 通道上的停止请求晚于开始请求到达。
    public func follow(container: String, tail: String? = "200") async {
        while let pending = pendingStop {
            await pending.value
            // 停止完成到清空 pendingStop 之间需要让出主 actor，
            // 否则会在已完成的任务上原地循环。
            await Task.yield()
        }
        guard !isClosed, !isActive else { return }
        generation += 1
        let run = generation
        text = ""
        characterCount = 0
        errorMessage = nil
        phase = .starting
        do {
            let opened = try await start(container, tail, { [weak self] chunk in
                Task { @MainActor in
                    self?.append(chunk, generation: run)
                }
            }, { [weak self] in
                Task { @MainActor in
                    guard let self, self.generation == run else { return }
                    self.phase = .ended
                }
            }, { [weak self] message in
                Task { @MainActor in
                    guard let self, self.generation == run else { return }
                    self.errorMessage = message
                    self.phase = .failed
                }
            })
            guard generation == run else {
                // 开始期间已被停止覆盖，立即结束这个刚建立的订阅。
                await stop(opened)
                return
            }
            handle = opened
            if phase == .starting {
                phase = .following
            }
        } catch {
            if generation == run {
                errorMessage = error.localizedDescription
                phase = .failed
            }
        }
    }

    /// 停止跟随，保留当前文本。
    ///
    /// 只终止本实例持有的订阅；其他页面新建的连接不受影响。
    public func stopFollowing() async {
        generation += 1
        phase = .idle
        errorMessage = nil
        let owned = handle
        handle = nil
        let token = UUID()
        pendingStopToken = token
        let task = Task {
            if let owned { await stop(owned) }
        }
        pendingStop = task
        await task.value
        if pendingStopToken == token {
            pendingStop = nil
        }
    }

    /// 结束视图生命周期：停止订阅并拒绝后续开始。
    ///
    /// 适用对象永久结束的视图（关闭弹窗、切换容器）；暂时离开的页面
    /// 应使用 `stopFollowing()`，让跟随意愿在返回时继续生效。
    public func close() async {
        isClosed = true
        await stopFollowing()
    }

    /// 供测试与诊断读取当前订阅句柄。
    public var activeHandle: Int? { handle }

    private func append(_ chunk: String, generation run: Int) {
        guard generation == run, isActive else { return }
        text.append(chunk)
        characterCount += chunk.count
        if characterCount > Self.maxCharacters {
            let drop = characterCount - Self.retainedCharacters
            let start = text.index(text.startIndex, offsetBy: drop)
            let tail = text[start...]
            if let newline = tail.firstIndex(of: "\n") {
                text = String(tail[tail.index(after: newline)...])
            } else {
                text = String(tail)
            }
            characterCount = text.count
        }
        revision += 1
    }
}