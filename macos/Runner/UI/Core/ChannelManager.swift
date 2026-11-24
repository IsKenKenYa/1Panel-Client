import CoreFoundation
import Foundation
import FlutterMacOS

enum NativeMutationOutcome: Equatable {
    case succeeded
    case failed(String?)

    init(_ result: Any?) {
        if let error = result as? FlutterError {
            self = .failed(error.message)
        } else if let response = result as? [String: Any] {
            if let success = response["success"] as? NSNumber,
               CFGetTypeID(success) == CFBooleanGetTypeID(), success.boolValue {
                self = .succeeded
            } else {
                self = .failed(response["error"] as? String)
            }
        } else {
            self = .failed(nil)
        }
    }
}

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
    /// Dart 侧 `startContainerLogStream` 建立 SSE 订阅，随后通过方法通道
    /// 回调 `containerLogChunk`、`containerLogDone`、`containerLogError`。
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

    /// 停止容器日志跟随。
    ///
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
        // 原生壳可在 Dart 通道就绪前请求导航文案和首屏仪表盘。
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
            name: "onepanel/macos_shell",
            binaryMessenger: binaryMessenger
        )
        
        shellChannel?.setMethodCallHandler { call, result in
            switch call.method {
            case "setTitle":
                if let args = call.arguments as? [String: Any],
                   let title = args["title"] as? String {
                    if let window = NSApplication.shared.windows.first(where: { $0.contentViewController is MainShellViewController }) {
                        window.title = title
                    }
                }
                result(nil)
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

    @MainActor
    func invokeMutation(_ method: String, arguments: [String: Any]) async -> NativeMutationOutcome {
        await withCheckedContinuation { continuation in
            invokeDataMethod(method, arguments: arguments) { result in
                continuation.resume(returning: NativeMutationOutcome(result))
            }
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
}
