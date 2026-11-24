import SwiftUI
import AppleSharedUI

enum ContainerSection: String, CaseIterable, Identifiable {
    case containers
    case images
    case networks
    case volumes
    case compose
    case repositories
    case templates

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .containers: return "containerTabContainers"
        case .images: return "containerTabImages"
        case .networks: return "containerTabNetworks"
        case .volumes: return "containerTabVolumes"
        case .compose: return "orchestrationCompose"
        case .repositories: return "containerTabRepositories"
        case .templates: return "containerTabTemplates"
        }
    }
}

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = ContainerSection(
        rawValue: ProcessInfo.processInfo.environment["ONEPANEL_CONTAINER_TAB"] ?? ""
    ) ?? .containers
    @State private var containerToDelete: ContainerModel?
    @State private var logsContainer: ContainerModel?
    @State private var detailContainer: ContainerModel?
    @State private var showCreateSheet = false

    /// 七个分区用标题菜单承载。分段控件在窄窗口会被压到最小宽度，
    /// 把 NavigationSplitView 侧栏一起挤掉，菜单不占横向空间。
    private var sectionPicker: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(ContainerSection.allCases) { item in
                    Button {
                        section = item
                    } label: {
                        if section == item {
                            Label(title(item), systemImage: "checkmark")
                        } else {
                            Text(title(item))
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(title(section))
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func title(_ item: ContainerSection) -> String {
        translations.get(item.titleKey, fallback: fallbackTitle(item))
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker
            Divider()
            Group {
                switch section {
                case .containers:
                    containersContent
                case .images:
                    ContainerImagesSectionView()
                case .networks:
                    ContainerNetworksSectionView()
                case .volumes:
                    ContainerVolumesSectionView()
                case .compose:
                    ContainerComposeSectionView()
                case .repositories:
                    ContainerReposSectionView()
                case .templates:
                    ContainerTemplatesSectionView()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleContainers", fallback: "Containers"))
        .toolbar {
            if section == .containers {
                ToolbarItemGroup(placement: .automatic) {
                    if viewModel.isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Button {
                            Task { await viewModel.fetchContainers() }
                        } label: {
                            Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                        }
                        .help(translations.get("commonRefresh", fallback: "Refresh"))
                    }
                    Button {
                        showCreateSheet = true
                    } label: {
                        Label(translations.get("containerCreate", fallback: "Create Container"),
                              systemImage: "plus")
                    }
                    .help(translations.get("containerCreate", fallback: "Create Container"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { containerToDelete != nil },
                set: { if !$0 { containerToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: containerToDelete
        ) { container in
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                Task { await viewModel.deleteContainer(id: container.originalId) }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { container in
            Text("\(container.name)\n\(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))")
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $logsContainer) { container in
            ContainerLogsSheet(containerName: container.name) {
                try await viewModel.fetchLogs(name: container.name)
            }
            .id(container.id)
        }
        .sheet(item: $detailContainer) { container in
            ContainerDetailView(viewModel: viewModel, container: container)
                .frame(minWidth: 820, minHeight: 620)
                .id("detail-\(container.id)")
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerCreateSheet {
                Task { await viewModel.fetchContainers() }
            }
            .environmentObject(translations)
        }
        .task { await viewModel.fetchContainers() }
    }

    private var containersContent: some View {
        Group {
            if viewModel.isLoading && viewModel.containers.isEmpty {
                LoadingView()
            } else if viewModel.containers.isEmpty {
                EmptyStateView(
                    icon: "cube.box",
                    message: translations.get("containerEmptyTitle", fallback: "No containers found")
                )
            } else {
                List {
                    ForEach(viewModel.containers) { container in
                        containerRow(container)
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func containerRow(_ container: ContainerModel) -> some View {
        let isRunning = container.state.lowercased() == "running"
        let subtitle = container.status.isEmpty ? container.image : container.status
        return ModuleRow(
            icon: "square.stack.3d.up",
            iconColor: .blue,
            title: container.name,
            subtitle: subtitle,
            badge: container.state.isEmpty ? nil : (container.state,
                                                   isRunning ? .green : .gray),
            onOpen: { detailContainer = container }
        ) {
            RowActionsMenu {
                Button {
                    detailContainer = container
                } label: {
                    Label(translations.get("containerDetailTitle",
                                           fallback: "Container Details"),
                          systemImage: "info.circle")
                }
                Button {
                    Task {
                        await viewModel.toggleContainerState(
                            id: container.originalId,
                            currentState: container.state
                        )
                    }
                } label: {
                    Label(isRunning
                          ? translations.get("commonStop", fallback: "Stop")
                          : translations.get("commonStart", fallback: "Start"),
                          systemImage: isRunning ? "stop.fill" : "play.fill")
                }
                Button {
                    Task { await viewModel.restartContainer(id: container.originalId) }
                } label: {
                    Label(translations.get("commonRestart", fallback: "Restart"),
                          systemImage: "arrow.clockwise")
                }
                Button {
                    logsContainer = container
                } label: {
                    Label(translations.get("containerActionLogs", fallback: "Logs"),
                          systemImage: "doc.text")
                }
                let isPaused = container.state.lowercased() == "paused"
                if isRunning || isPaused {
                    Button {
                        Task {
                            if isPaused {
                                await viewModel.unpauseContainer(id: container.originalId)
                            } else {
                                await viewModel.pauseContainer(id: container.originalId)
                            }
                        }
                    } label: {
                        Label(isPaused
                              ? translations.get("containerActionResume", fallback: "Resume")
                              : translations.get("containerActionPause", fallback: "Pause"),
                              systemImage: isPaused ? "play.circle" : "pause.circle")
                    }
                }
                if isRunning {
                    Button {
                        Task { await viewModel.killContainer(id: container.originalId) }
                    } label: {
                        Label(translations.get("containerActionForceStop",
                                               fallback: "Force stop"),
                              systemImage: "xmark.octagon")
                    }
                }
                Divider()
                Button(role: .destructive) {
                    containerToDelete = container
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            }
            .disabled(viewModel.isBusy)
        }
        .contextMenu {
            Button {
                detailContainer = container
            } label: {
                Label(translations.get("containerDetailTitle",
                                       fallback: "Container Details"),
                      systemImage: "info.circle")
            }
            Button {
                Task {
                    await viewModel.toggleContainerState(
                        id: container.originalId,
                        currentState: container.state
                    )
                }
            } label: {
                Label(
                    isRunning
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: isRunning ? "stop.fill" : "play.fill"
                )
            }
            .disabled(viewModel.isBusy)
            Button {
                Task { await viewModel.restartContainer(id: container.originalId) }
            } label: {
                Label(translations.get("commonRestart", fallback: "Restart"),
                      systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isBusy)
            Button {
                logsContainer = container
            } label: {
                Label(translations.get("containerActionLogs", fallback: "Logs"),
                      systemImage: "doc.text")
            }
            let isPausedMenu = container.state.lowercased() == "paused"
            if isPausedMenu || isRunning {
                Button {
                    Task {
                        if isPausedMenu {
                            await viewModel.unpauseContainer(id: container.originalId)
                        } else {
                            await viewModel.pauseContainer(id: container.originalId)
                        }
                    }
                } label: {
                    Label(
                        isPausedMenu
                            ? translations.get("containerActionResume", fallback: "Resume")
                            : translations.get("containerActionPause", fallback: "Pause"),
                        systemImage: isPausedMenu ? "play.circle" : "pause.circle"
                    )
                }
                .disabled(viewModel.isBusy)
            }
            if isRunning {
                Button {
                    Task { await viewModel.killContainer(id: container.originalId) }
                } label: {
                    Label(translations.get("containerActionForceStop",
                                           fallback: "Force stop"),
                          systemImage: "xmark.octagon")
                }
                .disabled(viewModel.isBusy)
            }
            Divider()
            Button(role: .destructive) {
                containerToDelete = container
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
            .disabled(viewModel.isBusy)
        }
    }

    private func fallbackTitle(_ section: ContainerSection) -> String {
        switch section {
        case .containers: return "Containers"
        case .images: return "Images"
        case .networks: return "Networks"
        case .volumes: return "Volumes"
        case .compose: return "Compose"
        case .repositories: return "Repositories"
        case .templates: return "Templates"
        }
    }
}

private struct ContainerLogsSheet: View {
    let containerName: String
    let fetchLogs: @MainActor () async throws -> String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager
    @State private var logs: String?
    @State private var loadError: String?
    @State private var isLoading = true
    @State private var refreshCount = 0
    /// 用户的跟随意愿；弹窗关闭只结束连接，不改变意愿。
    @State private var wantsFollow = true
    @StateObject private var stream = ContainerLogStreamStore(
        start: { container, tail, onChunk, onDone, onError in
            try await ChannelManager.shared.startContainerLogStream(
                container: container,
                tail: tail,
                onChunk: onChunk,
                onDone: onDone,
                onError: onError
            )
        },
        stop: { await ChannelManager.shared.stopContainerLogStream() }
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(translations.get("containerActionLogs", fallback: "Logs"))
                    .font(.headline)
                Text(containerName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if isLoading && logs != nil {
                    ProgressView().controlSize(.small)
                }
                Toggle(
                    translations.get("containerLogsAutoRefresh", fallback: "Auto Refresh"),
                    isOn: Binding(
                        get: { wantsFollow },
                        set: { follow in
                            wantsFollow = follow
                            Task {
                                if follow {
                                    await stream.follow(container: containerName)
                                } else {
                                    await stream.stopFollowing()
                                }
                            }
                        }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
                Button {
                    refreshCount += 1
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
            if stream.phase != .idle {
                if !stream.text.isEmpty {
                    ScrollView {
                        Text(verbatim: stream.text)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if stream.isActive {
                    LoadingView()
                } else if stream.hasEnded {
                    EmptyStateView(
                        icon: "doc.text",
                        message: translations.get("containerLogsEmpty", fallback: "No logs")
                    )
                }
                if let streamError = stream.errorMessage {
                    HStack(spacing: 8) {
                        Label(streamError, systemImage: "exclamationmark.triangle")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        Button(translations.get("commonRetry", fallback: "Retry")) {
                            Task { await stream.follow(container: containerName) }
                        }
                    }
                } else if stream.hasEnded {
                    HStack(spacing: 8) {
                        Text(translations.get("containerLogsStreamEnded",
                                              fallback: "Log stream ended"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button(translations.get("containerLogsResumeFollow",
                                                fallback: "Resume following")) {
                            Task { await stream.follow(container: containerName) }
                        }
                    }
                }
            } else if !stream.text.isEmpty {
                // 已收到的跟随日志优先于一键快照：快照加载与失败都不遮盖它。
                if let loadError {
                    Label(loadError, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                ScrollView {
                    Text(verbatim: stream.text)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let logs {                if let loadError {
                    Label(loadError, systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                if logs.isEmpty {
                    EmptyStateView(icon: "doc.text", message: translations.get("containerLogsEmpty", fallback: "No logs"))
                } else {
                    ScrollView {
                        Text(verbatim: logs)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else if let loadError {
                ErrorView(message: loadError) { refreshCount += 1 }
            } else {
                LoadingView()
            }
            HStack {
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 640, height: 480)
        .onDisappear {
            Task { await stream.close() }
        }
        .task(id: refreshCount) {
            isLoading = true
            loadError = nil
            do {
                let received = try await fetchLogs()
                try Task.checkCancellation()
                logs = received
            } catch {
                guard !Task.isCancelled else { return }
                loadError = error.localizedDescription
            }
            isLoading = false
        }
    }
}
