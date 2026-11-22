import AppleSharedUI
import SwiftUI

/// macOS 虚拟机模块：环境、概览、实例、ISO、模板、网络与存储池。
/// 分区由工具栏菜单切换，列表与加载结果保存在共享状态对象里。
struct VirtualMachinesView: View {
    @StateObject private var store = VirtualMachineStore(
        channel: MacOSDataChannel(channelManager: .shared)
    )
    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = VirtualMachineStore.Section(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_VM_TAB"] ?? ""
    ) ?? .overview
    @State private var path = NavigationPath()
    @State private var showEnableConfirm = false
    @State private var pendingAction: VMPowerAction?
    @State private var pendingName = ""
    @State private var actionError: String?

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                if !store.environmentReady {
                    environmentBanner
                }
                sectionContent
            }
            .navigationTitle(translations.get("vmPageTitle", fallback: "Virtual Machines"))
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("", selection: $section) {
                        ForEach(VirtualMachineStore.Section.allCases) { item in
                            Text(sectionTitle(item)).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .help(translations.get("vmPageTitle", fallback: "Virtual Machines"))
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task {
                            let error = await store.syncVms()
                            if let error { actionError = error }
                        }
                    } label: {
                        Label(translations.get("vmInstanceSyncAction", fallback: "Sync"),
                              systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(store.isBusy)
                    .help(translations.get("vmInstanceSyncAction", fallback: "Sync"))
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await store.loadAll() }
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"),
                              systemImage: "arrow.clockwise")
                    }
                    .disabled(store.isLoading)
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
            .navigationDestination(for: String.self) { name in
                VMInstanceDetailView(instanceName: name, store: store)
            }
        }
        .task {
            await store.loadAll()
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
                    runPower(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            if let action = pendingAction {
                Text(confirmMessage(action, name: pendingName))
            }
        }
        .confirmationDialog(
            translations.get("vmEnvironmentEnableConfirm",
                            fallback: "Enable the virtualization environment?"),
            isPresented: $showEnableConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("vmEnvironmentEnableAction", fallback: "Enable")) {
                Task {
                    if let error = await store.enableEnvironment() {
                        actionError = error
                    }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
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
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .overview:
            overviewContent
        case .instances:
            instanceContent
        case .isos:
            VMResourceListView(
                title: translations.get("vmTabIso", fallback: "ISO"),
                icon: "opticaldisc",
                emptyMessage: translations.get("vmIsoEmptyTitle", fallback: "No ISO images"),
                emptyDescription: translations.get("vmIsoEmptyDescription",
                                                   fallback: "ISO images registered on the panel appear here"),
                isLoading: store.isLoading,
                error: store.isosError,
                isEmpty: store.isos.isEmpty,
                refresh: { await store.loadIsos() }
            ) {
                ForEach(store.isos) { iso in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(iso.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text(iso.status).font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(iso.type) · \(VMFormatting.bytes(iso.size))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(iso.path)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .padding(.vertical, 2)
                }
            }
        case .templates:
            VMResourceListView(
                title: translations.get("vmTabTemplates", fallback: "Templates"),
                icon: "square.on.square",
                emptyMessage: translations.get("vmTemplateEmptyTitle", fallback: "No templates"),
                emptyDescription: translations.get("vmTemplateEmptyDescription",
                                                   fallback: "Templates created from virtual machines appear here"),
                isLoading: store.isLoading,
                error: store.templatesError,
                isEmpty: store.templates.isEmpty,
                refresh: { await store.loadTemplates() }
            ) {
                ForEach(store.templates) { template in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(template.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text(template.status).font(.caption).foregroundStyle(.secondary)
                        }
                        Text("\(translations.get("vmTemplateSourceVmLabel", fallback: "Source")): \(template.sourceVM)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(template.cpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores")) · \(VMFormatting.mib(template.memoryMiB)) · \(VMFormatting.bytes(template.diskSize))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        case .networks:
            VMResourceListView(
                title: translations.get("vmTabNetworks", fallback: "Networks"),
                icon: "network",
                emptyMessage: translations.get("vmNetworkEmptyTitle", fallback: "No networks"),
                emptyDescription: translations.get("vmNetworkEmptyDescription",
                                                   fallback: "Virtual networks created on the panel appear here"),
                isLoading: store.isLoading,
                error: store.networksError,
                isEmpty: store.networks.isEmpty,
                refresh: { await store.loadNetworks() }
            ) {
                ForEach(store.networks) { network in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(network.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text(network.type).font(.caption).foregroundStyle(.secondary)
                        }
                        if !network.cidr.isEmpty {
                            Text("\(network.cidr) · \(translations.get("vmNetworkGatewayLabel", fallback: "Gateway")): \(network.gateway)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(translations.get("vmNetworkVmCountLabel", fallback: "Virtual machines")): \(network.vmCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        case .storages:
            VMResourceListView(
                title: translations.get("vmTabStorages", fallback: "Storage Pools"),
                icon: "externaldrive",
                emptyMessage: translations.get("vmStorageEmptyTitle", fallback: "No storage pools"),
                emptyDescription: translations.get("vmStorageEmptyDescription",
                                                   fallback: "Storage pools usable by virtual machines appear here"),
                isLoading: store.isLoading,
                error: store.storagesError,
                isEmpty: store.storages.isEmpty,
                refresh: { await store.loadStorages() }
            ) {
                ForEach(store.storages) { storage in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(storage.name).font(.subheadline.weight(.medium))
                            Spacer()
                            Text(String(format: "%.1f%%", storage.usedPercent))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        Text(storage.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        ProgressView(value: min(max(storage.usedPercent, 0), 100), total: 100)
                            .tint(storage.usedPercent >= 90 ? .red : .accentColor)
                        Text(VMFormatting.bytes(storage.available))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var instanceContent: some View {
        Group {
            if store.isLoading && store.vms.isEmpty {
                LoadingView()
            } else if store.vmsError != nil && store.vms.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await store.loadVms() }
                }
            } else if store.vms.isEmpty {
                EmptyStateView(
                    icon: "desktopcomputer",
                    message: translations.get("vmInstanceEmptyTitle", fallback: "No virtual machines"),
                    description: translations.get("vmInstanceEmptyDescription",
                                                 fallback: "Virtual machines created on the panel appear here")
                )
            } else {
                List {
                    if let error = store.vmsError {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section {
                        ForEach(store.vms) { vm in
                            NavigationLink(value: vm.name) {
                                VMInstanceRow(vm: vm)
                            }
                            .contextMenu {
                                ForEach(VMPowerAction.available(vm.capabilities)) { action in
                                    Button(role: action.destructive ? .destructive : nil) {
                                        pendingName = vm.name
                                        pendingAction = action
                                    } label: {
                                        Label(powerTitle(action), systemImage: action.icon)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.loadVms()
                }
            }
        }
    }

    private var overviewContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox(label: Label(translations.get("vmEnvironmentSectionTitle",
                                                        fallback: "Environment"),
                                      systemImage: "server.rack")) {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoLine(
                            label: translations.get("vmEnvironmentArchLabel", fallback: "Architecture"),
                            value: store.environment.arch
                        )
                        environmentRow(
                            translations.get("vmEnvironmentHelperLabel", fallback: "Helper"),
                            ok: store.environment.helperExist,
                            message: store.environment.helperMessage
                        )
                        environmentRow(
                            translations.get("vmEnvironmentKvmLabel", fallback: "KVM"),
                            ok: store.environment.kvmExist,
                            message: store.environment.kvmMessage
                        )
                        environmentRow(
                            translations.get("vmEnvironmentLibvirtLabel", fallback: "libvirt"),
                            ok: store.environment.libvirtActive,
                            message: store.environment.libvirtMessage
                        )
                        environmentRow(
                            translations.get("vmEnvironmentStorageLabel", fallback: "Storage"),
                            ok: store.environment.storageExist,
                            message: store.environment.storageMessage
                        )
                    }
                    .padding(.vertical, 4)
                }

                GroupBox(label: Label(translations.get("vmTabInstances", fallback: "Virtual Machines"),
                                      systemImage: "desktopcomputer")) {
                    VStack(spacing: 8) {
                        InfoLine(
                            label: translations.get("vmOverviewRunningLabel", fallback: "Running"),
                            value: "\(store.runningCount)"
                        )
                        InfoLine(
                            label: translations.get("vmOverviewStoppedLabel", fallback: "Stopped"),
                            value: "\(store.stoppedCount)"
                        )
                        InfoLine(
                            label: translations.get("vmOverviewCreatingLabel", fallback: "Creating"),
                            value: "\(store.creatingCount)"
                        )
                        InfoLine(
                            label: translations.get("vmOverviewAbnormalLabel", fallback: "Abnormal"),
                            value: "\(store.abnormalCount)"
                        )
                        InfoLine(
                            label: translations.get("vmInstanceCpuLabel", fallback: "CPU"),
                            value: "\(store.allocatedCpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores"))"
                        )
                        InfoLine(
                            label: translations.get("vmInstanceMemoryLabel", fallback: "Memory"),
                            value: VMFormatting.mib(store.allocatedMemoryMiB)
                        )
                    }
                    .padding(.vertical, 4)
                }

                GroupBox(label: Label(translations.get("vmOverviewStorageSectionTitle",
                                                        fallback: "Storage Pools"),
                                      systemImage: "externaldrive")) {
                    VStack(alignment: .leading, spacing: 8) {
                        if store.storages.isEmpty {
                            Text(translations.get("vmStorageEmptyTitle", fallback: "No storage pools"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(store.storages) { storage in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(storage.name).font(.subheadline)
                                    Spacer()
                                    Text(String(format: "%.1f%%", storage.usedPercent))
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                ProgressView(value: min(max(storage.usedPercent, 0), 100), total: 100)
                                    .tint(storage.usedPercent >= 90 ? .red : .accentColor)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .refreshable {
            await store.loadAll()
        }
    }

    private var environmentBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: store.environmentError == nil
                  ? "exclamationmark.triangle.fill"
                  : "xmark.octagon.fill")
                .foregroundStyle(store.environmentError == nil ? .orange : .red)
            Text(store.environmentError ?? translations.get(
                "vmEnvironmentNotReady",
                fallback: "Virtualization is not ready"
            ))
            .font(.subheadline)
            Spacer()
            if store.environmentError == nil && !store.environmentReady {
                Button(translations.get("vmEnvironmentEnableAction", fallback: "Enable")) {
                    showEnableConfirm = true
                }
                .disabled(store.isBusy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }

    private func environmentRow(_ title: String, ok: Bool, message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(ok ? .green : .red)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if !message.isEmpty {
                    Text(message).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func sectionTitle(_ section: VirtualMachineStore.Section) -> String {
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

    private func runPower(_ action: VMPowerAction) {
        let name = pendingName
        pendingAction = nil
        Task {
            if let error = await store.operate(name: name, operation: action.id) {
                actionError = error
            }
        }
    }

    private func powerTitle(_ action: VMPowerAction) -> String {
        translations.get(action.titleKey, fallback: action.fallback)
    }

    private func confirmMessage(_ action: VMPowerAction, name: String) -> String {
        translations.get("vmInstanceOperateConfirm", fallback: "Run {operation} on {name}?")
            .replacingOccurrences(of: "{operation}", with: powerTitle(action))
            .replacingOccurrences(of: "{name}", with: name)
    }
}

struct VMInstanceRow: View {
    @EnvironmentObject private var translations: TranslationsManager
    let vm: VMInstanceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(vm.name).font(.subheadline.weight(.medium))
                Spacer()
                StatusBadge(text: vm.status, color: toneColor)
            }
            Text(metadata)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 2)
    }

    private var metadata: String {
        var items: [String] = []
        items.append("\(vm.cpu) \(translations.get("vmOverviewCoresUnit", fallback: "cores"))")
        items.append(VMFormatting.mib(vm.memoryMiB))
        items.append(VMFormatting.bytes(vm.diskSize))
        if !vm.network.isEmpty { items.append(vm.network) }
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

/// 只读资源分区的通用容器：加载、空态、错误与列表。
struct VMResourceListView<Content: View>: View {
    let title: String
    let icon: String
    let emptyMessage: String
    let emptyDescription: String
    let isLoading: Bool
    let error: String?
    let isEmpty: Bool
    let refresh: @MainActor () async -> Void
    @ViewBuilder let content: () -> Content

    @EnvironmentObject private var translations: TranslationsManager

    var body: some View {
        Group {
            if isLoading && isEmpty {
                LoadingView()
            } else if error != nil && isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await refresh() }
                }
            } else if isEmpty {
                EmptyStateView(icon: icon, message: emptyMessage, description: emptyDescription)
            } else {
                List {
                    if let error {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section(title) {
                        content()
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await refresh()
                }
            }
        }
    }
}