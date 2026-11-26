import Foundation
import XCTest

/// XCUITest 诊断：输出启动后界面层级，确认应用是否进入日志页。
///
/// 仅用于定位，正式验收用例见 `ContainerLogsFollowUITests`。
final class ContainerLogsDiagnosticUITests: XCTestCase {
    func testDumpHierarchyAfterLaunch() {
        let app = XCUIApplication()
        app.launchEnvironment["ONEPANEL_OPEN_CONTAINER_LOGS"] = "web-1"
        app.launchEnvironment["ONEPANEL_OPEN_MODULE"] = "containers"
        app.launchEnvironment["ONEPANEL_SEED_SERVER_URL"] = "http://127.0.0.1:18765"
        app.launchEnvironment["ONEPANEL_SEED_API_KEY"] = "test-key"
        app.launchEnvironment["ONEPANEL_SEED_SERVER_NAME"] = "B73 UI"
        app.launch()

        let ready = app.wait(for: .runningForeground, timeout: 30)
        print("DIAG foreground=\(ready)")
        Thread.sleep(forTimeInterval: 8)
        print("DIAG hierarchy start")
        print(app.debugDescription)
        print("DIAG hierarchy end")
        print("DIAG buttons=\(app.buttons.count) staticTexts=\(app.staticTexts.count)")
        for text in app.staticTexts.allElementsBoundByIndex.prefix(30) {
            print("DIAG text label=\(text.label) id=\(text.identifier)")
        }
        // 按标识查询各个状态节点，确认标识是否进入界面树。
        for name in ["text", "status.starting", "status.following", "status.ended",
                     "status.failed", "status.idle"] {
            let element = app.descendants(matching: .any)["containerLogs.\(name)"]
            print("DIAG id containerLogs.\(name) exists=\(element.exists)")
        }
        for button in app.buttons.allElementsBoundByIndex.prefix(20) {
            print("DIAG button label=\(button.label) id=\(button.identifier)")
        }
        print("DIAG serviceStatus=\(serviceStatus())")
    }

    private func serviceStatus() -> String {
        let semaphore = DispatchSemaphore(value: 0)
        var body = ""
        URLSession.shared.dataTask(with: URL(string: "http://127.0.0.1:18765/status")!) { data, _, _ in
            body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            semaphore.signal()
        }.resume()
        semaphore.wait()
        return body
    }
}