import AppleSharedUI
import SwiftUI

struct RuntimeRow: Identifiable {
    let runtimeId: Int
    let name: String
    let type: String
    let version: String
    let status: String
    let port: String
    let image: String
    let containerStatus: String

    var id: Int { runtimeId }

    init(payload: [String: Any]) {
        runtimeId = payload["id"] as? Int ?? 0
        name = payload["name"] as? String ?? ""
        type = payload["type"] as? String ?? ""
        version = payload["version"] as? String ?? ""
        status = payload["status"] as? String ?? ""
        port = payload["port"] as? String ?? ""
        image = payload["image"] as? String ?? ""
        containerStatus = payload["containerStatus"] as? String ?? ""
    }
}

/// 运行环境列表：PHP、Node、Java、Go、Python 与 .NET。
struct RuntimesView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var runtimes: [RuntimeRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var pending: RuntimeOperation?

    var body: some View {
        Group {
            if isLoading && runtimes.isEmpty {
                LoadingView()
            } else if let errorMessage, runtimes.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else if runtimes.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    message: translations.get("runtimeEmptyTitle", fallback: "No runtimes"),
                    description: translations.get("runtimeEmptyDescription",
                                                 fallback: "Create a runtime from the panel to manage it here.")
                )
            } else {
                List {
                    Section(translations.get("operationsCenterRuntimeSectionTitle",
                                             fallback: "Runtime")) {
                        ForEach(runtimes) { runtime in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(runtime.name.isEmpty ? runtime.type : runtime.name)
                                            .font(.subheadline.weight(.medium))
                                        StatusBadge(
                                            text: runtime.status,
                                            color: runtime.status.lowercased().contains("running")
                                                ? .green : .gray
                                        )
                                    }
                                    Text("\(runtime.type) · \(runtime.version)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if !runtime.port.isEmpty {
                                        Text("\(translations.get("sshPortLabel", fallback: "Port")) \(runtime.port)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button {
                                    pending = RuntimeOperation(runtime: runtime, operation: "start")
                                } label: {
                                    Image(systemName: "play.circle")
                                }
                                .buttonStyle(.borderless)
                                .disabled(runtime.status.lowercased().contains("running"))
                                Button {
                                    pending = RuntimeOperation(runtime: runtime, operation: "stop")
                                } label: {
                                    Image(systemName: "stop.circle")
                                }
                                .buttonStyle(.borderless)
                                .disabled(!runtime.status.lowercased().contains("running"))
                                Button {
                                    pending = RuntimeOperation(runtime: runtime, operation: "restart")
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleRuntime", fallback: "Runtime"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .confirmationDialog(
            pending?.operationLabel(translations) ?? "",
            isPresented: Binding(
                get: { pending != nil },
                set: { if !$0 { pending = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let pending {
                Button(pending.operationLabel(translations)) {
                    Task { await operate(pending) }
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    self.pending = nil
                }
            }
        } message: {
            if let pending {
                Text(pending.runtime.name)
            }
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync("getRuntimes")
            runtimes = (raw as? [[String: Any]] ?? []).map(RuntimeRow.init)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func operate(_ pending: RuntimeOperation) async {
        self.pending = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "operateRuntime",
                arguments: ["id": pending.runtime.runtimeId, "operation": pending.operation]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RuntimeOperation: Identifiable {
    let id = UUID()
    let runtime: RuntimeRow
    let operation: String

    func operationLabel(_ translations: TranslationsManager) -> String {
        switch operation {
        case "start": return translations.get("runtimeActionStart", fallback: "Start")
        case "stop": return translations.get("runtimeActionStop", fallback: "Stop")
        case "restart": return translations.get("runtimeActionRestart", fallback: "Restart")
        default: return operation
        }
    }
}

struct ProcessListeningRow: Identifiable {
    let processId: Int
    let name: String
    let ports: [Int]

    var id: Int { processId }
}

/// 进程入口：监听端口进程列表与停止操作。
struct ProcessesView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var processes: [ProcessListeningRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var pendingStop: ProcessListeningRow?

    var body: some View {
        Group {
            if isLoading && processes.isEmpty {
                LoadingView()
            } else if let errorMessage, processes.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else if processes.isEmpty {
                EmptyStateView(
                    icon: "list.bullet",
                    message: translations.get("processesEmptyTitle", fallback: "No processes")
                )
            } else {
                List {
                    Section(translations.get("operationsProcessesTitle", fallback: "Processes")) {
                        ForEach(processes) { process in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(process.name.isEmpty ? "\(process.processId)" : process.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text("PID \(process.processId)")
                                        .font(.caption)
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                if !process.ports.isEmpty {
                                    Text(process.ports.map(String.init).joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingStop = process
                                } label: {
                                    Label(translations.get("commonStop", fallback: "Stop"),
                                          systemImage: "stop.fill")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("operationsProcessesTitle", fallback: "Processes"))
        .confirmationDialog(
            processStopTitle,
            isPresented: Binding(
                get: { pendingStop != nil },
                set: { if !$0 { pendingStop = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonStop", fallback: "Stop"), role: .destructive) {
                Task { await stopPending() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingStop = nil
            }
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getListeningProcesses"
            )
            processes = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let pid = item["pid"] as? Int else { return nil }
                return ProcessListeningRow(
                    processId: pid,
                    name: item["name"] as? String ?? "",
                    ports: (item["ports"] as? [Any])?.compactMap {
                        ($0 as? NSNumber)?.intValue
                    } ?? []
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private var processStopTitle: String {
        let name = pendingStop?.name.isEmpty == false
            ? pendingStop!.name
            : "\(pendingStop?.processId ?? 0)"
        return translations.get("processesStopConfirm", fallback: "Stop process {name}?")
            .replacingOccurrences(of: "{name}", with: name)
            .replacingOccurrences(of: "{0}", with: name)
    }

    private func stopPending() async {
        guard let process = pendingStop else { return }
        pendingStop = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "stopListeningProcess",
                arguments: ["pid": process.processId]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct DiskRow: Identifiable {
    let device: String
    let model: String
    let size: String
    let diskType: String
    let mountPoint: String
    let usePercent: Int
    let isSystem: Bool
    let isMounted: Bool

    var id: String { device }
}

/// 磁盘管理入口：磁盘容量、挂载点与使用率。
struct DiskManagementView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var disks: [DiskRow] = []
    @State private var totalDisks = 0
    @State private var totalCapacity = 0
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && disks.isEmpty {
                LoadingView()
            } else if let errorMessage, disks.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else if disks.isEmpty {
                EmptyStateView(
                    icon: "internaldrive",
                    message: translations.get("toolboxDiskEmptyTitle", fallback: "No disks")
                )
            } else {
                List {
                    Section(translations.get("toolboxDiskOverviewTitle", fallback: "Disk Overview")) {
                        InfoLine(
                            label: translations.get("toolboxDiskTotalLabel", fallback: "Total disks"),
                            value: "\(totalDisks)"
                        )
                        InfoLine(
                            label: translations.get("toolboxDiskCapacityLabel", fallback: "Total capacity"),
                            value: ByteCountFormatter.string(
                                fromByteCount: Int64(totalCapacity),
                                countStyle: .file
                            )
                        )
                    }
                    Section(translations.get("toolboxDiskDataSectionTitle", fallback: "Disks")) {
                        ForEach(disks) { disk in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(disk.device)
                                        .font(.subheadline.weight(.medium))
                                    if disk.isSystem {
                                        Text(translations.get("toolboxDiskSystemSectionTitle",
                                                              fallback: "System"))
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 1)
                                            .background(Color.accentColor.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    Spacer()
                                    Text(disk.size)
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                Text("\(disk.diskType) · \(disk.model)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(disk.mountPoint.isEmpty
                                     ? translations.get("toolboxDiskUnmountedLabel", fallback: "Not mounted")
                                     : disk.mountPoint)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                ProgressView(value: Double(min(max(disk.usePercent, 0), 100)), total: 100)
                                    .tint(disk.usePercent >= 90 ? .red : .accentColor)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("toolboxDiskTitle", fallback: "Disk Management"))
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getToolboxDiskSnapshot"
            )
            let payload = raw as? [String: Any] ?? [:]
            totalDisks = payload["totalDisks"] as? Int ?? 0
            totalCapacity = payload["totalCapacity"] as? Int ?? 0
            disks = (payload["disks"] as? [[String: Any]] ?? []).compactMap { item in
                guard let device = item["device"] as? String, !device.isEmpty else { return nil }
                return DiskRow(
                    device: device,
                    model: item["model"] as? String ?? "",
                    size: item["size"] as? String ?? "",
                    diskType: item["diskType"] as? String ?? "",
                    mountPoint: item["mountPoint"] as? String ?? "",
                    usePercent: item["usePercent"] as? Int ?? 0,
                    isSystem: item["isSystem"] as? Bool ?? false,
                    isMounted: item["isMounted"] as? Bool ?? false
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct HostAssetRow: Identifiable {
    let hostId: Int
    let name: String
    let addr: String
    let port: Int
    let user: String
    let group: String
    let status: String
    let osType: String

    var id: Int { hostId }

    init(payload: [String: Any]) {
        hostId = payload["id"] as? Int ?? 0
        name = payload["name"] as? String ?? ""
        addr = payload["addr"] as? String ?? ""
        port = payload["port"] as? Int ?? 0
        user = payload["user"] as? String ?? ""
        group = payload["group"] as? String ?? ""
        status = payload["status"] as? String ?? ""
        osType = payload["osType"] as? String ?? ""
    }
}

/// 主机资源入口。
struct HostAssetsView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var hosts: [HostAssetRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && hosts.isEmpty {
                LoadingView()
            } else if let errorMessage, hosts.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else if hosts.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    message: translations.get("hostAssetsEmptyTitle", fallback: "No hosts")
                )
            } else {
                List {
                    Section(translations.get("serverModuleHostAssets", fallback: "Host Assets")) {
                        ForEach(hosts) { host in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(host.name).font(.subheadline.weight(.medium))
                                    Spacer()
                                    StatusBadge(
                                        text: host.status,
                                        color: host.status.lowercased().contains("online")
                                            ? .green : .gray
                                    )
                                }
                                Text("\(host.addr):\(host.port) · \(host.user)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !host.group.isEmpty || !host.osType.isEmpty {
                                    Text([host.group, host.osType]
                                        .filter { !$0.isEmpty }
                                        .joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleHostAssets", fallback: "Host Assets"))
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync("getHostAssets")
            hosts = (raw as? [[String: Any]] ?? []).map(HostAssetRow.init)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct GroupRow: Identifiable {
    let groupId: Int
    let name: String

    var id: Int { groupId }
}

/// 主机分组入口。
struct GroupsView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var groups: [GroupRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && groups.isEmpty {
                LoadingView()
            } else if let errorMessage, groups.isEmpty {
                ErrorView(message: errorMessage) {
                    Task { await load() }
                }
            } else if groups.isEmpty {
                EmptyStateView(
                    icon: "folder.badge.gearshape",
                    message: translations.get("groupEmptyTitle", fallback: "No groups")
                )
            } else {
                List {
                    Section(translations.get("serverModuleGroup", fallback: "Host Groups")) {
                        ForEach(groups) { group in
                            HStack {
                                Text(group.name.isEmpty ? "\(group.groupId)" : group.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("\(group.groupId)")
                                    .font(.caption)
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await load()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleGroup", fallback: "Host Groups"))
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getGroups",
                arguments: ["type": "host"]
            )
            groups = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let id = item["id"] as? Int else { return nil }
                return GroupRow(groupId: id, name: item["name"] as? String ?? "")
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}