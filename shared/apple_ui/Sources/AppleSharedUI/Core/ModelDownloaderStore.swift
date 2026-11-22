import Combine
import Foundation

/// 模型下载器的共享状态对象。
///
/// 四个分区（推荐、搜索、任务、本地）与设置共用同一份状态，平台层只注入
/// `DataChannel`。进度归一化、默认来源与状态语义由 Dart 通道完成。
@MainActor
open class ModelDownloaderStore: ObservableObject {
    public enum Section: String, CaseIterable, Identifiable {
        case featured
        case search
        case tasks
        case local

        public var id: String { rawValue }
    }

    private let channel: any DataChannel

    @Published public var featured: [FeaturedModelItem] = []
    @Published public var featuredTotal = 0
    @Published public var featuredFamilies: [String] = []
    @Published public var featuredError: String?
    @Published public var searchResults: [MarketModelItem] = []
    @Published public var searchTotal = 0
    @Published public var searchError: String?
    @Published public var searchSource = "hf"
    @Published public var searchQuery = ""
    @Published public var searchSort = "trending"
    @Published public var tasks: [DownloadTaskItem] = []
    @Published public var tasksError: String?
    @Published public var localModels: [DownloadedModelItem] = []
    @Published public var localError: String?
    @Published public var settings = DownloaderSettingsModel.empty
    @Published public var settingsError: String?
    @Published public var options = DownloaderOptions.empty
    @Published public private(set) var isLoading = false
    @Published public private(set) var isBusy = false

    public init(channel: any DataChannel) {
        self.channel = channel
    }

    public var hasActiveTasks: Bool {
        tasks.contains { $0.statusTone == "info" }
    }

