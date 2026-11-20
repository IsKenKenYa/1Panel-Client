import Foundation
import Flutter

/// 容器终端会话桥：与 Dart 侧 `NativeTerminalBridge`（com.onepanel.client/terminal）对接。
/// 原生层发起打开/输入/尺寸/关闭，Dart 层把输出与状态以 `terminalEvent` 回调上来。
final class TerminalSessionBridge {
    static let shared = TerminalSessionBridge()

    static let eventName = Notification.Name("onepanel.terminal.event")

    private var channel: FlutterMethodChannel?

    private init() {}

    func setup(binaryMessenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.onepanel.client/terminal",
            binaryMessenger: binaryMessenger
        )
        channel.setMethodCallHandler { call, result in
            guard call.method == "terminalEvent" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let payload = call.arguments as? [String: Any] ?? [:]
            NotificationCenter.default.post(
                name: TerminalSessionBridge.eventName,
                object: nil,
                userInfo: payload
            )
            result(nil)
        }
        self.channel = channel
    }

    func open(
        containerName: String,
        columns: Int,
        rows: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let channel else {
            completion(.failure(NSError(
                domain: "TerminalSessionBridge",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Terminal channel not initialized"]
            )))
            return
        }
        channel.invokeMethod(
            "openTerminal",
            arguments: ["containerName": containerName, "cols": columns, "rows": rows]
        ) { result in
            if let sessionId = result as? String {
                completion(.success(sessionId))
            } else if let flutterError = result as? FlutterError {
                completion(.failure(NSError(
                    domain: "TerminalSessionBridge",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: flutterError.message ?? "Terminal session failed"]
                )))
            } else {
                completion(.failure(NSError(
                    domain: "TerminalSessionBridge",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Terminal session failed"]
                )))
            }
        }
    }

    func sendInput(sessionId: String, data: String) {
        channel?.invokeMethod(
            "sendTerminalInput",
            arguments: ["sessionId": sessionId, "data": data]
        )
    }

    func resize(sessionId: String, columns: Int, rows: Int) {
        channel?.invokeMethod(
            "resizeTerminal",
            arguments: ["sessionId": sessionId, "cols": columns, "rows": rows]
        )
    }

    func heartbeat(sessionId: String) {
        channel?.invokeMethod("heartbeatTerminal", arguments: ["sessionId": sessionId])
    }

    func close(sessionId: String) {
        channel?.invokeMethod("closeTerminal", arguments: ["sessionId": sessionId])
    }
}
