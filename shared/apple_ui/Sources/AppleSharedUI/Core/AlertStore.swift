import Combine
import Foundation

/// 告警中心的共享状态对象。
///
/// 三块（任务、日志、渠道）共用同一份状态，平台层只注入 `DataChannel`。
/// 写操作与测试的字段组装、错误映射由 Dart 通道完成。
@MainActor
open class AlertStore: ObservableObject {
    public enum Section: String, CaseIterable, Identifiable {
        case rules
        case logs
        case channels

        public var id: String { rawValue }
    }

    private let channel: any DataChannel

    @Published public var rules: [AlertRuleModel] = []
    @Published public var ruleTotal = 0
    @Published public var rulesError: String?
    @Published public var logs: [AlertLogModel] = []
    @Published public var logTotal = 0
    @Published public var logsError: String?
    @Published public var channels: [AlertChannelModel] = []
    @Published public var channelsError: String?
    @Published public var options = AlertOptions(payload: [:])
    @Published public private(set) var isLoading = false
    @Published public private(set) var isBusy = false

    public init(channel: any DataChannel) {
        self.channel = channel
    }

    public var enabledChannels: [AlertChannelModel] {
        channels.filter(\.enabled)
    }

    public func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        await loadOptions()
        await loadRules()
        await loadLogs()
        await loadChannels()
        isLoading = false
    }

    public func loadRules(type: String? = nil, status: String? = nil) async {
        var arguments: [String: Any] = ["page": 1, "pageSize": 100]
        if let type, !type.isEmpty { arguments["type"] = type }
        if let status, !status.isEmpty { arguments["status"] = status }
        do {
            let payload = try await requestPayload("getAlertRules", arguments: arguments)
            rules = (payload["items"] as? [[String: Any]] ?? []).map(AlertRuleModel.init)
            ruleTotal = AlertValue.int(payload["total"])
            rulesError = nil
        } catch {
            rulesError = error.localizedDescription
        }
    }

    public func loadLogs(status: String? = nil) async {
        var arguments: [String: Any] = ["page": 1, "pageSize": 100]
        if let status, !status.isEmpty { arguments["status"] = status }
        do {
            let payload = try await requestPayload("getAlertLogs", arguments: arguments)
            logs = (payload["items"] as? [[String: Any]] ?? []).map(AlertLogModel.init)
            logTotal = AlertValue.int(payload["total"])
            logsError = nil
        } catch {
            logsError = error.localizedDescription
        }
    }

    public func loadChannels() async {
        do {
            let array = try await requestArray("getAlertChannels")
            channels = array.map(AlertChannelModel.init)
            channelsError = nil
        } catch {
            channelsError = error.localizedDescription
        }
    }

    public func loadOptions() async {
        do {
            let payload = try await requestPayload("getAlertOptions")
            options = AlertOptions(payload: payload)
        } catch {
            // 选项加载失败不阻断列表；表单按空选项展示并允许稍后重试。
            options = AlertOptions(payload: [:])
        }
    }

    public func createRule(_ arguments: [String: Any]) async -> String? {
        let error = await performWrite("createAlertRule", arguments: arguments)
        if error == nil { await loadRules() }
        return error
    }

    public func updateRule(_ arguments: [String: Any]) async -> String? {
        let error = await performWrite("updateAlertRule", arguments: arguments)
        if error == nil { await loadRules() }
        return error
    }

    public func deleteRule(id: Int) async -> String? {
        let error = await performWrite("deleteAlertRule", arguments: ["id": id])
        if error == nil { await loadRules() }
        return error
    }

    public func toggleRule(id: Int, enable: Bool) async -> String? {
        let error = await performWrite(
            "toggleAlertRule",
            arguments: ["id": id, "enable": enable]
        )
        if error == nil { await loadRules() }
        return error
    }

    public func cleanLogs() async -> String? {
        let error = await performWrite("cleanAlertLogs", arguments: [:])
        if error == nil { await loadLogs() }
        return error
    }

    public func saveChannel(_ arguments: [String: Any]) async -> String? {
        let error = await performWrite("saveAlertChannel", arguments: arguments)
        if error == nil { await loadChannels() }
        return error
    }

    public func deleteChannel(id: Int) async -> String? {
        let error = await performWrite("deleteAlertChannel", arguments: ["id": id])
        if error == nil { await loadChannels() }
        return error
    }

    public func toggleChannel(id: Int, enable: Bool) async -> String? {
        let error = await performWrite(
            "toggleAlertChannel",
            arguments: ["id": id, "enable": enable]
        )
        if error == nil { await loadChannels() }
        return error
    }

    public func testChannel(_ arguments: [String: Any]) async -> AlertTestResult {
        do {
            let payload = try await requestPayload("testAlertChannel", arguments: arguments)
            return AlertTestResult(payload: payload)
        } catch {
            return AlertTestResult(payload: [
                "success": false,
                "message": error.localizedDescription,
            ])
        }
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
            let success = AlertValue.bool(payload["success"])
            if success { return nil }
            let error = AlertValue.string(payload["error"])
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
            throw AlertStoreError.invalidPayload
        }
        return payload
    }

    private func requestArray(_ method: String) async throws -> [[String: Any]] {
        let raw = try await channel.invoke(method, arguments: nil)
        guard let array = raw as? [[String: Any]] else {
            throw AlertStoreError.invalidPayload
        }
        return array
    }
}

enum AlertStoreError: Error {
    case invalidPayload
}