import Foundation
import XCTest
import AppleSharedUI
@testable import Runner

/// 容器日志跟随的真实链路测试。
///
/// 全部用例经真实 Flutter 通道（`ChannelManager` → Dart → SSE 客户端）连接
/// 测试进程外的真实服务 `test/scripts/container_log_sse_server.dart`。该服务
/// 用 `dart:io` 的 HttpServer 实现 HTTP 与 SSE，按上游 `container.go` 的格式
/// 推送普通帧 `data: <base64>` 与 `event: error` 明文；快照走生产
/// `getContainerLogs` 通道。没有回调替身、空 stop、人工成功事件或手写协议解析。
///
/// 测试隔离：`setUp` 先经 `useTestStorageNamespace` 把配置读写切到独立命名
/// 空间并重置该空间，`tearDown` 只切回用户命名空间，不加 `reset`：切回时
/// 清空会删除用户真实条目。
@MainActor
final class ContainerLogStreamTests: XCTestCase {
    /// 本次运行独占的测试命名空间；随机后缀避免并行运行互相干扰。
    private let namespace = "test_b73_\(UUID().uuidString)_"

    override func setUp() async throws {
        try await super.setUp()
        try await useNamespace(reset: true)
        let seeded = try await ChannelManager.shared.invokeDataMethodAsync(
            "seedDebugConfig",
            arguments: [
                "url": ContainerLogTestService.baseURL().absoluteString,
                "apiKey": "test-key",
                "name": "B73 Real Stream",
            ]
        )
        let payload = seeded as? [String: Any]
        XCTAssertEqual(payload?["success"] as? Bool, true,
                       "seedDebugConfig failed: \(payload ?? [:])")
    }

    override func tearDown() async throws {
        _ = try? await ChannelManager.shared.invokeDataMethodAsync(
            "stopContainerLogStream",
            arguments: ["requestID": 0]
        )
        try await useNamespace(reset: false, namespace: "")
        try await super.tearDown()
    }

    /// 切换配置存储命名空间；`reset` 只清空目标命名空间内的条目。
    private func useNamespace(
        reset: Bool,
        namespace: String? = nil
    ) async throws {
        let target = namespace ?? self.namespace
        let raw = try await ChannelManager.shared.invokeDataMethodAsync(
            "useTestStorageNamespace",
            arguments: ["namespace": target, "reset": reset]
        )
        let payload = raw as? [String: Any]
        XCTAssertEqual(payload?["success"] as? Bool, true,
                       "useTestStorageNamespace failed: \(payload ?? [:])")
        // 配置存储切换后重新读取服务器目录，确认测试空间确实是空的。
        if reset && !target.isEmpty {
            let servers = try await ChannelManager.shared.invokeDataMethodAsync("getServers")
            XCTAssertEqual((servers as? [[String: Any]])?.count, 0,
                           "测试命名空间必须为空，不能复用用户配置")
        }
    }

