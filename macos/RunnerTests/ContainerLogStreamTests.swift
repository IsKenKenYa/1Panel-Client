import Foundation
import XCTest
import AppleSharedUI
@testable import onepanel_client

/// 容器日志跟随的真实链路测试（macOS）。
///
/// 全部用例经真实 Flutter 通道（`ChannelManager` → Dart → SSE 客户端）
/// 连接到测试进程内的本地 SSE 服务端，帧格式与上游
/// `agent/app/service/container.go` 一致：普通帧 `data: <base64>`，
/// 失败帧 `event: error` 加明文。没有回调替身与人工成功事件。
@MainActor
final class ContainerLogStreamTests: XCTestCase {
    private var server: ContainerLogTestServer!

    override func setUp() async throws {
        try await super.setUp()
        server = try ContainerLogTestServer()
        server.start()
        let seeded = try await ChannelManager.shared.invokeDataMethodAsync(
            "seedDebugConfig",
            arguments: [
                "url": server.baseURL,
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
            "stopContainerLogStream"
        )
        server?.stop()
        server = nil
        try await super.tearDown()
    }

    private func waitFor(
        _ description: String,
        timeout: TimeInterval = 10,
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

    private func makeSession(
        container: String = "web-1"
    ) -> ContainerLogsSession {
        ContainerLogsSession(
            container: container,
            store: ContainerLogStreamStore(
                start: { container, tail, onChunk, onDone, onError in
                    try await ChannelManager.shared.startContainerLogStream(
                        container: container,
                        tail: tail,
                        onChunk: onChunk,
                        onDone: onDone,
                        onError: onError
                    )
                },
                stop: { await ChannelManager.shared.stopContainerLogStream() }
            ),
            fetchSnapshot: { "" }
        )
    }

    // MARK: - 正常日志流

    func testFollowsRealServerLogFrames() async throws {
        server.respond(with: [
            .log("first line\n"),
            .log("中文日志\n"),
            .error(""),
        ])
        let session = makeSession()
        await session.appear()

        try await waitFor("two log chunks") {
            session.store.text.contains("first line\n")
                && session.store.text.contains("中文日志\n")
        }
        XCTAssertEqual(session.store.text, "first line\n中文日志\n")
        XCTAssertEqual(session.store.revision, 2)
    }

    func testErrorFrameKeepsLogsAndReportsServerMessage() async throws {
        server.respond(with: [
            .log("line before error\n"),
            .error("docker logs: no such container"),
        ])
        let session = makeSession()
        await session.appear()

        try await waitFor("failure") { session.store.phase == .failed }
        XCTAssertEqual(session.store.text, "line before error\n")
        XCTAssertEqual(session.store.errorMessage,
                       "docker logs: no such container")
        XCTAssertFalse(session.store.isActive)
    }

    func testEofEndsFollowNormally() async throws {
        server.respond(with: [.log("only line\n")])
        let session = makeSession()
        await session.appear()

        try await waitFor("ended") { session.store.phase == .ended }
        XCTAssertEqual(session.store.text, "only line\n")
        XCTAssertNil(session.store.errorMessage)
        XCTAssertTrue(session.store.hasEnded)
    }

    // MARK: - 停止与恢复

    func testStopKeepsTextAndResumeReconnects() async throws {
        server.respond(with: [
            .log("during follow\n"),
            .hold,
        ])
        let session = makeSession()
        await session.appear()
        try await waitFor("first chunk") { !session.store.text.isEmpty }

        await session.setFollow(false)
        XCTAssertEqual(session.store.phase, .idle)
        XCTAssertEqual(session.store.text, "during follow\n")
        XCTAssertEqual(session.displayText, "during follow\n")

        server.respond(with: [.log("after resume\n"), .error("")])
        await session.setFollow(true)
        try await waitFor("resumed chunk") {
            session.store.text.contains("after resume\n")
        }
        XCTAssertFalse(session.store.text.contains("during follow\n"),
                       "新订阅必须清空上一轮文本")
    }

    func testLateCallbacksFromPreviousFollowAreIgnored() async throws {
        server.respond(with: [.log("round one\n"), .hold])
        let session = makeSession()
        await session.appear()
        try await waitFor("round one") { !session.store.text.isEmpty }

        await session.setFollow(false)
        server.respond(with: [.log("round two\n"), .error("")])
        await session.setFollow(true)

        try await waitFor("round two") {
            session.store.text.contains("round two\n")
        }
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(session.store.text.contains("round one\n"),
                       "旧订阅迟到的帧必须丢弃")
        XCTAssertEqual(session.store.text.components(separatedBy: "round two\n").count - 1,
                       1, "新一轮内容不得重复")
    }

    // MARK: - 生命周期

    func testLeaveKeepsWantsFollowAndAppearResumes() async throws {
        server.respond(with: [.log("before leave\n"), .hold])
        let session = makeSession()
        await session.appear()
        try await waitFor("before leave") { !session.store.text.isEmpty }

        await session.leave()
        XCTAssertTrue(session.wantsFollow)
        XCTAssertEqual(session.store.phase, .idle)

        server.respond(with: [.log("after appear\n"), .error("")])
        await session.appear()
        try await waitFor("after appear") {
            session.store.text.contains("after appear\n")
        }
        XCTAssertTrue(session.wantsFollow)
    }

    func testFinishRejectsLaterAppear() async throws {
        server.respond(with: [.log("first\n"), .hold])
        let session = makeSession()
        await session.appear()
        try await waitFor("first") { !session.store.text.isEmpty }

        await session.finish()
        server.respond(with: [.log("not expected\n"), .error("")])
        await session.appear()
        try await Task.sleep(nanoseconds: 700_000_000)
        XCTAssertFalse(session.store.text.contains("not expected\n"),
                       "关闭后不应再建立订阅")
        XCTAssertEqual(session.store.phase, .idle)
    }

    func testRepeatedAppearKeepsSingleSubscription() async throws {
        server.respond(with: [.log("only once\n"), .hold])
        let session = makeSession()
        await session.appear()
        await session.appear()
        try await waitFor("only once") { !session.store.text.isEmpty }
        try await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(session.store.revision, 1)
    }

    // MARK: - 快照与已收到文本

    func testSnapshotFailureNeverHidesReceivedText() async throws {
        server.respond(with: [.log("received\n"), .hold])
        let store = ContainerLogStreamStore(
            start: { container, tail, onChunk, onDone, onError in
                try await ChannelManager.shared.startContainerLogStream(
                    container: container,
                    tail: tail,
                    onChunk: onChunk,
                    onDone: onDone,
                    onError: onError
                )
            },
            stop: { await ChannelManager.shared.stopContainerLogStream() }
        )
        let session = ContainerLogsSession(
            container: "web-1",
            store: store,
            fetchSnapshot: {
                throw NSError(domain: "snapshot", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "snapshot failed"])
            }
        )
        await session.appear()
        try await waitFor("received") { !store.text.isEmpty }

        await session.setFollow(false)
        XCTAssertEqual(session.snapshotError, "snapshot failed")
        XCTAssertEqual(session.displayText, "received\n",
                       "快照失败不能遮盖已收到日志")
    }

    func testSwitchContainerUsesNewStream() async throws {
        server.respond(with: [.log("container A\n"), .hold])
        let first = makeSession(container: "a")
        await first.appear()
        try await waitFor("A") { !first.store.text.isEmpty }
        await first.finish()

        server.respond(with: [.log("container B\n"), .error("")])
        let second = makeSession(container: "b")
        await second.appear()
        try await waitFor("B") { second.store.text.contains("container B\n") }
        XCTAssertFalse(second.store.text.contains("container A\n"))
    }

    // MARK: - 取消后的连接结束

    func testStopClosesServerConnection() async throws {
        server.respond(with: [.log("open\n"), .hold])
        let session = makeSession()
        await session.appear()
        try await waitFor("open") { !session.store.text.isEmpty }

        await session.setFollow(false)
        server.respond(with: [.log("second\n"), .error("")])
        await session.setFollow(true)
        try await waitFor("second") { session.store.text.contains("second\n") }
    }
}