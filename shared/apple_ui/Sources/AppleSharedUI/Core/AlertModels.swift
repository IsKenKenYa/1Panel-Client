import Foundation

/// 告警中心通道返回值的解码结构。
///
/// 状态语义、渠道能力、规则字段依赖与配置组装由 Dart 侧通道完成，
/// iOS 与 macOS 共用同一套值类型。

public struct AlertRuleModel: Identifiable, Hashable {
    public let ruleId: Int
    public let type: String
    public let title: String
    public let taskName: String
    public let project: String
    public let status: String
    public let statusTone: String
    public let enabled: Bool
    public let cycle: Int
    public let count: Int
    public let interval: Int
    public let sendCount: Int
    public let sendMethod: [String]
    public let advancedParams: String
    public let alertTriggerMode: String
    public let createdAt: String

    public var id: Int { ruleId }

    public init(payload: [String: Any]) {
        ruleId = AlertValue.int(payload["id"])
        type = AlertValue.string(payload["type"])
        title = AlertValue.string(payload["title"])
        taskName = AlertValue.string(payload["taskName"])
        project = AlertValue.string(payload["project"])
        status = AlertValue.string(payload["status"])
        statusTone = AlertValue.string(payload["statusTone"])
        enabled = AlertValue.bool(payload["enabled"])
        cycle = AlertValue.int(payload["cycle"])
        count = AlertValue.int(payload["count"])
        interval = AlertValue.int(payload["interval"])
        sendCount = AlertValue.int(payload["sendCount"])
        sendMethod = payload["sendMethod"] as? [String] ?? []
        advancedParams = AlertValue.string(payload["advancedParams"])
        alertTriggerMode = AlertValue.string(payload["alertTriggerMode"])
        createdAt = AlertValue.string(payload["createdAt"])
    }
}

public struct AlertLogModel: Identifiable, Hashable {
    public let logId: Int
    public let alertId: Int
    public let title: String
    public let type: String
    public let message: String
    public let status: String
    public let statusTone: String
    public let method: String
    public let count: Int
    public let createdAt: String

    public var id: Int { logId }

    public init(payload: [String: Any]) {
        logId = AlertValue.int(payload["id"])
        alertId = AlertValue.int(payload["alertId"])
        title = AlertValue.string(payload["title"])
        type = AlertValue.string(payload["type"])
        message = AlertValue.string(payload["message"])
        status = AlertValue.string(payload["status"])
        statusTone = AlertValue.string(payload["statusTone"])
        method = AlertValue.string(payload["method"])
        count = AlertValue.int(payload["count"])
        createdAt = AlertValue.string(payload["createdAt"])
    }
}

public struct AlertChannelModel: Identifiable, Hashable {
    public let channelId: Int
    public let type: String
    public let title: String
    public let config: String
    public let configSummary: String
    public let status: String
    public let enabled: Bool
    public let statusTone: String
    public let isEmail: Bool
    public let isWebhook: Bool
    public let supportsTest: Bool
    public let createdAt: String

    public var id: Int { channelId }

    public init(payload: [String: Any]) {
        channelId = AlertValue.int(payload["id"])
        type = AlertValue.string(payload["type"])
        title = AlertValue.string(payload["title"])
        config = AlertValue.string(payload["config"])
        configSummary = AlertValue.string(payload["configSummary"])
        status = AlertValue.string(payload["status"])
        enabled = AlertValue.bool(payload["enabled"])
        statusTone = AlertValue.string(payload["statusTone"])
        isEmail = AlertValue.bool(payload["isEmail"])
        isWebhook = AlertValue.bool(payload["isWebhook"])
        supportsTest = AlertValue.bool(payload["supportsTest"])
        createdAt = AlertValue.string(payload["createdAt"])
    }

    /// 编辑表单从列表行进入时需要的结构化输入。
    public var formInput: [String: Any] {
        [
            "id": channelId,
            "type": type,
            "title": title,
            "status": status,
        ]
    }
}

public struct AlertRuleTypeOption: Identifiable, Hashable {
    public let type: String
    public let needsCycleDays: Bool
    public let needsThreshold: Bool
    public let needsInterval: Bool
    public let needsDisk: Bool
    public let needsClam: Bool
    public let needsCronJob: Bool
    public let needsCertificate: Bool
    public let needsWebsite: Bool

    public var id: String { type }

    public init(payload: [String: Any]) {
        type = AlertValue.string(payload["type"])
        needsCycleDays = AlertValue.bool(payload["needsCycleDays"])
        needsThreshold = AlertValue.bool(payload["needsThreshold"])
        needsInterval = AlertValue.bool(payload["needsInterval"])
        needsDisk = AlertValue.bool(payload["needsDisk"])
        needsClam = AlertValue.bool(payload["needsClam"])
        needsCronJob = AlertValue.bool(payload["needsCronJob"])
        needsCertificate = AlertValue.bool(payload["needsCertificate"])
        needsWebsite = AlertValue.bool(payload["needsWebsite"])
    }
}

