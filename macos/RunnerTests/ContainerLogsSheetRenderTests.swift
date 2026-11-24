import AppKit
import Foundation
import SwiftUI
import XCTest
import AppleSharedUI
@testable import onepanel_client

/// 容器日志弹窗的渲染与数据流验证（macOS）。
///
/// 把生产 `ContainerLogsSheet` 放进真实窗口托管，经真实 Flutter 通道连接
/// `test/scripts/container_log_sse_server.dart`，断言打开后即按初始跟随意愿
/// 建立连接并收到新日志，不需要先关闭再开启。
@MainActor
final class ContainerLogsSheetRenderTests: XCTestCase {
    private var window: NSWindow!
    private var session: ContainerLogsSession?

    override func setUp() async throws {
        try await super.setUp()
        let seeded = try await ChannelManager.shared.invokeDataMethodAsync(
            "seedDebugConfig",
            arguments: [
                "url": ContainerLogTestService.baseURL().absoluteString,
                "apiKey": "test-key",
                "name": "B73 Render",
            ]
        )
        XCTAssertEqual((seeded as? [String: Any])?["success"] as? Bool, true)
        window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 640, height: 480),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
    }

    override func tearDown() async throws {
        window?.contentViewController = nil
        window?.orderOut(nil)
        window = nil
        session = nil
        try await super.tearDown()
    }

    /// 托管生产弹窗，会话由测试构造以便观察同一实例。
    private func hostSheet(container: String = "web-1") {
        let built = ContainerLogsSession(
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
                stop: { handle in
                    await ChannelManager.shared.stopContainerLogStream(handle: handle)
                }
            ),
            fetchSnapshot: {
                let result = try await ChannelManager.shared.invokeDataMethodAsync(
                    "getContainerLogs",
                    arguments: ["name": container, "tail": "200"]
                )
                return result as? String ?? ""
            }
        )
        session = built
        let view = ContainerLogsSheet(containerName: container, session: built)
            .environmentObject(TranslationsManager.shared)
        let hosting = NSHostingController(rootView: view)
        window.contentViewController = hosting
        window.makeKeyAndOrderFront(nil)
        hosting.view.layoutSubtreeIfNeeded()
    }

    private func waitFor(
        _ description: String,
        timeout: TimeInterval = 20,
        _ predicate: @escaping () -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if predicate() { return true }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTFail("timed out: \(description)")
        return false
    }

    /// 打开弹窗即建立连接，无需用户先关再开。
    func testSheetFollowsOnOpenWithoutToggling() async throws {
        let baseline = try ContainerLogTestService.status()
        try ContainerLogTestService.setScenario("log:opened and streaming\\n\nhold\n")
        hostSheet()

        let started = await waitFor("打开后建立连接") {
            ((try? ContainerLogTestService.status())?.started ?? 0) > baseline.started
        }
        XCTAssertTrue(started, "打开弹窗必须按初始跟随意愿建立连接")

        let received = await waitFor("收到新日志") {
            (self.session?.displayText ?? "").contains("opened and streaming")
        }
        XCTAssertTrue(received,
                      "打开后必须收到新日志，实际：\(session?.displayText ?? "")")
        XCTAssertEqual(session?.wantsFollow, true, "初始开关应与连接状态一致")
    }

    func testSheetEndedStatusReachesView() async throws {
        try ContainerLogTestService.setScenario("log:sheet line\\n\neof\n")
        hostSheet()
        let ended = await waitFor("结束状态") {
            guard let phase = self.session?.store.phase else { return false }
            return phase == .ended
        }
        XCTAssertTrue(ended, "结束状态必须进入弹窗视图")
        XCTAssertTrue((session?.displayText ?? "").contains("sheet line"))
    }
}