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
    private var logChunkHandler: ((String) -> Void)?
    private var logDoneHandler: (() -> Void)?
    private var logErrorHandler: ((String) -> Void)?
    /// 本端分配的请求编号，随开始参数下发并随回调回传。
    ///
    /// Dart 在开始订阅后会立刻推帧，回复到达前回调就可能到达；
    /// 用请求编号而不是回复里的会话编号匹配，先到的帧不会被丢弃，
    /// 上一轮订阅的迟到帧也仍能被识别。
    private var logRequestID: Int?
    private var logRequest = 0
    
    private init() {}

    /// 订阅容器日志流。
    ///
    /// Dart 侧 `startContainerLogStream` 建立 SSE 订阅，随后通过方法通道
    /// 回调 `containerLogChunk`、`containerLogDone`、`containerLogError`。
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
        logRequestID = request
        logChunkHandler = onChunk
        logDoneHandler = onDone
        logErrorHandler = onError
        var arguments: [String: Any] = [
            "container": container,
            "follow": true,
            "requestID": request,
        ]
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
        logRequestID = nil
    }

    private func handleLogCallback(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "containerLogChunk", "containerLogDone", "containerLogError":
            guard let requestID = arguments["requestID"] as? Int,
                  requestID == logRequestID else {
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
}
