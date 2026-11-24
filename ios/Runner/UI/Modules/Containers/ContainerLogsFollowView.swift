import AppleSharedUI
import SwiftUI

/// 容器日志跟随视图。
///
/// 跟随中持续追加并滚动到底部；关闭跟随回放最近一次日志快照。
/// 暂时离开（切换标签、返回上一级、进入后台）只结束当前连接，
/// 用户首次进入时的跟随意愿保留，重新出现或回到前台时恢复跟随；
/// 已收到的日志在暂停与快照加载期间始终优先显示。
/// 快速停止再恢复由 `ContainerLogStreamStore` 按代次丢弃旧回调。
struct ContainerLogsFollowView: View {
    let containerName: String
    let fetchSnapshot: () async throws -> String

    @EnvironmentObject private var translations: TranslationsManager
    @EnvironmentObject private var navigation: ServerNavigation
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session: ContainerLogsSession

    @State private var followServerID: String?

    private let bottomID = "container-log-bottom"

    init(containerName: String, fetchSnapshot: @escaping () async throws -> String) {
        self.containerName = containerName
        self.fetchSnapshot = fetchSnapshot
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
                stop: { await ChannelManager.shared.stopContainerLogStream() }
            ),
            fetchSnapshot: fetchSnapshot
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            followBar
            Divider()
            content
        }
        .task {
            followServerID = navigation.activeServerID
            await session.appear()
        }
        .onChange(of: navigation.activeServerID) { serverID in
            if followServerID == nil {
                followServerID = serverID
                return
            }
            guard followServerID != serverID else { return }
            followServerID = serverID
            Task { await session.leave() }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                Task { await session.leave() }
            } else if phase == .active {
                Task { await session.appear() }
            }
        }
        .onDisappear {
            Task { await session.leave() }
        }
    }

    private var followBar: some View {
        HStack(spacing: 12) {
            Toggle(isOn: followBinding) {
                Text(t("containerLogsFollow", "Follow logs"))
                    .font(.subheadline)
            }
            .toggleStyle(.switch)
            .accessibilityHint(t("containerLogsFollowHint",
                                 "Keep receiving new container log lines"))

            Spacer(minLength: 8)

            statusContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var followBinding: Binding<Bool> {
        Binding(
            get: { session.wantsFollow },
            set: { enabled in
                Task { await session.setFollow(enabled) }
            }
        )
    }

    @ViewBuilder
    private var statusContent: some View {
        switch session.store.phase {
        case .starting:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(t("containerLogsConnecting", "Connecting to log stream"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .following:
            Label(t("containerLogsFollowing", "Following live logs"),
                  systemImage: "podcasts")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .ended:
            HStack(spacing: 8) {
                Text(t("containerLogsStreamEnded", "Log stream ended"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(t("containerLogsResumeFollow", "Resume following")) {
                    Task { await session.retry() }
                }
                .font(.caption)
            }
        case .failed:
            HStack(spacing: 8) {
                Text(session.store.errorMessage
                     ?? t("commonLoadFailedTitle", "Failed to load"))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                Button(t("commonRetry", "Retry")) {
                    Task { await session.retry() }
                }
                .font(.caption)
            }
        case .idle:
            Text(t("containerLogsFollowPaused",
                   "Follow stopped, showing loaded logs"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var content: some View {
        let store = session.store
        if session.wantsFollow && store.phase == .idle {
            if store.text.isEmpty {
                LoadingView()
            } else {
                logScroll(store.text, autoScroll: false)
            }
        } else if store.isActive || store.hasEnded || store.phase == .failed {
            streamContent
        } else if !session.displayText.isEmpty {
            // 已收到的日志优先于一键快照：快照加载与失败都不遮盖它。
            VStack(spacing: 0) {
                if session.snapshotError != nil, !store.text.isEmpty {
                    inlineNotice(session.snapshotError ?? "")
                }
                logScroll(session.displayText, autoScroll: false)
            }
        } else if session.isLoadingSnapshot || session.snapshotError != nil {
            snapshotContent
        } else {
            LoadingView()
        }
    }

    @ViewBuilder
    private var streamContent: some View {
        let store = session.store
        if store.text.isEmpty {
            if store.phase == .failed {
                ErrorView(message: store.errorMessage
                          ?? t("commonLoadFailedTitle", "Failed to load")) {
                    Task { await session.retry() }
                }
            } else if store.hasEnded {
                EmptyStateView(
                    icon: "doc.text",
                    message: t("containerLogsEmpty", "No logs")
                )
            } else {
                LoadingView()
            }
        } else {
            logScroll(store.text, autoScroll: store.isActive)
        }
    }

    private func inlineNotice(_ text: String) -> some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.callout)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemBackground))
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
                    message: t("containerLogsEmpty", "No logs")
                )
            } else {
                logScroll(snapshot, autoScroll: false)
            }
        } else {
            LoadingView()
        }
    }

    private func logScroll(_ text: String, autoScroll: Bool) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(verbatim: text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .id(bottomID)
            }
            .onChange(of: session.store.revision) { _ in
                guard autoScroll, session.store.isActive else { return }
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onAppear {
                if autoScroll {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}