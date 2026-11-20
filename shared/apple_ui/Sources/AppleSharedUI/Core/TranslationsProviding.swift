import SwiftUI

/// 文案查询接口：各平台 target 用自身 TranslationsManager 实现。
public protocol TranslationsProviding: AnyObject {
    func get(_ key: String, fallback: String?) -> String
}

private struct TranslationsProviderKey: EnvironmentKey {
    static let defaultValue: (any TranslationsProviding)? = nil
}

public extension EnvironmentValues {
    /// 由各平台根视图注入，共享组件据此读取本地化文案。
    var translationsProvider: (any TranslationsProviding)? {
        get { self[TranslationsProviderKey.self] }
        set { self[TranslationsProviderKey.self] = newValue }
    }
}
