import SwiftUI
import AppleSharedUI

/// 虚拟机详情：资源、磁盘、网卡、电源操作、快照与健康检查入口。
struct VMInstanceDetailView: View {
    let instanceName: String
    @StateObject private var viewModel = VirtualMachinesViewModel()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var instance: VMInstanceModel?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pendingAction: VMPowerAction?
    @State private var activeSheet: VMDetailSheet?
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && instance == nil {
                LoadingView()
            } else if instance == nil {
                ErrorView(
                    message: loadError ?? translations.get("commonLoadFailedTitle", fallback: "Failed to load")
                ) {
                    Task { await reload() }
                }
            } else if let instance {
                detailList(instance)
            }
        }
        .navigationTitle(instanceName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await reload()
        }
        .confirmationDialog(
            pendingAction.map { powerTitle($0) } ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(powerTitle(action), role: action.destructive ? .destructive : nil) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            if let action = pendingAction {
                Text(confirmMessage(action))
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .snapshots:
                NavigationStack {
                    VMSnapshotSheet(instanceName: instanceName, viewModel: viewModel)
                }
            case .health:
                NavigationStack {
                    VMHealthSheet(instanceName: instanceName, viewModel: viewModel)
                }
            case .monitor:
                NavigationStack {
                    VMInstanceMonitorView(instanceName: instanceName, viewModel: viewModel)
                }
            }
        }
        .operationNotice(toastText)
    }

    private func detailList(_ instance: VMInstanceModel) -> some View {
        List {
            if let loadError {
                Section {
                    Text(loadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                HStack {
                    Text(instance.name)
                        .font(.headline)
                    Spacer()
                    StatusBadge(text: instance.status, color: toneColor(instance.statusTone))
                }
                if !instance.description.isEmpty {
                    Text(instance.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                InfoLine(
                    label: translations.get("vmInstanceUuidLabel", fallback: "UUID"),
                    value: instance.uuid.isEmpty ? "--" : instance.uuid
                )
                InfoLine(
                    label: translations.get("vmInstanceBootOrderLabel", fallback: "Boot Order"),
                    value: instance.bootOrder.isEmpty ? "--" : instance.bootOrder
                )
                InfoLine(
                    label: translations.get("vmInstanceGraphicsLabel", fallback: "Graphics"),
                    value: instance.graphicsType.isEmpty ? "--" : instance.graphicsType
                )
            }

            Section(translations.get("vmInstanceResourcesTitle", fallback: "Resources")) {
                InfoLine(
                    label: translations.get("vmInstanceCpuLabel", fallback: "CPU"),
                    value: "\(instance.cpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores"))"
                )
                InfoLine(
                    label: translations.get("vmInstanceMemoryLabel", fallback: "Memory"),
                    value: VMFormatting.mib(instance.memoryMiB)
                )
                InfoLine(
                    label: translations.get("vmInstanceDiskSizeLabel", fallback: "Disk Size"),
                    value: VMFormatting.bytes(instance.diskSize)
                )
                InfoLine(
                    label: translations.get("vmInstanceNetworkLabel", fallback: "Network"),
                    value: instance.network.isEmpty ? "--" : instance.network
                )
                InfoLine(
                    label: translations.get("vmInstanceStoragePoolLabel", fallback: "Storage Pool"),
                    value: instance.storagePool.isEmpty ? "--" : instance.storagePool
                )
                InfoLine(
                    label: translations.get("vmInstanceAutoStartLabel", fallback: "Auto Start"),
                    value: instance.autoStart ? translations.get("commonYes", fallback: "Yes")
                                              : translations.get("commonNo", fallback: "No")
                )
            }

            if !powerActions(instance).isEmpty {
                Section(translations.get("vmInstancePowerSectionTitle", fallback: "Power")) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 140), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(powerActions(instance)) { action in
                            Button {
                                pendingAction = action
                            } label: {
                                Label(powerTitle(action), systemImage: action.icon)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(action.destructive ? .red : .accentColor)
                            .disabled(viewModel.isBusy)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(translations.get("vmInstanceActionSnapshot", fallback: "Snapshots")) {
                Button {
                    activeSheet = .snapshots
                } label: {
                    Label(translations.get("vmInstanceSnapshotTitle", fallback: "Snapshots"),
                          systemImage: "clock.arrow.circlepath")
                }
                if instance.capabilities.canHealthCheck {
                    Button {
                        activeSheet = .health
                    } label: {
                        Label(translations.get("vmInstanceActionHealthCheck", fallback: "Health Check"),
                              systemImage: "stethoscope")
                    }
                }
                if instance.capabilities.canMonitor {
                    Button {
                        activeSheet = .monitor
                    } label: {
                        Label(translations.get("vmInstanceActionMonitor", fallback: "Monitor"),
                              systemImage: "waveform.path.ecg")
                    }
                }
            }
            .disabled(viewModel.isBusy)

            if !instance.disks.isEmpty {
                Section(translations.get("vmInstanceDisksSectionTitle", fallback: "Disks")) {
                    ForEach(instance.disks) { disk in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(disk.target) · \(disk.bus)")
                                .font(.subheadline.weight(.medium))
                            Text("\(disk.format) · \(VMFormatting.bytes(disk.capacity))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(disk.source)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            if !instance.interfaces.isEmpty {
                Section(translations.get("vmInstanceInterfacesSectionTitle", fallback: "Network Interfaces")) {
                    ForEach(instance.interfaces) { interface in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(interface.source.isEmpty ? interface.type : interface.source)
                                .font(.subheadline.weight(.medium))
                            if !interface.ip.isEmpty || !interface.mac.isEmpty {
                                Text([interface.ip, interface.mac]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            Section(translations.get("vmInstanceIsoPathsLabel", fallback: "ISO Images")) {
                if instance.isoPaths.isEmpty {
                    Text(translations.get("vmInstanceIsoNone", fallback: "No ISO attached"))
                        .foregroundStyle(.secondary)
                }
                ForEach(instance.isoPaths, id: \.self) { path in
                    Text(path)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await reload()
        }
    }

    private func reload() async {
        isLoading = true
        do {
            instance = try await viewModel.fetchInfo(name: instanceName)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func run(_ action: VMPowerAction) {
        pendingAction = nil
        Task {
            let error = await viewModel.operate(name: instanceName, operation: action.id)
            await reload()
            showToast(error == nil
                ? translations.get("vmInstanceOperateCompleted", fallback: "Request submitted")
                    .replacingOccurrences(of: "{operation}", with: powerTitle(action))
                : error!)
        }
    }

    private func powerActions(_ instance: VMInstanceModel) -> [VMPowerAction] {
        var actions: [VMPowerAction] = []
        if instance.capabilities.canStart {
            actions.append(VMPowerAction(id: "start", titleKey: "vmInstanceActionStart",
                                         fallback: "Start", icon: "play.fill"))
        }
        if instance.capabilities.canShutdown {
            actions.append(VMPowerAction(id: "shutdown", titleKey: "vmInstanceActionShutdown",
                                         fallback: "Shut Down", icon: "power", destructive: true))
        }
        if instance.capabilities.canReboot {
            actions.append(VMPowerAction(id: "reboot", titleKey: "vmInstanceActionReboot",
                                         fallback: "Reboot", icon: "restart"))
        }
        if instance.capabilities.canSuspend {
            actions.append(VMPowerAction(id: "suspend", titleKey: "vmInstanceActionSuspend",
                                         fallback: "Suspend", icon: "pause.fill"))
        }
        if instance.capabilities.canResume {
            actions.append(VMPowerAction(id: "resume", titleKey: "vmInstanceActionResume",
                                         fallback: "Resume", icon: "play.circle"))
        }
        if instance.capabilities.canDestroy {
            actions.append(VMPowerAction(id: "destroy", titleKey: "vmInstanceActionDestroy",
                                         fallback: "Force Off", icon: "bolt.slash.fill",
                                         destructive: true))
        }
        return actions
    }

    private func powerTitle(_ action: VMPowerAction) -> String {
        translations.get(action.titleKey, fallback: action.fallback)
    }

    private func confirmMessage(_ action: VMPowerAction) -> String {
        translations.get("vmInstanceOperateConfirm",
                         fallback: "Run {operation} on {name}?")
            .replacingOccurrences(of: "{operation}", with: powerTitle(action))
            .replacingOccurrences(of: "{name}", with: instanceName)
    }

    private func toneColor(_ tone: String) -> Color {
        switch tone {
        case "positive": return .green
        case "warning": return .orange
        case "info": return .blue
        case "negative": return .red
        default: return .secondary
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}

struct VMPowerAction: Identifiable {
    let id: String
    let titleKey: String
    let fallback: String
    let icon: String
    var destructive = false
}

enum VMDetailSheet: String, Identifiable {
    case snapshots
    case health
    case monitor

    var id: String { rawValue }
}