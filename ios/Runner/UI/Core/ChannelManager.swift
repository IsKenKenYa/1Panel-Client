import Foundation
import Flutter

class ChannelManager {
    static let shared = ChannelManager()

    private var dataChannel: FlutterMethodChannel?
    private var shellChannel: FlutterMethodChannel?

    private init() {}

    func setup(binaryMessenger: FlutterBinaryMessenger) {
        dataChannel = FlutterMethodChannel(
            name: "com.onepanel.client/method",
            binaryMessenger: binaryMessenger
        )
        // 启动时首个页面的数据请求与翻译请求共用通道。
        dataChannel?.resizeBuffer(8)
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
