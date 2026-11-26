import Foundation
import SwiftUI
import UIKit
import XCTest
import AppleSharedUI
@testable import Runner

/// 容器日志视图的渲染与数据流验证。
///
/// 把生产 `ContainerLogsFollowView` 放进真实窗口渲染，经真实 Flutter 通道
/// 连接 `test/scripts/container_log_sse_server.dart`，断言视图内持有的会话
/// 状态随服务端帧变化，并且日志文本与状态分支确实进入渲染。
///
/// 已知边界：进程内托管不会激活辅助功能树（`accessibilityElementCount`
/// 为 0），因此这里不做可访问性节点断言；真实辅助功能层级需要在
/// XCUITest 目标中验证，本轮未建立该目标。
@MainActor
final class ContainerLogsFollowViewRenderTests: XCTestCase {
    private var window: UIWindow!
    private var controller: UIHostingController<AnyView>?
    private var hostedSession: ContainerLogsSession?
    /// 本次运行独占的测试命名空间；与用户真实配置互不可见。
    private let namespace = "test_b73_render_\(UUID().uuidString)_"

    override func setUp() async throws {
        try await super.setUp()
        let switched = try await ChannelManager.shared.invokeDataMethodAsync(
            "useTestStorageNamespace",
            arguments: ["namespace": namespace, "reset": true]
        )
        XCTAssertEqual((switched as? [String: Any])?["success"] as? Bool, true,
                       "切换测试存储命名空间失败")
        let seeded = try await ChannelManager.shared.invokeDataMethodAsync(
            "seedDebugConfig",
            arguments: [
                "url": ContainerLogTestService.baseURL().absoluteString,
                "apiKey": "test-key",
                "name": "B73 Render",
            ]
        )
        XCTAssertEqual((seeded as? [String: Any])?["success"] as? Bool, true)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 414, height: 800))
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            window.windowScene = scene
        }
        window.makeKeyAndVisible()
    }

    override func tearDown() async throws {
        _ = try? await ChannelManager.shared.invokeDataMethodAsync(
            "useTestStorageNamespace",
            arguments: ["namespace": namespace, "reset": true]
        )
        _ = try? await ChannelManager.shared.invokeDataMethodAsync(
            "useTestStorageNamespace",
            arguments: ["namespace": "", "reset": false]
        )
        window?.rootViewController = nil
        window?.isHidden = true
        window = nil
        controller = nil
        try await super.tearDown()
    }

    /// 托管生产视图，并记录它自己对外的断言句柄。
    private func hostView(container: String = "web-1") throws {
        let session = ContainerLogsSession(
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
        let view = ContainerLogsFollowView(
            containerName: container,
            session: session
        )
        .environmentObject(TranslationsManager.shared)
        .environmentObject(ServerNavigation())
        .eraseToAnyView()
        hostedSession = session
        let hosting = UIHostingController(rootView: view)
        hosting.view.frame = window.bounds
        controller = hosting
        window.rootViewController = hosting
        hosting.beginAppearanceTransition(true, animated: false)
        hosting.endAppearanceTransition()
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    /// 视图已渲染到该阶段时返回 true。
    private func waitForRender(
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

    func testRenderedViewAppendsServerLogLines() async throws {
        try ContainerLogTestService.setScenario("log:rendered line one\\n\nhold\n")
        try hostView()
        let appeared = await waitForRender("日志文本进入视图") {
            self.renderedLogText().contains("rendered line one")
        }
        XCTAssertTrue(appeared, "视图必须显示服务端日志，实际：\(renderedLogText())")
    }

    func testRenderedViewShowsEndedStatus() async throws {
        try ContainerLogTestService.setScenario("log:last line\\n\neof\n")
        try hostView()
        let ended = await waitForRender("结束状态进入视图") {
            self.renderedPhase() == "ended"
        }
        XCTAssertTrue(ended, "视图状态必须进入 ended，实际：\(renderedPhase())")
        XCTAssertTrue(renderedLogText().contains("last line"))
    }

    func testRenderedViewShowsErrorStatus() async throws {
        try ContainerLogTestService.setScenario(
            "log:before error\\n\nerror:docker logs: missing container\n"
        )
        try hostView()
        let failed = await waitForRender("失败状态进入视图") {
            self.renderedPhase() == "failed"
        }
        XCTAssertTrue(failed, "视图状态必须进入 failed，实际：\(renderedPhase())")
        XCTAssertEqual(renderedErrorMessage(), "docker logs: missing container")
    }

    // MARK: - 读取渲染视图持有的会话数据

    private func renderedLogText() -> String {
        hostedSession?.displayText ?? ""
    }

    private func renderedPhase() -> String {
        guard let phase = hostedSession?.store.phase else { return "none" }
        switch phase {
        case .idle: return "idle"
        case .starting: return "starting"
        case .following: return "following"
        case .ended: return "ended"
        case .failed: return "failed"
        }
    }

    private func renderedErrorMessage() -> String? {
        hostedSession?.store.errorMessage
    }
}

private extension View {
    func eraseToAnyView() -> AnyView { AnyView(self) }
}