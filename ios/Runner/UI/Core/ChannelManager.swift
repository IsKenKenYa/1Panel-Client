import Foundation
import Flutter

class ChannelManager {
    static let shared = ChannelManager()

    private var dataChannel: FlutterMethodChannel?
    private var shellChannel: FlutterMethodChannel?

    /// 容器日志跟随回调：Dart 侧订阅 SSE 后逐块回调。
    ///
    /// 用句柄登记每一次订阅：句柄由本端生成并随开始参数下发，Dart 原样
    /// 回传。开始回复到达前先到的帧按句柄也能匹配；停止只终止调用方持有的
    /// 句柄，其他页面新建的连接不受影响。
    private var logHandlers: [Int: (
        chunk: (String) -> Void,
        done: () -> Void,
        error: (String) -> Void
    )] = [:]
    private var logRequest = 0

    private init() {}

    /// 订阅容器日志流。
    ///
    /// 返回本次订阅的归属句柄，调用方停止时交回。
    @MainActor
    func startContainerLogStream(
        container: String,
        tail: String?,
        onChunk: @escaping (String) -> Void,
        onDone: @escaping () -> Void,
        onError: @escaping (String) -> Void
    ) async throws -> Int {
        logRequest += 1
        let handle = logRequest
        logHandlers[handle] = (onChunk, onDone, onError)
        var arguments: [String: Any] = [
            "container": container,
            "follow": true,
            "requestID": handle,
        ]
        if let tail, !tail.isEmpty { arguments["tail"] = tail }
        do {
            let raw = try await invokeDataMethodAsync(
                "startContainerLogStream",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            guard payload["success"] as? Bool == true else {
                logHandlers[handle] = nil
                throw NSError(
                    domain: "onepanel.containerLogs",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: payload["error"] as? String
                            ?? "Failed to start log stream",
                    ]
                )
            }
            return handle
        } catch {
            logHandlers[handle] = nil
            throw error
        }
    }

    /// 停止指定句柄的容器日志跟随。
    ///
    /// 只清理并通知 Dart 终止该句柄；其他页面的订阅继续接收。
    @MainActor
    func stopContainerLogStream(handle: Int) async {
        logHandlers[handle] = nil
        _ = try? await invokeDataMethodAsync(
            "stopContainerLogStream",
            arguments: ["requestID": handle]
        )
    }

    private func handleLogCallback(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "containerLogChunk", "containerLogDone", "containerLogError":
            guard let requestID = arguments["requestID"] as? Int,
                  let handlers = logHandlers[requestID] else {
                result(nil)
                return
            }
            switch call.method {
            case "containerLogChunk":
                handlers.chunk(arguments["chunk"] as? String ?? "")
            case "containerLogDone":
                handlers.done()
            default:
                handlers.error(arguments["error"] as? String ?? "Log stream failed")
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
            // 平台通道只允许在主线程发消息；不在主线程时先切回主线程。
            let send = {
                guard let dataChannel = self.dataChannel else {
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
            if Thread.isMainThread {
                send()
            } else {
                DispatchQueue.main.async(execute: send)
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
    ///
    /// 只在 Dart 通道可应答后写入，并在写入完成后再放行界面读取配置，
    /// 避免日志页首帧早于种子完成而落到「加载失败」。
    /// 可选 `ONEPANEL_SEED_NAMESPACE` 把写入切到独立存储命名空间，
    /// 让自动化测试完全不触碰用户真实配置。
    func seedDebugConfigIfNeeded(completion: (() -> Void)? = nil) {
        let env = ProcessInfo.processInfo.environment
        guard let url = env["ONEPANEL_SEED_SERVER_URL"], !url.isEmpty,
              let apiKey = env["ONEPANEL_SEED_API_KEY"], !apiKey.isEmpty else {
            completion?()
            return
        }
        var args: [String: Any] = ["url": url, "apiKey": apiKey]
        if let name = env["ONEPANEL_SEED_SERVER_NAME"], !name.isEmpty {
            args["name"] = name
        }
        let namespace = env["ONEPANEL_SEED_NAMESPACE"] ?? ""

        // 先探测通道就绪（getServers 是只读调用），再按顺序切换命名空间与写入。
        invokeDataMethod("getServers", arguments: nil) { [weak self] _ in
            guard let self else { return }
            let proceed = { [weak self] in
                guard let self else { return }
                self.invokeDataMethod("seedDebugConfig", arguments: args) { _ in
                    completion?()
                }
            }
            guard !namespace.isEmpty else {
                proceed()
                return
            }
            self.invokeDataMethod(
                "useTestStorageNamespace",
                arguments: ["namespace": namespace, "reset": true]
            ) { _ in
                proceed()
            }
        }
    }
}
