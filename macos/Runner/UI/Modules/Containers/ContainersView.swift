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

struct ContainerLogsSheet: View {
    let containerName: String
    let fetchLogs: @MainActor () async throws -> String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager
    /// 与 iOS 共用的会话：跟随意愿、连接状态与快照规则只有一处实现。
    @StateObject private var session: ContainerLogsSession
    @State private var refreshCount = 0

    init(
        containerName: String,
        fetchLogs: @escaping @MainActor () async throws -> String
    ) {
        self.containerName = containerName
        self.fetchLogs = fetchLogs
        _session = StateObject(wrappedValue: ContainerLogsSession(
            container: containerName,
            store: ContainerLogStreamStore(
                start: { container, tail, onChunk, onDone, onError in
                    try await ChannelManager.shared.startContainerLogStream(
                        container: container,
                        tail: tail,
                        onChunk: onChunk,
                        onDone: onDone,
                        onError: onError
                    )
                },
                stop: { handle in
                    await ChannelManager.shared.stopContainerLogStream(handle: handle)
                }
            ),
            fetchSnapshot: fetchLogs
        ))
    }

    /// 用调用方提供的会话渲染，供真实链路测试观察同一实例。
    init(containerName: String, session: ContainerLogsSession) {
        self.containerName = containerName
        self.fetchLogs = { "" }
        _session = StateObject(wrappedValue: session)
    }

    private var stream: ContainerLogStreamStore { session.store }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(translations.get("containerActionLogs", fallback: "Logs"))
                    .font(.headline)
                Text(containerName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Toggle(
                    translations.get("containerLogsAutoRefresh", fallback: "Auto Refresh"),
                    isOn: Binding(
                        get: { session.wantsFollow },
                        set: { follow in
                            Task { await session.setFollow(follow) }
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
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
            content
            HStack {
                Spacer()
                Button(translations.get("commonClose", fallback: "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 640, height: 480)
        .onAppear {
            // 打开弹窗即按初始跟随意愿建立连接，不要求用户先关再开。
            Task { await session.appear() }
        }
        .onDisappear {
            // 弹窗关闭视为对象永久结束，连接立即终止并拒绝后续开始。
            Task { await session.finish() }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didResignActiveNotification
        )) { _ in
            Task { await session.leave() }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )) { _ in
            Task { await session.appear() }
        }
        .onChange(of: refreshCount) { _ in
            Task { await session.setFollow(false) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if session.wantsFollow && stream.phase == .idle {
            if stream.text.isEmpty {
                LoadingView()
            } else {
                logScroll(stream.text)
            }
        } else if stream.isActive || stream.hasEnded || stream.phase == .failed {
            streamContent
        } else if !session.displayText.isEmpty {
            VStack(spacing: 0) {
                if let snapshotError = session.snapshotError, !stream.text.isEmpty {
                    inlineNotice(snapshotError)
                }
                logScroll(session.displayText)
            }
        } else if session.isLoadingSnapshot || session.snapshotError != nil {
            snapshotContent
        } else {
            LoadingView()
        }
    }

    @ViewBuilder
    private var streamContent: some View {
        if stream.text.isEmpty {
            if stream.phase == .failed {
                ErrorView(message: LogStreamErrorText.display(stream.errorMessage)
                          ?? translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    Task { await session.retry() }
                }
            } else if stream.hasEnded {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("containerLogsEmpty", fallback: "No logs")
                )
            } else {
                LoadingView()
            }
        } else {
            VStack(spacing: 0) {
                logScroll(stream.text)
                statusFooter
            }
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        if let streamError = LogStreamErrorText.display(stream.errorMessage) {
            HStack(spacing: 8) {
                Label(streamError, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .help(stream.errorMessage ?? "")
                Button(translations.get("commonRetry", fallback: "Retry")) {
                    Task { await session.retry() }
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
                    Task { await session.retry() }
                }
            }
        }
    }

    @ViewBuilder
    private var snapshotContent: some View {
        if session.isLoadingSnapshot && session.snapshot == nil {
            LoadingView()
        } else if let snapshotError = session.snapshotError, session.snapshot == nil {
            ErrorView(message: snapshotError) {
                Task { await session.setFollow(false) }
            }
        } else if let snapshot = session.snapshot {
            if snapshot.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("containerLogsEmpty", fallback: "No logs")
                )
            } else {
                logScroll(snapshot)
            }
        } else {
            LoadingView()
        }
    }

    private func inlineNotice(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func logScroll(_ text: String) -> some View {
        ScrollView {
            Text(verbatim: text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(text)
                .accessibilityIdentifier("containerLogs.text")
        }
    }
}
