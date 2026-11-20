import Foundation

/// 容器列表行：iOS 与 macOS 共用的容器摘要。
/// 字段来源为 Dart 侧 `getContainers` 返回字典。
public struct ContainerSummary: Identifiable, Hashable, Sendable {
    public let originalId: String
    public let name: String
    public let image: String
    public let state: String
    public let status: String
    public let cpuUsage: Double?
    public let memoryUsage: Double?

    public var id: String { originalId }

    public init(
        originalId: String,
        name: String,
        image: String,
        state: String,
        status: String = "",
        cpuUsage: Double? = nil,
        memoryUsage: Double? = nil
    ) {
        self.originalId = originalId
        self.name = name
        self.image = image
        self.state = state
        self.status = status
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }

    public init?(payload: [String: Any]) {
        guard let name = payload["name"] as? String,
              let image = payload["image"] as? String,
              let state = payload["state"] as? String else { return nil }
        self.init(
            originalId: payload["id"] as? String ?? "",
            name: name,
            image: image,
            state: state,
            status: payload["status"] as? String ?? "",
            cpuUsage: payload["cpuUsage"] as? Double,
            memoryUsage: payload["memoryUsage"] as? Double
        )
    }

    /// 解析 `getContainers` 的列表返回值，无法识别的行被跳过。
    public static func parseList(_ rows: [[String: Any]]) -> [ContainerSummary] {
        rows.compactMap(ContainerSummary.init(payload:))
    }
}
