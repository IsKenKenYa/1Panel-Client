import Combine
import Foundation

/// 容器日志跟随流的共享状态。
///
/// Dart 侧订阅 SSE 后逐块回调，这里累积文本并在结束时置位；
/// 取消订阅时通知 Dart 停止，避免服务端连接悬挂。
@MainActor
public final class ContainerLogStreamStore: ObservableObject {
    @Published public private(set) var text = ""
    @Published public private(set) var isFollowing = false
    @Published public private(set) var errorMessage: String?

    private let start: @MainActor (String, String?, @escaping (String) -> Void,
        @escaping () -> Void, @escaping (String) -> Void) async throws -> Void
    private let stop: @MainActor () async -> Void

    public init(
        start: @escaping @MainActor (
            String,
            String?,
            @escaping (String) -> Void,
            @escaping () -> Void,
            @escaping (String) -> Void
        ) async throws -> Void,
        stop: @escaping @MainActor () async -> Void
    ) {
        self.start = start
        self.stop = stop
    }

    /// 开始跟随容器日志。
    public func follow(container: String, tail: String? = "200") async {
        guard !isFollowing else { return }
        text = ""
        errorMessage = nil
        isFollowing = true
        do {
            try await start(container, tail, { [weak self] chunk in
                Task { @MainActor in
                    guard let self, self.isFollowing else { return }
                    self.text += chunk
                }
            }, { [weak self] in
                Task { @MainActor in self?.isFollowing = false }
            }, { [weak self] message in
                Task { @MainActor in
                    self?.errorMessage = message
                    self?.isFollowing = false
                }
            })
        } catch {
            errorMessage = error.localizedDescription
            isFollowing = false
        }
    }

    /// 停止跟随。
    public func stopFollowing() async {
        guard isFollowing else { return }
        isFollowing = false
        await stop()
    }
}