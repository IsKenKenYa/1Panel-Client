import Foundation

/// 测试进程外的真实 1Panel 日志服务客户端。
///
/// 服务本体是 `test/scripts/container_log_sse_server.dart`（用 `dart:io`
/// 的 HttpServer 实现 HTTP 与 SSE，本类只负责启动它并调用其控制端点，
/// 不解析任何 HTTP 协议）。测试启动前由外部脚本准备好服务并写出 URL；
/// URL 通过环境变量 `ONEPANEL_LOG_TEST_SERVER` 传入。
enum ContainerLogTestService {
    /// 测试服务端固定端口。
    ///
    /// 模拟器测试宿主读不到启动脚本的 shell 环境变量，因此服务用固定端口，
    /// 测试按同一端口连接；端口可用 `ONEPANEL_LOG_TEST_SERVER` 覆盖。
    static let defaultBaseURL = "http://127.0.0.1:18765"

    /// 服务地址；未提供环境变量时使用固定端口。
    static func baseURL() throws -> URL {
        let raw = ProcessInfo.processInfo.environment["ONEPANEL_LOG_TEST_SERVER"]
        let value = raw?.isEmpty == false ? raw! : defaultBaseURL
        guard let url = URL(string: value) else {
            throw NSError(
                domain: "test-service",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey:
                    "测试服务地址无效：\(value)"]
            )
        }
        return url
    }

    /// 设置本次用例的流响应脚本。
    ///
    /// 每行一条指令：`log:<text>`、`error:<text>`、`hold`、`eof`。
    static func setScenario(_ scenario: String) throws {
        try post("/scenario", body: scenario)
    }

    /// 设置快照响应：`nil` 表示让服务端返回 500，验证失败路径。
    static func setSnapshot(_ body: String?) throws {
        try post("/snapshot", body: body ?? "")
    }

    /// 读取服务端连接统计。
    struct Status {
        let started: Int
        let closedByClient: Int
        let closedByServer: Int
        let active: [String]
    }

    static func status() throws -> Status {
        let data = try get("/status")
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "test-service", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "状态响应不是对象"])
        }
        return Status(
            started: json["started"] as? Int ?? 0,
            closedByClient: json["closedByClient"] as? Int ?? 0,
            closedByServer: json["closedByServer"] as? Int ?? 0,
            active: json["active"] as? [String] ?? []
        )
    }

    /// 等到服务端观察到指定数量的客户端断开。
    static func waitForClientDisconnects(_ expected: Int, timeout: TimeInterval = 5) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while try status().closedByClient < expected {
            if Date() > deadline {
                let current = try status().closedByClient
                throw NSError(domain: "test-service", code: 3,
                              userInfo: [NSLocalizedDescriptionKey:
                                "等待客户端断开超时：期望 \(expected)，实际 \(current)"])
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
    }

    private static func post(_ path: String, body: String) throws {
        var request = URLRequest(url: try baseURL().appendingPathComponent(path))
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)
        _ = try send(request)
    }

    private static func get(_ path: String) throws -> Data {
        var request = URLRequest(url: try baseURL().appendingPathComponent(path))
        request.httpMethod = "GET"
        return try send(request)
    }

    private static func send(_ request: URLRequest) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var payload = Data()
        var failure: Error?
        URLSession.shared.dataTask(with: request) { data, _, error in
            payload = data ?? Data()
            failure = error
            semaphore.signal()
        }.resume()
        semaphore.wait()
        if let failure { throw failure }
        return payload
    }
}