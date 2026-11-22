import SwiftUI
import AppleSharedUI

/// 虚拟机模块：概览 / 实例 / ISO / 模板 / 网络 / 存储池六个分区。
/// 分区共用一个状态对象，切换页签保留列表与加载结果。
struct VirtualMachinesModuleView: View {
    @StateObject private var viewModel = VirtualMachinesViewModel()
    @EnvironmentObject var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_VM_TAB=instances|isos|templates|networks|storages`。
    @State private var section = VirtualMachinesViewModel.Section(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_VM_TAB"] ?? ""
    ) ?? .overview
    @State private var showEnableConfirm = false
    @State private var toastText: String?
    @State private var hasLoaded = false

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.environmentReady {
                environmentBanner
            }
            sectionContent
        }
        .navigationTitle(translations.get("vmPageTitle", fallback: "Virtual Machines"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(VirtualMachinesViewModel.Section.allCases) { item in
                        Button {
                            section = item
                        } label: {
                            if item == section {
                                Label(sectionTitle(item), systemImage: "checkmark")
                            } else {
                                Text(sectionTitle(item))
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sectionTitle(section))
                            .font(.headline)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                }
                .accessibilityIdentifier("vm-section-menu")
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    Task { await viewModel.syncVms() }
                } label: {
                    Label(translations.get("vmInstanceSyncAction", fallback: "Sync"),
                          systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(viewModel.isBusy)
                Button {
                    Task { await viewModel.loadAll() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
                ModuleSwitcherMenu(current: .virtualMachines)
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            await viewModel.loadAll()
        }
        .onAppear {
            guard hasLoaded else { return }
            Task { await viewModel.loadVms() }
        }
        .confirmationDialog(
            translations.get("vmEnvironmentEnableConfirm",
                            fallback: "Enable the virtualization environment?"),
            isPresented: $showEnableConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("vmEnvironmentEnableAction", fallback: "Enable")) {
                Task {
                    let error = await viewModel.enableEnvironment()
                    showToast(error == nil
                        ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                        : error!)
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        }
        .operationNotice(toastText)
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .overview:
            overviewList
        case .instances:
            instanceList
        case .isos:
            VMIsoSectionView(viewModel: viewModel)
        case .templates:
            VMTemplateSectionView(viewModel: viewModel)
        case .networks:
            VMNetworkSectionView(viewModel: viewModel)
        case .storages:
            VMStorageSectionView(viewModel: viewModel)
        }
    }

    private var environmentBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: viewModel.environmentError == nil
                  ? "exclamationmark.triangle.fill"
                  : "xmark.octagon.fill")
                .foregroundStyle(viewModel.environmentError == nil ? .orange : .red)
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.environmentError == nil
                     ? translations.get("vmEnvironmentNotReady", fallback: "Virtualization is not ready")
                     : viewModel.environmentError!)
                    .font(.subheadline.weight(.medium))
                if viewModel.environmentError == nil {
                    Text(environmentMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if viewModel.environmentError == nil && !viewModel.environmentReady {
                Button(translations.get("vmEnvironmentEnableAction", fallback: "Enable")) {
                    showEnableConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(viewModel.isBusy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }

    private var environmentMessage: String {
        let items = [
            (viewModel.environment.helperExist,
             translations.get("vmEnvironmentHelperLabel", fallback: "Helper")),
            (viewModel.environment.kvmExist,
             translations.get("vmEnvironmentKvmLabel", fallback: "KVM")),
            (viewModel.environment.libvirtActive,
             translations.get("vmEnvironmentLibvirtLabel", fallback: "libvirt")),
            (viewModel.environment.storageExist,
             translations.get("vmEnvironmentStorageLabel", fallback: "Storage")),
        ]
        return items.map { $0.0 ? "✓ \($0.1)" : "✗ \($0.1)" }.joined(separator: "  ")
    }

    private var overviewList: some View {
        List {
            Section(translations.get("vmEnvironmentSectionTitle", fallback: "Environment")) {
                InfoLine(
                    label: translations.get("vmEnvironmentArchLabel", fallback: "Architecture"),
                    value: viewModel.environment.arch.isEmpty ? "--" : viewModel.environment.arch
                )
                environmentRow(
                    title: translations.get("vmEnvironmentHelperLabel", fallback: "Helper"),
                    ok: viewModel.environment.helperExist,
                    message: viewModel.environment.helperMessage
                )
                environmentRow(
                    title: translations.get("vmEnvironmentKvmLabel", fallback: "KVM"),
                    ok: viewModel.environment.kvmExist,
                    message: viewModel.environment.kvmMessage
                )
                environmentRow(
                    title: translations.get("vmEnvironmentLibvirtLabel", fallback: "libvirt"),
                    ok: viewModel.environment.libvirtActive,
                    message: viewModel.environment.libvirtMessage
                )
                environmentRow(
                    title: translations.get("vmEnvironmentStorageLabel", fallback: "Storage"),
                    ok: viewModel.environment.storageExist,
                    message: viewModel.environment.storageMessage
                )
                InfoLine(
                    label: translations.get("vmInstanceStatusColumn", fallback: "Status"),
                    value: viewModel.environmentReady
                        ? translations.get("vmEnvironmentReady", fallback: "Ready")
                        : translations.get("vmEnvironmentNotReady", fallback: "Not ready")
                )
            }

            Section(translations.get("vmTabInstances", fallback: "Virtual Machines")) {
                HStack {
                    Text("\(viewModel.vmTotal)")
                        .font(.title2.weight(.semibold))
                        .monospacedDigit()
                    Text(translations.get("vmInstanceCountUnit", fallback: "VMs"))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                InfoLine(
                    label: translations.get("vmOverviewRunningLabel", fallback: "Running"),
                    value: "\(viewModel.runningCount)"
                )
                InfoLine(
                    label: translations.get("vmOverviewStoppedLabel", fallback: "Stopped"),
                    value: "\(viewModel.stoppedCount)"
                )
                InfoLine(
                    label: translations.get("vmOverviewCreatingLabel", fallback: "Creating"),
                    value: "\(viewModel.creatingCount)"
                )
                InfoLine(
                    label: translations.get("vmOverviewAbnormalLabel", fallback: "Abnormal"),
                    value: "\(viewModel.abnormalCount)"
                )
                if viewModel.vmLimit > 0 {
                    InfoLine(
                        label: translations.get("vmInstanceQuotaLabel", fallback: "Quota"),
                        value: "\(viewModel.vms.count)/\(viewModel.vmLimit)"
                    )
                }
            }

            Section(translations.get("vmOverviewCpuAllocation", fallback: "Allocated Resources")) {
                InfoLine(
                    label: translations.get("vmInstanceCpuLabel", fallback: "CPU"),
                    value: "\(viewModel.allocatedCpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores"))"
                )
                InfoLine(
                    label: translations.get("vmInstanceMemoryLabel", fallback: "Memory"),
                    value: VMFormatting.mib(viewModel.allocatedMemoryMiB)
                )
                InfoLine(
                    label: translations.get("vmInstanceStoragePoolLabel", fallback: "Storage Pool"),
                    value: "\(viewModel.storages.count)"
                )
            }

            Section(translations.get("vmOverviewStorageSectionTitle", fallback: "Storage Pools")) {
                if viewModel.storages.isEmpty {
                    Text(translations.get("vmStorageEmptyTitle", fallback: "No storage pools"))
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.storages) { storage in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(storage.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "%.1f%%", storage.usedPercent))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: min(max(storage.usedPercent, 0), 100), total: 100)
                            .tint(storage.usedPercent >= 90 ? .red : .accentColor)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await viewModel.loadAll()
        }
    }

    private var instanceList: some View {
        Group {
            if viewModel.isLoading && viewModel.vms.isEmpty {
                LoadingView()
            } else if viewModel.vmsError != nil, viewModel.vms.isEmpty {
                ErrorView(
                    message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")
                ) {
                    Task { await viewModel.loadVms() }
                }
            } else if viewModel.vms.isEmpty {
                EmptyStateView(
                    icon: "desktopcomputer",
                    message: translations.get("vmInstanceEmptyTitle", fallback: "No virtual machines"),
                    description: translations.get("vmInstanceEmptyDescription",
                                                 fallback: "Virtual machines created on the panel appear here")
                )
            } else {
                List {
                    if let error = viewModel.vmsError {
                        Section {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("vmTabInstances", fallback: "Virtual Machines")) {
                        ForEach(viewModel.vms) { vm in
                            NavigationLink(value: ServerRoute.vmInstance(name: vm.name)) {
                                VMInstanceRow(vm: vm)
                            }
                            .tint(.primary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadVms()
                }
            }
        }
    }

    private func environmentRow(title: String, ok: Bool, message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func sectionTitle(_ section: VirtualMachinesViewModel.Section) -> String {
        switch section {
        case .overview:
            return translations.get("vmTabOverview", fallback: "Overview")
        case .instances:
            return translations.get("vmTabInstances", fallback: "Virtual Machines")
        case .isos:
            return translations.get("vmTabIso", fallback: "ISO")
        case .templates:
            return translations.get("vmTabTemplates", fallback: "Templates")
        case .networks:
            return translations.get("vmTabNetworks", fallback: "Networks")
        case .storages:
            return translations.get("vmTabStorages", fallback: "Storage Pools")
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

struct VMInstanceRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let vm: VMInstanceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(vm.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                StatusBadge(text: vm.status, color: toneColor)
            }
            Text(metadata)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !vm.description.isEmpty {
                Text(vm.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var metadata: String {
        var items: [String] = []
        items.append("\(vm.cpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores"))")
        items.append(VMFormatting.mib(vm.memoryMiB))
        items.append(VMFormatting.bytes(vm.diskSize))
        if !vm.network.isEmpty { items.append(vm.network) }
        if !vm.storagePool.isEmpty { items.append(vm.storagePool) }
        return items.joined(separator: " · ")
    }

    private var toneColor: Color {
        switch vm.statusTone {
        case "positive": return .green
        case "warning": return .orange
        case "info": return .blue
        case "negative": return .red
        default: return .secondary
        }
    }
}