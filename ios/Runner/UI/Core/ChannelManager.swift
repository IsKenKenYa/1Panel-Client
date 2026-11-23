import Foundation
import Flutter

class ChannelManager {
    static let shared = ChannelManager()

    private var dataChannel: FlutterMethodChannel?
    private var shellChannel: FlutterMethodChannel?

    /// 容器日志跟随回调：Dart 侧订阅 SSE 后逐块回调。
    private var logChunkHandler: ((String) -> Void)?
    private var logDoneHandler: (() -> Void)?
    private var logErrorHandler: ((String) -> Void)?
    /// Dart 侧分配的会话编号，回调编号不一致时丢弃。
    private var logSession: Int?
    /// 本端发起次数的编号，用于识别被后续开始或停止覆盖的请求。
    private var logRequest = 0

    private init() {}

    /// 订阅容器日志流。
    @MainActor
    func startContainerLogStream(
        container: String,
        tail: String?,
        onChunk: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) async throws {
        logRequest += 1
        let request = logRequest
        logChunkHandler = onChunk
        logDoneHandler = onDone
        logErrorHandler = onError
        var arguments: [String: Any] = ["container": container, "follow": true]
        if let tail, !tail.isEmpty { arguments["tail"] = tail }
        do {
            let raw = try await invokeDataMethodAsync(
                "startContainerLogStream",
                arguments: arguments
            )
            guard request == logRequest else { return }
            let payload = raw as? [String: Any] ?? [:]
            guard payload["success"] as? Bool == true else {
                clearLogHandlers()
                throw NSError(
                    domain: "onepanel.containerLogs",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: payload["error"] as? String
                            ?? "Failed to start log stream",
                    ]
                )
            }
            logSession = payload["session"] as? Int
        } catch {
            if request == logRequest { clearLogHandlers() }
            throw error
        }
    }

    /// 停止容器日志跟随。
    @MainActor
    func stopContainerLogStream() async {
        logRequest += 1
        clearLogHandlers()
        _ = try? await invokeDataMethodAsync("stopContainerLogStream", arguments: nil)
    }

    private func clearLogHandlers() {
        logChunkHandler = nil
        logDoneHandler = nil
        logErrorHandler = nil
        logSession = nil
    }

    private func handleLogCallback(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "containerLogChunk", "containerLogDone", "containerLogError":
            guard let session = arguments["session"] as? Int,
                  session == logSession else {
                result(nil)
                return
            }
            switch call.method {
            case "containerLogChunk":
                logChunkHandler?(arguments["chunk"] as? String ?? "")
            case "containerLogDone":
                logDoneHandler?()
            default:
                logErrorHandler?(arguments["error"] as? String ?? "Log stream failed")
            }
        default:
            result(FlutterMethodNotImplemented)
            return
        }
        result(nil)
    }

    func setup(binaryMessenger: FlutterBinaryMessenger) {
        dataChannel = FlutterMethodChannel(
            name: "com.onepanel.client/method",
            binaryMessenger: binaryMessenger
        )
        // 启动时首个页面的数据请求与翻译请求共用通道。
        dataChannel?.resizeBuffer(8)
        // Dart 侧跟随日志时通过同一通道回调日志块。
        dataChannel?.setMethodCallHandler { [weak self] call, result in
            guard let self else {
                result(FlutterMethodNotImplemented)
                return
            }
            self.handleLogCallback(call, result: result)
        }
        shellChannel = FlutterMethodChannel(
            name: "onepanel/ios_channel",
            binaryMessenger: binaryMessenger
        )

        shellChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "ping":
                result("pong")
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func invokeDataMethod(_ method: String, arguments: Any? = nil, completion: @escaping (Any?) -> Void) {
        guard let dataChannel = dataChannel else {
            completion(nil)
            return
        }
        dataChannel.invokeMethod(method, arguments: arguments) { result in
            completion(result)
        }
    }

    func invokeDataMethodAsync(_ method: String, arguments: Any? = nil) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            guard let dataChannel = dataChannel else {
                continuation.resume(throwing: NSError(domain: "ChannelManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data channel not initialized"]))
                return
            }
            dataChannel.invokeMethod(method, arguments: arguments) { result in
                if let flutterError = result as? FlutterError {
                    continuation.resume(throwing: NSError(domain: "FlutterError", code: Int(flutterError.code) ?? -1, userInfo: [NSLocalizedDescriptionKey: flutterError.message ?? "Unknown error"]))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: NSError(domain: "FlutterError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Method not implemented"]))
                } else {
                    continuation.resume(returning: result)
                }
            }
        }
    }

    func invokeShellMethod(_ method: String, arguments: Any? = nil, completion: @escaping (Any?) -> Void) {
        guard let shellChannel = shellChannel else {
            completion(nil)
            return
        }
        shellChannel.invokeMethod(method, arguments: arguments) { result in
            completion(result)
        }
    }

    /// 调试走查种子：把 `ONEPANEL_SEED_*` 环境变量转发给 Dart 侧写入配置。
    /// Dart 侧仅在调试构建处理该调用。
    func seedDebugConfigIfNeeded() {
        let env = ProcessInfo.processInfo.environment
        guard let url = env["ONEPANEL_SEED_SERVER_URL"], !url.isEmpty,
              let apiKey = env["ONEPANEL_SEED_API_KEY"], !apiKey.isEmpty else {
            return
        }
        var args: [String: Any] = ["url": url, "apiKey": apiKey]
        if let name = env["ONEPANEL_SEED_SERVER_NAME"], !name.isEmpty {
            args["name"] = name
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.invokeDataMethod("seedDebugConfig", arguments: args) { _ in }
        }
    }
}
