import Foundation
import FlutterMacOS

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
    
    func invokeDataMethodAsync(_ method: String, arguments: Any? = nil) async throws -> Any? {
        return try await withCheckedThrowingContinuation { continuation in
            guard let dataChannel = dataChannel else {
                continuation.resume(throwing: NSError(domain: "ChannelManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data channel not initialized"]))
                return
            }
            dataChannel.invokeMethod(method, arguments: arguments) { result in
                if let flutterError = result as? FlutterError {
                    continuation.resume(throwing: NSError(domain: "FlutterError", code: Int(flutterError.code) ?? -1, userInfo: [NSLocalizedDescriptionKey: flutterError.message ?? "Unknown error"]))
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
