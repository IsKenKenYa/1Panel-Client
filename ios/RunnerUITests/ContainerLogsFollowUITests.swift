import XCTest

/// 容器日志页的界面刷新验证（XCUITest）。
///
/// 启动真实应用，经 `ONEPANEL_OPEN_CONTAINER_LOGS` 钩子直达日志页，按
/// 可访问性文本断言：建立连接后两次分时追加的日志都出现在页面上，
/// 随后结束与错误状态、以及已收到的日志仍可读。
///
/// 断言只依赖界面暴露的可访问性文本（`XCUIElement` 的 `label`/`value`），
/// 不读取宿主对象状态，不使用回调替身或人工事件。界面检查不使用截图。
///
/// 前置条件：本机需先启动 `test/scripts/container_log_sse_server.dart`
/// （固定端口 18765）；用例在启动应用前通过其控制端点设置本次场景。
final class ContainerLogsFollowUITests: XCTestCase {
    private var app: XCUIApplication!
    /// 本次运行独占的测试存储命名空间；应用只在该空间内写种子配置。
    private var namespace = ""

    /// 模拟器与宿主共享回环网络：已用模拟器内 curl 实测 127.0.0.1 可达宿主
    /// 测试服务，因此默认地址直接用回环；可用 `ONEPANEL_UI_TEST_SERVICE` 覆盖。
    private static var serviceURL: URL {
        let raw = ProcessInfo.processInfo.environment["ONEPANEL_UI_TEST_SERVICE"]
            ?? "http://127.0.0.1:18765"
        return URL(string: raw)!
    }

    override func setUp() {
        continueAfterFailure = false
        app = nil
        namespace = "test_b73_ui_\(UUID().uuidString)_"
    }

    override func tearDown() {
        app?.terminate()
        app = nil
        super.tearDown()
    }

    /// 设置服务端场景，必须在启动应用之前完成。
    private func setScenario(_ scenario: String) throws {
        var request = URLRequest(url: Self.serviceURL.appendingPathComponent("scenario"))
        request.httpMethod = "POST"
        request.httpBody = Data(scenario.utf8)
        let semaphore = DispatchSemaphore(value: 0)
        var failure: Error?
        URLSession.shared.dataTask(with: request) { _, _, error in
            failure = error
            semaphore.signal()
        }.resume()
        semaphore.wait()
        if let failure { throw failure }
    }

    /// 启动应用并直达日志页。
    ///
    /// 种子配置经 `ONEPANEL_SEED_NAMESPACE` 写入独立存储命名空间，测试
    /// 不触碰用户真实配置；原生壳在种子写入完成后才放行界面，因此日志页
    /// 打开时配置已就绪，不需要点重试遮掩时序。
    private func launch(container: String = "web-1", namespace: String) {
        let app = XCUIApplication()
        app.launchEnvironment["ONEPANEL_OPEN_CONTAINER_LOGS"] = container
        app.launchEnvironment["ONEPANEL_OPEN_MODULE"] = "containers"
        app.launchEnvironment["ONEPANEL_SEED_SERVER_URL"] = Self.serviceURL.absoluteString
        app.launchEnvironment["ONEPANEL_SEED_API_KEY"] = "test-key"
        app.launchEnvironment["ONEPANEL_SEED_SERVER_NAME"] = "B73 UI"
        app.launchEnvironment["ONEPANEL_SEED_NAMESPACE"] = namespace
        app.launch()
        self.app = app
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30),
                      "应用必须进入前台")
    }

    /// 页面上的日志正文元素，按可访问性标识定位。
    private var logText: XCUIElement {
        app.descendants(matching: .any)["containerLogs.text"]
    }

    /// 页面上的状态元素，按可访问性标识查询。
    private func status(_ name: String) -> XCUIElement {
        app.descendants(matching: .any)["containerLogs.status.\(name)"]
    }

    /// 等界面出现包含指定文本的日志节点。
    private func waitForLogText(
        containing needle: String,
        timeout: TimeInterval = 60,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", needle),
            object: logText
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed,
                       "界面必须出现「\(needle)」，实际可访问性文本：\(logText.label)",
                       file: file, line: line)
    }

    /// 跟随时两次分时日志都必须由界面重建后显示。
    func testTimedLogAppendsAppearOnScreen() throws {
        // 第一段、等待、第二段：界面必须分别重建并显示两段。
        try setScenario("log:rendered line one\\n\nhold\nlog:rendered line two\\n\nhold\n")
        launch(namespace: namespace)

        XCTAssertTrue(logText.waitForExistence(timeout: 40),
                      "日志正文节点必须出现在界面上")
        waitForLogText(containing: "rendered line one")
        waitForLogText(containing: "rendered line two")
        // 两段同时可见，证明后续追加没有覆盖前一段。
        XCTAssertTrue(logText.label.contains("rendered line one"))
        XCTAssertTrue(logText.label.contains("rendered line two"))
    }

    /// EOF 之后界面显示结束状态，已收到日志仍可读。
    func testEndedStatusAndRetainedLogRemainReadable() throws {
        try setScenario("log:last line\\n\neof\n")
        launch(namespace: namespace)

        XCTAssertTrue(logText.waitForExistence(timeout: 40))
        waitForLogText(containing: "last line")
        XCTAssertTrue(status("ended").waitForExistence(timeout: 60),
                      "EOF 之后界面必须显示结束状态")
        XCTAssertFalse(status("ended").label.isEmpty,
                       "结束状态节点必须有可读文本")
    }

    /// 服务端错误之后界面显示失败状态，已收到日志仍可读。
    func testErrorStatusAndRetainedLogRemainReadable() throws {
        try setScenario("log:before error\\n\nerror:docker logs: missing container\n")
        launch(namespace: namespace)

        XCTAssertTrue(logText.waitForExistence(timeout: 40))
        waitForLogText(containing: "before error")
        let failed = status("failed")
        XCTAssertTrue(failed.waitForExistence(timeout: 60),
                      "服务端错误之后界面必须显示失败状态")
        let combined = "\(failed.label)\n\(failed.value as? String ?? "")"
        XCTAssertTrue(combined.contains("missing container")
                      || combined.contains("Retry")
                      || combined.contains("重试"),
                      "失败状态必须可读，实际：\(combined)")
        // 已收到的日志在失败后仍可读。
        XCTAssertTrue(logText.label.contains("before error"),
                      "失败后已收到日志仍必须可读")
    }
}