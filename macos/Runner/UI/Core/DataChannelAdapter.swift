import AppleSharedUI
import Foundation
import FlutterMacOS

/// 把 macOS ChannelManager 适配为共享包的调用接口。
final class MacOSDataChannel: DataChannel {
    let channelManager: ChannelManager

    init(channelManager: ChannelManager) {
        self.channelManager = channelManager
    }

    func invoke(_ method: String, arguments: Any?) async throws -> Any? {
        try await channelManager.invokeDataMethodAsync(method, arguments: arguments)
    }
}

extension TranslationsManager: TranslationsProviding {}
