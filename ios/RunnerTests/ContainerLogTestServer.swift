import Foundation

/// 测试用的本地 SSE 服务端。
///
/// 按上游 `agent/app/service/container.go` 的真实帧格式返回：
/// 普通日志帧是 `data: <base64>` 加空行，失败帧是 `event: error` 加明文 data。
/// 只绑定回环地址，端口由系统分配。
final class ContainerLogTestServer: @unchecked Sendable {
    private var serverSocket: Int32 = -1
    private let acceptQueue = DispatchQueue(label: "container-log-test-accept")
    /// 处理连接用并发队列：接受循环阻塞在 `accept`，不能共用串行队列。
    private let clientQueue = DispatchQueue(
        label: "container-log-test-client",
        attributes: .concurrent
    )
    private(set) var port: Int = 0

    /// 事件脚本：每个元素是 `log` 或 `error`。
    enum Step {
        case log(String)
        case error(String)
        /// 保持连接不关闭，等待客户端取消。
        case hold
    }

    private var steps: [Step] = []
    /// 已收到的连接数与最近一次请求首行，供测试断言连接真的到达。
    private(set) var requestCount = 0
    private(set) var lastRequestLine = ""

    init() throws {
        serverSocket = socket(AF_INET, SOCK_STREAM, 0)
        guard serverSocket >= 0 else { throw NSError(domain: "test-server", code: 1) }
        var reuse: Int32 = 1
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, 4)
        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = 0
        let bound = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                bind(serverSocket, sockaddrPointer, UInt32(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0, listen(serverSocket, 8) == 0 else {
            throw NSError(domain: "test-server", code: 2)
        }
        var resolved = sockaddr_in()
        var size = UInt32(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &resolved) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                getsockname(serverSocket, sockaddrPointer, &size)
            }
        }
        port = Int(UInt16(bigEndian: resolved.sin_port))
    }

    var baseURL: String { "http://127.0.0.1:\(port)" }

    /// 设定本次响应要发送的事件序列。
    func respond(with steps: [Step]) {
        self.steps = steps
    }

    /// 开始接收连接。
    func start() {
        acceptQueue.async { [weak self] in
            guard let self else { return }
            while true {
                let client = accept(self.serverSocket, nil, nil)
                if client < 0 { return }
                self.clientQueue.async {
                    self.handle(client: client)
                }
            }
        }
    }

    func stop() {
        if serverSocket >= 0 {
            close(serverSocket)
            serverSocket = -1
        }
    }

    deinit { stop() }

    private func handle(client: Int32) {
        defer {
            shutdown(client, Int32(SHUT_RDWR))
            close(client)
        }
        var buffer = [UInt8](repeating: 0, count: 4096)
        let received = recv(client, &buffer, buffer.count, 0)
        requestCount += 1
        lastRequestLine = String(
            data: Data(buffer.prefix(max(received, 0))),
            encoding: .utf8
        )?.split(separator: "\r\n").first.map(String.init) ?? ""

        let header = "HTTP/1.1 200 OK\r\n"
            + "Content-Type: text/event-stream\r\n"
            + "Cache-Control: no-cache\r\n"
            + "Transfer-Encoding: chunked\r\n"
            + "Connection: close\r\n\r\n"
        _ = sendText(client, header)

        for step in steps {
            switch step {
            case .log(let text):
                let payload = Data(text.utf8).base64EncodedString()
                writeChunk(client, "data: \(payload)\n\n")
            case .error(let message):
                writeChunk(client, "event: error\ndata: \(message)\n\n")
            case .hold:
                Thread.sleep(forTimeInterval: 2)
            }
        }
        _ = sendText(client, "0\r\n\r\n")
    }

    private func writeChunk(_ client: Int32, _ text: String) {
        // HTTP 分块编码的长度按字节计，单位是十六进制。
        let bytes = Data(text.utf8)
        _ = sendText(client, "\(String(bytes.count, radix: 16))\r\n")
        _ = sendText(client, text)
        _ = sendText(client, "\r\n")
    }

    @discardableResult
    private func sendText(_ client: Int32, _ text: String) -> Bool {
        let bytes = Array(text.utf8)
        let result = bytes.withUnsafeBufferPointer { pointer in
            send(client, pointer.baseAddress, pointer.count, 0)
        }
        return result > 0
    }
}