    private func waitFor(
        _ description: String,
        timeout: TimeInterval = 15,
        _ predicate: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate() {
            if Date() > deadline {
                XCTFail("timed out: \(description)")
                return
            }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    /// 生产快照链路：`getContainerLogs` 通道 → Dart 服务 → 1Panel API。
    private static func productionSnapshot(container: String) async throws -> String {
        let result = try await ChannelManager.shared.invokeDataMethodAsync(
            "getContainerLogs",
            arguments: ["name": container, "tail": "200"]
        )
        guard let text = result as? String else {
            throw NSError(domain: "snapshot", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "快照返回非文本"])
        }
        return text
    }

    private func makeSession(
        container: String = "web-1"
    ) -> ContainerLogsSession {
        ContainerLogsSession(
            container: container,
            store: ContainerLogStreamStore(
                start: { container, tail, onChunk, onDone, onError in
                    try await ChannelManager.shared.startContainerLogStream(
                        container: container, tail: tail,
                        onChunk: onChunk, onDone: onDone, onError: onError)
                },
                stop: { handle in
                    await ChannelManager.shared.stopContainerLogStream(handle: handle)
                }
            ),
            fetchSnapshot: {
                try await Self.productionSnapshot(container: container)
            }
        )
    }

    // MARK: - 正常日志流

    func testFollowsRealServerLogFrames() async throws {
        try ContainerLogTestService.setScenario("log:first line\\n\neof\n")
        let session = makeSession()
        await session.appear()

        try await waitFor("log chunk") {
            session.store.text.contains("first line")
        }
        XCTAssertEqual(session.store.phase, .ended)
        XCTAssertNil(session.store.errorMessage)
    }

    func testErrorFrameKeepsLogsAndReportsServerMessage() async throws {
        try ContainerLogTestService.setScenario(
            "log:line before error\\n\nerror:docker logs: no such container\n"
        )
        let session = makeSession()
        await session.appear()

        try await waitFor("failure") { session.store.phase == .failed }
        XCTAssertTrue(session.store.text.contains("line before error"))
        XCTAssertEqual(session.store.errorMessage,
                       "docker logs: no such container")
        XCTAssertFalse(session.store.isActive)
    }

    /// 长错误不能在基础通道被截断：通道保留全文，展示层才限长。
    func testLongServerErrorSurvivesChannelIntact() async throws {
        let fullError = "docker logs failed: " + String(repeating: "very long reason ", count: 20)
        try ContainerLogTestService.setScenario(
            "log:before\\n\nerror:\(fullError)\\n"
        )
        let session = makeSession()
        await session.appear()

        try await waitFor("failure") { session.store.phase == .failed }
        let received = session.store.errorMessage ?? ""
        // SSE 的 data 行按协议舍去行尾空白，比较时按同一规则处理。
        XCTAssertEqual(received.trimmingCharacters(in: .whitespaces),
                       fullError.trimmingCharacters(in: .whitespaces),
                       "通道必须保留完整原始错误")
        XCTAssertGreaterThan(received.count, LogStreamErrorText.displayLimit)
        let display = LogStreamErrorText.display(received) ?? ""
        XCTAssertLessThanOrEqual(display.count, LogStreamErrorText.displayLimit,
                                 "展示层按规范截断")
    }

    /// 暂时离开后紧接着点重试：不可见期间不得重新建立订阅。
    func testRetryWhileHiddenDoesNotSubscribe() async throws {
        let baseline = try ContainerLogTestService.status()
        try ContainerLogTestService.setScenario("log:first\\n\nhold\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("first") { !session.store.text.isEmpty }

        await session.leave()
        let startedAfterLeave = try ContainerLogTestService.status().started
        await session.retry()
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(try ContainerLogTestService.status().started, startedAfterLeave,
                       "不可见期间的重试不得建立订阅")
        XCTAssertEqual(session.store.phase, .idle)
        XCTAssertTrue(session.wantsFollow)

        // 重新出现后按意愿恢复。
        try ContainerLogTestService.setScenario("log:after reappear\\n\n")
        await session.appear()
        try await waitFor("reappear") {
            session.store.text.contains("after reappear")
        }
        XCTAssertGreaterThanOrEqual(
            try ContainerLogTestService.status().started,
            baseline.started + 2
        )
    }

    func testEofEndsFollowNormally() async throws {
        try ContainerLogTestService.setScenario("log:only line\\n\neof\n")
        let session = makeSession()
        await session.appear()

        try await waitFor("ended") { session.store.phase == .ended }
        XCTAssertTrue(session.store.text.contains("only line"))
        XCTAssertNil(session.store.errorMessage)
        XCTAssertTrue(session.store.hasEnded)
    }

    // MARK: - 停止、恢复与归属

    func testStopKeepsTextAndProductionSnapshotLoads() async throws {
        try ContainerLogTestService.setScenario("log:during follow\\n\nhold\n")
        try ContainerLogTestService.setSnapshot("snapshot body\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("first chunk") { !session.store.text.isEmpty }

        await session.setFollow(false)
        XCTAssertEqual(session.store.phase, .idle)
        XCTAssertTrue(session.store.text.contains("during follow"))
        // 生产快照链路真实执行并到达服务端。
        try await waitFor("snapshot loaded") { session.snapshot != nil }
        XCTAssertTrue(session.snapshot?.contains("snapshot body") ?? false)
        XCTAssertNil(session.snapshotError)
        XCTAssertTrue(session.displayText.contains("during follow"),
                      "已收到日志优先于快照")
    }

    func testSnapshotFailureKeepsReceivedText() async throws {
        try ContainerLogTestService.setScenario("log:received\\n\nhold\n")
        // 不设置快照内容：服务端按生产失败路径返回 500。
        try ContainerLogTestService.setSnapshot(nil)
        let session = makeSession()
        await session.appear()
        try await waitFor("received") { !session.store.text.isEmpty }

        await session.setFollow(false)
        try await waitFor("snapshot failure") { session.snapshotError != nil }
        XCTAssertTrue(session.displayText.contains("received"),
                      "快照失败不能遮盖已收到日志")
        XCTAssertFalse(session.snapshotError?.isEmpty ?? true)
    }

    func testRapidRestartKeepsLatestStreamOnly() async throws {
        try ContainerLogTestService.setScenario("log:round one\\n\nhold\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("round one") { !session.store.text.isEmpty }

        await session.setFollow(false)
        try ContainerLogTestService.setScenario("log:round two\\n\n")
        await session.setFollow(true)

        try await waitFor("round two") { session.store.text.contains("round two") }
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(session.store.text.contains("round one"),
                       "旧订阅的内容不得混入")
        XCTAssertEqual(session.store.text.components(separatedBy: "round two").count - 1,
                       1, "新一轮内容不得重复")
    }

    /// 多实例并存：旧实例的停止不得取消新实例的连接。
    func testOldSessionStopDoesNotCancelNewSession() async throws {
        try ContainerLogTestService.setScenario("log:shared stream\nhold\n")
        let first = makeSession(container: "a")
        let second = makeSession(container: "b")
        await first.appear()
        try await waitFor("first connected") { first.store.phase == .following }
        await second.appear()
        try await waitFor("second connected") { second.store.phase == .following }

        await first.setFollow(false)
        // Dart 侧仍是第二个实例的订阅，仍能收到新的帧。
        try ContainerLogTestService.setScenario("log:after old stop\neof\n")
        await second.setFollow(false)
        await second.setFollow(true)
        try await waitFor("second still live") {
            second.store.text.contains("after old stop")
        }
        XCTAssertEqual(second.store.phase, .ended)
    }

    // MARK: - 生命周期

    func testLeaveKeepsWantsFollowAndAppearResumes() async throws {
        try ContainerLogTestService.setScenario("log:before leave\nhold\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("before leave") { !session.store.text.isEmpty }

        await session.leave()
        XCTAssertTrue(session.wantsFollow)
        XCTAssertEqual(session.store.phase, .idle)

        try ContainerLogTestService.setScenario("log:after appear\neof\n")
        await session.appear()
        try await waitFor("after appear") { session.store.text.contains("after appear") }
        XCTAssertTrue(session.wantsFollow)
    }

    func testFinishRejectsLaterAppear() async throws {
        try ContainerLogTestService.setScenario("log:first\nhold\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("first") { !session.store.text.isEmpty }

        await session.finish()
        try ContainerLogTestService.setScenario("log:not expected\neof\n")
        await session.appear()
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertFalse(session.store.text.contains("not expected"),
                       "关闭后不应再建立订阅")
        XCTAssertEqual(session.store.phase, .idle)
    }

    func testRepeatedAppearKeepsSingleSubscription() async throws {
        let before = try ContainerLogTestService.status().started
        try ContainerLogTestService.setScenario("log:only once\nhold\n")
        let session = makeSession()
        await session.appear()
        await session.appear()
        try await waitFor("only once") { !session.store.text.isEmpty }
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(session.store.revision, 1)
        XCTAssertEqual(try ContainerLogTestService.status().started, before + 1,
                       "重复出现不得再建订阅")
    }

    // MARK: - 取消后服务端连接确已关闭

    /// 直接观察客户端取消导致的服务端连接关闭，不依赖服务端自然 EOF。
    func testStopClosesServerConnection() async throws {
        let baseline = try ContainerLogTestService.status()
        try ContainerLogTestService.setScenario("log:open\\n\nhold\n")
        let session = makeSession()
        await session.appear()
        try await waitFor("open") { !session.store.text.isEmpty }

        await session.setFollow(false)
        try ContainerLogTestService.waitForClientDisconnects(
            baseline.closedByClient + 1
        )
        let status = try ContainerLogTestService.status()
        XCTAssertNil(status.active.first { $0 == "web-1" },
                     "服务端不应再有该容器的活动连接")
        // 本次结束来自客户端取消，服务端自然结束计数不应增加。
        XCTAssertEqual(status.closedByServer, baseline.closedByServer,
                       "本次结束必须来自客户端取消")
    }

    func testSwitchContainerClosesPreviousConnection() async throws {
        let baseline = try ContainerLogTestService.status()
        try ContainerLogTestService.setScenario("log:container a\\n\nhold\n")
        let first = makeSession(container: "a")
        await first.appear()
        try await waitFor("a") { !first.store.text.isEmpty }
        await first.finish()
        try ContainerLogTestService.waitForClientDisconnects(
            baseline.closedByClient + 1
        )

        try ContainerLogTestService.setScenario("log:container b\neof\n")
        let second = makeSession(container: "b")
        await second.appear()
        try await waitFor("b") { second.store.text.contains("container b") }
        XCTAssertFalse(second.store.text.contains("container a"))
    }
}