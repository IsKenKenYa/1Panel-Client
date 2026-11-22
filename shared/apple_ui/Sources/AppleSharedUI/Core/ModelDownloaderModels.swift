import Foundation

/// 模型下载器通道返回值的解码结构。

public struct FeaturedModelItem: Identifiable, Hashable {
    public let key: String
    public let repoID: String
    public let family: String
    public let architecture: String
    public let backboneParams: String
    public let activeParams: String
    public let engram: String
    public let weightGB: Double
    public let sources: [String]
    public let preferredSource: String
    public let preferredRepoID: String
    public let description: [String: String]

    public var id: String { key.isEmpty ? repoID : key }

    public init(payload: [String: Any]) {
        key = ModelValue.string(payload["key"])
        repoID = ModelValue.string(payload["repoID"])
        family = ModelValue.string(payload["family"])
        architecture = ModelValue.string(payload["architecture"])
        backboneParams = ModelValue.string(payload["backboneParams"])
        activeParams = ModelValue.string(payload["activeParams"])
        engram = ModelValue.string(payload["engram"])
        weightGB = ModelValue.double(payload["weightGB"])
        sources = payload["sources"] as? [String] ?? []
        preferredSource = ModelValue.string(payload["preferredSource"])
        preferredRepoID = ModelValue.string(payload["preferredRepoID"])
        description = (payload["description"] as? [String: String]) ?? [:]
    }

    public func localizedDescription() -> String {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        if let text = description[language], !text.isEmpty { return text }
        if language.hasPrefix("zh"), let text = description["zh"], !text.isEmpty {
            return text
        }
        return description["en"] ?? description.values.first ?? ""
    }
}

public struct MarketModelItem: Identifiable, Hashable {
    public let repoID: String
    public let name: String
    public let downloads: Int
    public let likes: Int
    public let sizeFormatted: String

    public var id: String { repoID }

    public init(payload: [String: Any]) {
        repoID = ModelValue.string(payload["repoID"])
        name = ModelValue.string(payload["name"])
        downloads = ModelValue.int(payload["downloads"])
        likes = ModelValue.int(payload["likes"])
        sizeFormatted = ModelValue.string(payload["sizeFormatted"])
    }
}

public struct DownloadTaskItem: Identifiable, Hashable {
    public let taskId: Int
    public let modelName: String
    public let repoID: String
    public let revision: String
    public let downloadType: String
    public let source: String
    public let status: String
    public let statusTone: String
    public let progressRatio: Double
    public let downloadedSize: Int
    public let totalSize: Int
    public let targetDir: String
    public let errorMessage: String
    public let createdAt: String
    public let startedAt: String
    public let completedAt: String
    public let canCancel: Bool
    public let canRetry: Bool
    public let canRemoveRecord: Bool

    public var id: Int { taskId }

    public init(payload: [String: Any]) {
        taskId = ModelValue.int(payload["id"])
        modelName = ModelValue.string(payload["modelName"])
        repoID = ModelValue.string(payload["repoID"])
        revision = ModelValue.string(payload["revision"])
        downloadType = ModelValue.string(payload["downloadType"])
        source = ModelValue.string(payload["source"])
        status = ModelValue.string(payload["status"])
        statusTone = ModelValue.string(payload["statusTone"])
        progressRatio = ModelValue.double(payload["progressRatio"])
        downloadedSize = ModelValue.int(payload["downloadedSize"])
        totalSize = ModelValue.int(payload["totalSize"])
        targetDir = ModelValue.string(payload["targetDir"])
        errorMessage = ModelValue.string(payload["errorMessage"])
        createdAt = ModelValue.string(payload["createdAt"])
        startedAt = ModelValue.string(payload["startedAt"])
        completedAt = ModelValue.string(payload["completedAt"])
        canCancel = ModelValue.bool(payload["canCancel"])
        canRetry = ModelValue.bool(payload["canRetry"])
        canRemoveRecord = ModelValue.bool(payload["canRemoveRecord"])
    }
}

public struct DownloadedModelItem: Identifiable, Hashable {
    public let name: String
    public let repoID: String
    public let revision: String
    public let downloadType: String
    public let source: String
    public let path: String
    public let size: Int
    public let sizeFormatted: String
    public let createdAt: String

    public var id: String { "\(name)-\(downloadType)-\(path)" }

    public init(payload: [String: Any]) {
        name = ModelValue.string(payload["name"])
        repoID = ModelValue.string(payload["repoID"])
        revision = ModelValue.string(payload["revision"])
        downloadType = ModelValue.string(payload["downloadType"])
        source = ModelValue.string(payload["source"])
        path = ModelValue.string(payload["path"])
        size = ModelValue.int(payload["size"])
        sizeFormatted = ModelValue.string(payload["sizeFormatted"])
        createdAt = ModelValue.string(payload["createdAt"])
    }
}

public struct DownloaderSettingsModel {
    public let modelDir: String
    public let featuredSyncEnabled: Bool
    public let hfEndpoint: String
    public let hfToken: String
    public let modelScopeEndpoint: String
    public let modelScopeToken: String

    public static let empty = DownloaderSettingsModel(payload: [:])

    public init(payload: [String: Any]) {
        modelDir = ModelValue.string(payload["modelDir"])
        featuredSyncEnabled = ModelValue.bool(payload["featuredSyncEnabled"])
        hfEndpoint = ModelValue.string(payload["hfEndpoint"])
        hfToken = ModelValue.string(payload["hfToken"])
        modelScopeEndpoint = ModelValue.string(payload["modelScopeEndpoint"])
        modelScopeToken = ModelValue.string(payload["modelScopeToken"])
    }
}

public struct DownloaderOptions {
    public let sources: [String]
    public let sorts: [String]
    public let downloadTypes: [String]
    public let taskStatuses: [String]

    public static let empty = DownloaderOptions(
        sources: ["hf", "modelScope"],
        sorts: ["trending"],
        downloadTypes: ["all", "tokenizer"],
        taskStatuses: []
    )

    public init(
        sources: [String],
        sorts: [String],
        downloadTypes: [String],
        taskStatuses: [String]
    ) {
        self.sources = sources
        self.sorts = sorts
        self.downloadTypes = downloadTypes
        self.taskStatuses = taskStatuses
    }

    public init(payload: [String: Any]) {
        sources = payload["sources"] as? [String] ?? ["hf", "modelScope"]
        sorts = payload["sorts"] as? [String] ?? ["trending"]
        downloadTypes = payload["downloadTypes"] as? [String] ?? ["all", "tokenizer"]
        taskStatuses = payload["taskStatuses"] as? [String] ?? []
    }
}

public enum ModelValue {
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

/// 下载任务操作：取消、重试与移除记录。
public enum DownloadTaskAction: Identifiable {
    case cancel(DownloadTaskItem)
    case retry(DownloadTaskItem)
    case remove(DownloadTaskItem)

    public var id: String {
        switch self {
        case .cancel(let task): return "cancel-\(task.id)"
        case .retry(let task): return "retry-\(task.id)"
        case .remove(let task): return "remove-\(task.id)"
        }
    }

    public var isDestructive: Bool {
        switch self {
        case .cancel: return true
        case .retry: return false
        case .remove: return true
        }
    }

    public var task: DownloadTaskItem {
        switch self {
        case .cancel(let task): return task
        case .retry(let task): return task
        case .remove(let task): return task
        }
    }
}