import Combine
import Foundation

/// 虚拟机模块的共享状态对象。
///
/// iOS 与 macOS 共用加载、写操作与错误映射；平台层只注入各自的 `DataChannel`。
/// 六个分区共用同一份状态，页签切换不会销毁列表与加载结果。
@MainActor
open class VirtualMachineStore: ObservableObject {
    public enum Section: String, CaseIterable, Identifiable {
        case overview
        case instances
        case isos
        case templates
        case networks
        case storages

        public var id: String { rawValue }
    }

    private let channel: any DataChannel

    @Published public var environment = VMEnvironmentModel.empty
    @Published public var environmentError: String?
    @Published public var vms: [VMInstanceModel] = []
    @Published public var vmTotal = 0
    @Published public var vmLimit = 0
    @Published public var vmsError: String?
    @Published public var isos: [VMIsoModel] = []
    @Published public var isosError: String?
    @Published public var templates: [VMTemplateModel] = []
    @Published public var templatesError: String?
    @Published public var networks: [VMNetworkModel] = []
    @Published public var networksError: String?
    @Published public var storages: [VMStorageModel] = []
    @Published public var storagesError: String?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isBusy = false

    public init(channel: any DataChannel) {
        self.channel = channel
    }

    public var environmentReady: Bool { environment.ready }

    public var runningCount: Int {
        vms.filter { $0.statusTone == "positive" }.count
    }

    public var stoppedCount: Int {
        vms.filter { $0.statusTone == "neutral" }.count
    }

    public var creatingCount: Int {
        vms.filter { $0.statusTone == "info" }.count
    }

    public var abnormalCount: Int {
        vms.filter { $0.statusTone == "negative" || $0.statusTone == "warning" }.count
    }

    public var allocatedCpu: Int {
        vms.reduce(0) { $0 + $1.cpu }
    }

    public var allocatedMemoryMiB: Int {
        vms.reduce(0) { $0 + $1.memoryMiB }
    }

    public func loadAll() async {
        guard !isLoading else { return }
        isLoading = true
        await loadEnvironment()
        await loadVms()
        await loadIsos()
        await loadTemplates()
        await loadNetworks()
        await loadStorages()
        isLoading = false
    }

    public func loadEnvironment() async {
        do {
            let payload = try await requestPayload("getVmEnvironment")
            environment = VMEnvironmentModel(payload: payload)
            environmentError = nil
        } catch {
            environmentError = error.localizedDescription
        }
    }

    public func loadVms() async {
        do {
            let payload = try await requestPayload("getVms", arguments: ["info": ""])
            vms = (payload["items"] as? [[String: Any]] ?? [])
                .map(VMInstanceModel.init)
            vmTotal = VMValue.int(payload["total"])
            vmLimit = VMValue.int(payload["limit"])
            vmsError = nil
        } catch {
            vmsError = error.localizedDescription
        }
    }

    public func loadIsos() async {
        do {
            let array = try await requestArray("getVmIsos")
            isos = array.map(VMIsoModel.init)
            isosError = nil
        } catch {
            isosError = error.localizedDescription
        }
    }

    public func loadTemplates() async {
        do {
            let array = try await requestArray("getVmTemplates")
            templates = array.map(VMTemplateModel.init)
            templatesError = nil
        } catch {
            templatesError = error.localizedDescription
        }
    }

    public func loadNetworks() async {
        do {
            let array = try await requestArray("getVmNetworks")
            networks = array.map(VMNetworkModel.init)
            networksError = nil
        } catch {
            networksError = error.localizedDescription
        }
    }

    public func loadStorages() async {
        do {
            let array = try await requestArray("getVmStorages")
            storages = array.map(VMStorageModel.init)
            storagesError = nil
        } catch {
            storagesError = error.localizedDescription
        }
    }

    /// 同步实例列表。成功返回 nil，失败返回错误文案。
    public func syncVms() async -> String? {
        await performWrite("syncVms", arguments: [:])
    }

    /// 启用虚拟机运行环境。
    public func enableEnvironment() async -> String? {
        let error = await performWrite("enableVmEnvironment", arguments: [:])
        await loadEnvironment()
        return error
    }

    /// 电源操作。成功返回 nil，失败返回错误文案。
    public func operate(name: String, operation: String) async -> String? {
        let error = await performWrite(
            "operateVm",
            arguments: ["name": name, "operate": operation]
        )
        await loadVms()
        return error
    }

    public func fetchInfo(name: String) async throws -> VMInstanceModel {
        let payload = try await requestPayload("getVmInfo", arguments: ["name": name])
        return VMInstanceModel(payload: payload)
    }

    public func fetchSnapshots(name: String) async throws -> VMSnapshotResult {
        let payload = try await requestPayload("getVmSnapshots", arguments: ["name": name])
        return VMSnapshotResult(payload: payload)
    }

    public func fetchHealth(name: String) async throws -> VMHealthModel {
        let payload = try await requestPayload("getVmHealth", arguments: ["name": name])
        return VMHealthModel(payload: payload)
    }

    public func fetchStats(name: String) async throws -> VMStatsSample {
        let payload = try await requestPayload("getVmStats", arguments: ["name": name])
        return VMStatsSample(payload: payload)
    }

    public func createSnapshot(
        name: String,
        snapshotName: String,
        description: String
    ) async -> String? {
        await performWrite(
            "createVmSnapshot",
            arguments: [
                "name": name,
                "snapshotName": snapshotName,
                "description": description,
            ]
        )
    }

    public func recoverSnapshot(name: String, snapshotName: String) async -> String? {
        await performWrite(
            "recoverVmSnapshot",
            arguments: ["name": name, "snapshotName": snapshotName]
        )
    }

    public func deleteSnapshot(name: String, snapshotName: String) async -> String? {
        await performWrite(
            "deleteVmSnapshot",
            arguments: ["name": name, "snapshotName": snapshotName]
        )
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
            let success = VMValue.bool(payload["success"])
            if success { return nil }
            let error = VMValue.string(payload["error"])
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
            throw VMStoreError.invalidPayload
        }
        return payload
    }

    private func requestArray(_ method: String) async throws -> [[String: Any]] {
        let raw = try await channel.invoke(method, arguments: nil)
        guard let array = raw as? [[String: Any]] else {
            throw VMStoreError.invalidPayload
        }
        return array
    }
}

enum VMStoreError: Error {
    case invalidPayload
}