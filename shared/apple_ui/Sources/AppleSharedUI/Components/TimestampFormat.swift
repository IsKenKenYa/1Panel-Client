import Foundation

/// ISO-8601 时间戳的显示格式化。
/// 上游返回的时间带纳秒与时区差值（2026-11-16T00:02:28.80488344+08:00），
/// 直接显示会撑满整行，这里统一截到分钟。
public enum TimestampFormat {
    private static let parser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    /// 解析失败时保留原值，避免把服务端时间显示成空。
    public static func display(_ raw: String) -> String {
        guard !raw.isEmpty else { return "" }
        guard let date = parser.date(from: raw) ?? fallbackParser.date(from: raw) else {
            return raw
        }
        return displayFormatter.string(from: date)
    }
}