public struct AlertChannelTypeOption: Identifiable, Hashable {
    public let type: String
    public let isEmail: Bool
    public let isWebhook: Bool
    public let supportsTest: Bool
    public let isCustom: Bool

    public var id: String { type }

    public init(payload: [String: Any]) {
        type = AlertValue.string(payload["type"])
        isEmail = AlertValue.bool(payload["isEmail"])
        isWebhook = AlertValue.bool(payload["isWebhook"])
        supportsTest = AlertValue.bool(payload["supportsTest"])
        isCustom = AlertValue.bool(payload["isCustom"])
    }
}

public struct AlertDiskOption: Identifiable, Hashable {
    public let path: String
    public let type: String
    public let device: String
    public let usedPercent: Double

    public var id: String { path }

    public init(payload: [String: Any]) {
        path = AlertValue.string(payload["path"])
        type = AlertValue.string(payload["type"])
        device = AlertValue.string(payload["device"])
        usedPercent = AlertValue.double(payload["usedPercent"])
    }
}

public struct AlertClamOption: Identifiable, Hashable {
    public let name: String
    public let status: String
    public let path: String

    public var id: String { name }

    public init(payload: [String: Any]) {
        name = AlertValue.string(payload["name"])
        status = AlertValue.string(payload["status"])
        path = AlertValue.string(payload["path"])
    }
}

public struct AlertCronJobOption: Identifiable, Hashable {
    public let name: String
    public let type: String
    public let status: String

    public var id: String { name }

    public init(payload: [String: Any]) {
        name = AlertValue.string(payload["name"])
        type = AlertValue.string(payload["type"])
        status = AlertValue.string(payload["status"])
    }
}

public struct AlertWebhookPreset: Identifiable, Hashable {
    public let key: String
    public let template: String?

    public var id: String { key }

    public init(payload: [String: Any]) {
        key = AlertValue.string(payload["key"])
        template = payload["template"] as? String
    }
}

public struct AlertOptions {
    public let disks: [AlertDiskOption]
    public let clams: [AlertClamOption]
    public let cronJobs: [AlertCronJobOption]
    public let ruleTypes: [AlertRuleTypeOption]
    public let channelTypes: [AlertChannelTypeOption]
    public let encryptions: [String]
    public let webhookPresets: [AlertWebhookPreset]

    public init(payload: [String: Any]) {
        disks = (payload["disks"] as? [[String: Any]] ?? []).map(AlertDiskOption.init)
        clams = (payload["clams"] as? [[String: Any]] ?? []).map(AlertClamOption.init)
        cronJobs = (payload["cronJobs"] as? [[String: Any]] ?? []).map(AlertCronJobOption.init)
        ruleTypes = (payload["ruleTypes"] as? [[String: Any]] ?? [])
            .map(AlertRuleTypeOption.init)
        channelTypes = (payload["channelTypes"] as? [[String: Any]] ?? [])
            .map(AlertChannelTypeOption.init)
        encryptions = payload["encryptions"] as? [String] ?? ["NONE", "SSL", "TLS"]
        webhookPresets = (payload["webhookPresets"] as? [[String: Any]] ?? [])
            .map(AlertWebhookPreset.init)
    }

    public func ruleType(_ type: String) -> AlertRuleTypeOption? {
        ruleTypes.first { $0.type == type }
    }

    public func channelType(_ type: String) -> AlertChannelTypeOption? {
        channelTypes.first { $0.type == type }
    }

    public func preset(_ key: String) -> AlertWebhookPreset? {
        webhookPresets.first { $0.key == key }
    }
}

public struct AlertTestResult {
    public let success: Bool
    public let message: String
    public let response: String
    public let statusCode: Int
    public let duration: Int

    public init(payload: [String: Any]) {
        success = AlertValue.bool(payload["success"])
        message = AlertValue.string(payload["message"]).isEmpty
            ? AlertValue.string(payload["error"])
            : AlertValue.string(payload["message"])
        response = AlertValue.string(payload["response"])
        statusCode = AlertValue.int(payload["statusCode"])
        duration = AlertValue.int(payload["duration"])
    }
}

public enum AlertValue {
    public static func string(_ value: Any?) -> String {
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return ""
    }

    public static func int(_ value: Any?) -> Int {
        if let number = value as? NSNumber { return number.intValue }
        if let text = value as? String { return Int(text) ?? 0 }
        return 0
    }

    public static func double(_ value: Any?) -> Double {
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String { return Double(text) ?? 0 }
        return 0
    }

    public static func bool(_ value: Any?) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }
}