import Foundation

/// 原生壳到 Dart 业务核心的调用接口。
/// 各平台 target 用自身 ChannelManager 实现，包内 ViewModel 只依赖该协议。
public protocol DataChannel: AnyObject {
    func invoke(_ method: String, arguments: Any?) async throws -> Any?
}
