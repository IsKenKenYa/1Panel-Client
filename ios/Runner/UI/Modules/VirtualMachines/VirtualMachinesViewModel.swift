import Foundation

/// 虚拟机模块的展示状态。
///
/// 六个分区共用同一份状态对象，页签切换不会销毁列表与滚动位置。
@MainActor
final class VirtualMachinesViewModel: ObservableObject {
    enum Section: String, CaseIterable, Identifiable {
        case overview
        case instances
        case isos
        case templates
        case networks
        case storages

        var id: String { rawValue }
    }

    @Published var environment = VMEnvironmentModel.empty
    @Published var environmentError: String?
    @Published var vms: [VMInstanceModel] = []
    @Published var vmTotal = 0
    @Published var vmLimit = 0
    @Published var vmsError: String?
    @Published var isos: [VMIsoModel] = []
    @Published var isosError: String?
    @Published var templates: [VMTemplateModel] = []
    @Published var templatesError: String?
    @Published var networks: [VMNetworkModel] = []
    @Published var networksError: String?
    @Published var storages: [VMStorageModel] = []
    @Published var storagesError: String?
    @Published private(set) var isLoading = false
    @Published private(set) var isBusy = false

    var environmentReady: Bool { environment.ready }

    var runningCount: Int {
        vms.filter { $0.statusTone == "positive" }.count
    }

    var stoppedCount: Int {
        vms.filter { $0.statusTone == "neutral" }.count
    }

    var creatingCount: Int {
        vms.filter { $0.statusTone == "info" }.count
    }

    var abnormalCount: Int {
        vms.filter { $0.statusTone == "negative" || $0.statusTone == "warning" }.count
    }

    var allocatedCpu: Int {
        vms.reduce(0) { $0 + $1.cpu }
    }

    var allocatedMemoryMiB: Int {
        vms.reduce(0) { $0 + $1.memoryMiB }
    }

    func loadAll() async {
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

    func loadEnvironment() async {
        do {
            let payload = try await requestPayload("getVmEnvironment")
            environment = VMEnvironmentModel(payload: payload)
            environmentError = nil
        } catch {
            environmentError = message(error)
        }
    }

    func loadVms() async {
        do {
            let payload = try await requestPayload("getVms", arguments: ["info": ""])
            vms = (payload["items"] as? [[String: Any]] ?? [])
                .map(VMInstanceModel.init)
            vmTotal = VMValue.int(payload["total"])
            vmLimit = VMValue.int(payload["limit"])
            vmsError = nil
        } catch {
            vmsError = message(error)
        }
    }

    func loadIsos() async {
        do {
            let array = try await requestArray("getVmIsos")
            isos = array.map(VMIsoModel.init)
            isosError = nil
        } catch {
            isosError = message(error)
        }
    }

    func loadTemplates() async {
        do {
            let array = try await requestArray("getVmTemplates")
            templates = array.map(VMTemplateModel.init)
            templatesError = nil
        } catch {
            templatesError = message(error)
        }
    }

    func loadNetworks() async {
        do {
            let array = try await requestArray("getVmNetworks")
            networks = array.map(VMNetworkModel.init)
            networksError = nil
        } catch {
            networksError = message(error)
        }
    }

    func loadStorages() async {
        do {
            let array = try await requestArray("getVmStorages")
            storages = array.map(VMStorageModel.init)
            storagesError = nil
        } catch {
            storagesError = message(error)
        }
    }

    /// 同步实例列表。成功返回 nil，失败返回错误文案。
    func syncVms() async -> String? {
        await performWrite("syncVms", arguments: [:])
    }

    /// 启用虚拟机运行环境。
    func enableEnvironment() async -> String? {
        let error = await performWrite("enableVmEnvironment", arguments: [:])
        await loadEnvironment()
        return error
    }

    /// 电源操作。成功返回 nil，失败返回错误文案。
    func operate(name: String, operation: String) async -> String? {
        let error = await performWrite(
            "operateVm",
            arguments: ["name": name, "operate": operation]
        )
        await loadVms()
        return error
    }

    func fetchInfo(name: String) async throws -> VMInstanceModel {
        let payload = try await requestPayload("getVmInfo", arguments: ["name": name])
        return VMInstanceModel(payload: payload)
    }

    func fetchSnapshots(name: String) async throws -> VMSnapshotResult {
        let payload = try await requestPayload("getVmSnapshots", arguments: ["name": name])
        return VMSnapshotResult(payload: payload)
    }

    func fetchHealth(name: String) async throws -> VMHealthModel {
        let payload = try await requestPayload("getVmHealth", arguments: ["name": name])
        return VMHealthModel(payload: payload)
    }

    func fetchStats(name: String) async throws -> VMStatsSample {
        let payload = try await requestPayload("getVmStats", arguments: ["name": name])
        return VMStatsSample(payload: payload)
    }

    func createSnapshot(name: String, snapshotName: String, description: String) async -> String? {
        await performWrite(
            "createVmSnapshot",
            arguments: [
                "name": name,
                "snapshotName": snapshotName,
                "description": description,
            ]
        )
    }

    func recoverSnapshot(name: String, snapshotName: String) async -> String? {
        await performWrite(
            "recoverVmSnapshot",
            arguments: ["name": name, "snapshotName": snapshotName]
        )
    }

    func deleteSnapshot(name: String, snapshotName: String) async -> String? {
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
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            let success = VMValue.bool(payload["success"])
            if success { return nil }
            let error = VMValue.string(payload["error"])
            return error.isEmpty ? "Operation failed" : error
        } catch {
            return message(error)
        }
    }

    private func requestPayload(
        _ method: String,
        arguments: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let raw = try await ChannelManager.shared.invokeDataMethodAsync(
            method,
            arguments: arguments
        )
        guard let payload = raw as? [String: Any] else {
            throw VMChannelError.invalidPayload
        }
        return payload
    }

    private func requestArray(_ method: String) async throws -> [[String: Any]] {
        let raw = try await ChannelManager.shared.invokeDataMethodAsync(method)
        guard let array = raw as? [[String: Any]] else {
            throw VMChannelError.invalidPayload
        }
        return array
    }

    private func message(_ error: Error) -> String {
        if let channelError = error as? VMChannelError {
            return channelError.message
        }
        return error.localizedDescription
    }
}

enum VMChannelError: Error {
    case invalidPayload

    var message: String {
        switch self {
        case .invalidPayload:
            return "Unexpected response from the panel"
        }
    }
}