    public func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        await loadOptions()
        await loadFeatured()
        await loadTasks()
        await loadLocal()
        isLoading = false
    }

    public func loadOptions() async {
        do {
            let payload = try await requestPayload("getModelDownloaderOptions")
            options = DownloaderOptions(payload: payload)
        } catch {
            options = .empty
        }
    }

    public func loadFeatured(family: String? = nil) async {
        var arguments: [String: Any] = ["page": 1, "pageSize": 100]
        if let family, !family.isEmpty { arguments["family"] = family }
        do {
            let payload = try await requestPayload(
                "getModelDownloaderFeatured",
                arguments: arguments
            )
            featured = (payload["items"] as? [[String: Any]] ?? [])
                .map(FeaturedModelItem.init)
            featuredTotal = ModelValue.int(payload["total"])
            featuredFamilies = payload["families"] as? [String] ?? []
            featuredError = nil
        } catch {
            featuredError = error.localizedDescription
        }
    }

    public func search(source: String? = nil, query: String? = nil, sort: String? = nil) async {
        if let source, !source.isEmpty { searchSource = source }
        if let query { searchQuery = query }
        if let sort, !sort.isEmpty { searchSort = sort }
        do {
            let payload = try await requestPayload(
                "getModelDownloaderSearch",
                arguments: [
                    "source": searchSource,
                    "query": searchQuery,
                    "sort": searchSort,
                    "page": 1,
                    "pageSize": 100,
                ]
            )
            searchResults = (payload["items"] as? [[String: Any]] ?? [])
                .map(MarketModelItem.init)
            searchTotal = ModelValue.int(payload["total"])
            searchError = nil
        } catch {
            searchError = error.localizedDescription
        }
    }

    public func loadTasks(status: String? = nil) async {
        var arguments: [String: Any] = [:]
        if let status, !status.isEmpty { arguments["status"] = status }
        do {
            let payload = try await requestPayload(
                "getModelDownloaderTasks",
                arguments: arguments
            )
            tasks = (payload["items"] as? [[String: Any]] ?? [])
                .map(DownloadTaskItem.init)
            tasksError = nil
        } catch {
            tasksError = error.localizedDescription
        }
    }

    public func loadLocal(info: String? = nil) async {
        var arguments: [String: Any] = [:]
        if let info, !info.isEmpty { arguments["info"] = info }
        do {
            let payload = try await requestPayload(
                "getModelDownloaderLocal",
                arguments: arguments
            )
            localModels = (payload["items"] as? [[String: Any]] ?? [])
                .map(DownloadedModelItem.init)
            localError = nil
        } catch {
            localError = error.localizedDescription
        }
    }

    public func loadSettings() async {
        do {
            let payload = try await requestPayload("getModelDownloaderSettings")
            settings = DownloaderSettingsModel(payload: payload)
            settingsError = nil
        } catch {
            settingsError = error.localizedDescription
        }
    }

    public func syncFeatured() async -> String? {
        let error = await performWrite("syncModelDownloaderFeatured", arguments: [:])
        if error == nil { await loadFeatured() }
        return error
    }

    public func setFeaturedSync(enabled: Bool) async -> String? {
        await performWrite(
            "setModelDownloaderFeaturedSync",
            arguments: ["enabled": enabled]
        )
    }

    public func downloadFeatured(_ model: FeaturedModelItem) async -> String? {
        let error = await performWrite(
            "downloadModel",
            arguments: [
                "repoID": model.preferredRepoID,
                "source": model.preferredSource,
                "downloadType": "all",
            ]
        )
        if error == nil { await loadTasks() }
        return error
    }

    public func downloadModel(
        repoID: String,
        source: String,
        downloadType: String = "all",
        revision: String = ""
    ) async -> String? {
        let error = await performWrite(
            "downloadModel",
            arguments: [
                "repoID": repoID,
                "source": source,
                "downloadType": downloadType,
                "revision": revision,
            ]
        )
        if error == nil { await loadTasks() }
        return error
    }

    public func cancelTask(id: Int, withFile: Bool = false) async -> String? {
        let error = await performWrite(
            "cancelModelTask",
            arguments: ["id": id, "withFile": withFile]
        )
        if error == nil { await loadTasks() }
        return error
    }

    public func retryTask(id: Int) async -> String? {
        let error = await performWrite("retryModelTask", arguments: ["id": id])
        if error == nil { await loadTasks() }
        return error
    }

    public func removeTask(id: Int, withFile: Bool = false) async -> String? {
        let error = await performWrite(
            "removeModelTask",
            arguments: ["id": id, "withFile": withFile]
        )
        if error == nil {
            await loadTasks()
            await loadLocal()
        }
        return error
    }

    public func deleteLocalModel(
        name: String,
        downloadType: String = "",
        withFile: Bool = true
    ) async -> String? {
        let error = await performWrite(
            "deleteLocalModel",
            arguments: [
                "name": name,
                "downloadType": downloadType,
                "withFile": withFile,
            ]
        )
        if error == nil { await loadLocal() }
        return error
    }

    public func saveSettings(_ arguments: [String: Any]) async -> String? {
        let error = await performWrite(
            "updateModelDownloaderSettings",
            arguments: arguments
        )
        if error == nil { await loadSettings() }
        return error
    }

    private func performWrite(
        _ method: String,
        arguments: [String: Any]
    ) async -> String? {
        guard !isBusy else { return nil }
        isBusy = true
        defer { isBusy = false }
        do {
            let raw = try await channel.invoke(method, arguments: arguments)
            let payload = raw as? [String: Any] ?? [:]
            let success = ModelValue.bool(payload["success"])
            if success { return nil }
            let error = ModelValue.string(payload["error"])
            return error.isEmpty ? "Operation failed" : error
        } catch {
            return error.localizedDescription
        }
    }

    private func requestPayload(
        _ method: String,
        arguments: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let raw = try await channel.invoke(method, arguments: arguments)
        guard let payload = raw as? [String: Any] else {
            throw ModelDownloaderStoreError.invalidPayload
        }
        return payload
    }
}

enum ModelDownloaderStoreError: Error {
    case invalidPayload
}