import Foundation

/// 日志流错误的展示截断。
///
/// Dart 通道保留完整原始错误，展示层按用户反馈规范限制长度；
/// 原始文案仍完整保存在存储的 message 里，供详情入口查看。
public enum LogStreamErrorText {
    /// 展示用长度上限，与 Dart 侧 `ErrorMessageUtils.userFacingMessage`
    /// 默认值一致。
    public static let displayLimit = 120

    /// 把完整错误截断到展示长度，超出时以省略号结尾。
    public static func display(_ message: String?) -> String? {
        guard let message, !message.isEmpty else { return nil }
        if message.count <= displayLimit { return message }
        let end = message.index(message.startIndex, offsetBy: displayLimit - 1)
        return String(message[message.startIndex..<end]) + "…"
    }
}