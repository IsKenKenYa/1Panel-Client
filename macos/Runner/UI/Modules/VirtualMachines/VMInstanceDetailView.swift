import AppleSharedUI
import SwiftUI

/// macOS 虚拟机详情：资源、磁盘、网卡、电源操作、快照、健康检查与监控。
struct VMInstanceDetailView: View {
    let instanceName: String
    @ObservedObject var store: VirtualMachineStore
    @EnvironmentObject private var translations: TranslationsManager

    @State private var instance: VMInstanceModel?
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pendingAction: VMPowerAction?
    @State private var activeSheet: VMDetailSheet?
    @State private var actionError: String?

    var body: some View {
        Group {
            if isLoading && instance == nil {
                LoadingView()
            } else if let instance {
                detailContent(instance)
            } else {
                ErrorView(
                    message: loadError ?? translations.get("commonLoadFailedTitle", fallback: "Failed to load")
                ) {
                    Task { await reload() }
                }
            }
        }
        .navigationTitle(instanceName)
        .toolbar {
            if let instance {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(VMPowerAction.available(instance.capabilities)) { action in
                            Button(role: action.destructive ? .destructive : nil) {
                                pendingAction = action
                            } label: {
                                Label(powerTitle(action), systemImage: action.icon)
                            }
                        }
                    } label: {
                        Label(translations.get("vmInstancePowerSectionTitle", fallback: "Power"),
                              systemImage: "power")
                    }
                    .disabled(store.isBusy)
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await reload() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .confirmationDialog(
            pendingAction.map(powerTitle) ?? "",
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
                VMSnapshotSheet(instanceName: instanceName, store: store)
            case .health:
                VMHealthSheet(instanceName: instanceName, store: store)
            case .monitor:
                VMInstanceMonitorView(instanceName: instanceName, store: store)
            }
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await reload()
        }
    }

    private func detailContent(_ instance: VMInstanceModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(instance.name).font(.headline)
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
                            value: instance.uuid
                        )
                        InfoLine(
                            label: translations.get("vmInstanceBootOrderLabel", fallback: "Boot Order"),
                            value: instance.bootOrder
                        )
                        InfoLine(
                            label: translations.get("vmInstanceGraphicsLabel", fallback: "Graphics"),
                            value: instance.graphicsType
                        )
                    }
                    .padding(.vertical, 4)
                }

                GroupBox(label: Label(translations.get("vmInstanceResourcesTitle", fallback: "Resources"),
                                      systemImage: "cpu")) {
                    VStack(alignment: .leading, spacing: 8) {
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
                            value: instance.network
                        )
                        InfoLine(
                            label: translations.get("vmInstanceStoragePoolLabel", fallback: "Storage Pool"),
                            value: instance.storagePool
                        )
                        InfoLine(
                            label: translations.get("vmInstanceAutoStartLabel", fallback: "Auto Start"),
                            value: instance.autoStart
                                ? translations.get("commonYes", fallback: "Yes")
                                : translations.get("commonNo", fallback: "No")
                        )
                    }
                    .padding(.vertical, 4)
                }

                GroupBox(label: Label(translations.get("vmInstanceActionSnapshot", fallback: "Snapshots"),
                                      systemImage: "clock.arrow.circlepath")) {
                    HStack(spacing: 12) {
                        Button {
                            activeSheet = .snapshots
                        } label: {
                            Label(translations.get("vmInstanceSnapshotTitle", fallback: "Snapshots"),
                                  systemImage: "list.bullet.rectangle")
                        }
                        if instance.capabilities.canHealthCheck {
                            Button {
                                activeSheet = .health
                            } label: {
                                Label(translations.get("vmInstanceActionHealthCheck",
                                                       fallback: "Health Check"),
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
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                if !instance.disks.isEmpty {
                    GroupBox(label: Label(translations.get("vmInstanceDisksSectionTitle",
                                                           fallback: "Disks"),
                                          systemImage: "internaldrive")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(instance.disks) { disk in
                                VStack(alignment: .leading, spacing: 3) {
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
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !instance.interfaces.isEmpty {
                    GroupBox(label: Label(translations.get("vmInstanceInterfacesSectionTitle",
                                                           fallback: "Network Interfaces"),
                                          systemImage: "network")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(instance.interfaces) { interface in
                                VStack(alignment: .leading, spacing: 3) {
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
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !instance.isoPaths.isEmpty {
                    GroupBox(label: Label(translations.get("vmInstanceIsoPathsLabel",
                                                           fallback: "ISO Images"),
                                          systemImage: "opticaldisc")) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(instance.isoPaths, id: \.self) { path in
                                Text(path)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if let loadError {
                    Text(loadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
    }

    private func reload() async {
        isLoading = true
        do {
            instance = try await store.fetchInfo(name: instanceName)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func run(_ action: VMPowerAction) {
        pendingAction = nil
        Task {
            if let error = await store.operate(name: instanceName, operation: action.id) {
                actionError = error
            }
            await reload()
        }
    }

    private func powerTitle(_ action: VMPowerAction) -> String {
        translations.get(action.titleKey, fallback: action.fallback)
    }

    private func confirmMessage(_ action: VMPowerAction) -> String {
        translations.get("vmInstanceOperateConfirm", fallback: "Run {operation} on {name}?")
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
}

enum VMDetailSheet: String, Identifiable {
    case snapshots
    case health
    case monitor

    var id: String { rawValue }
}