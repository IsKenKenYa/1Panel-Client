import AppleSharedUI
import SwiftUI

/// 容器日志跟随视图。
///
/// 跟随中持续追加并滚动到底部；关闭跟随回放最近一次日志快照。
/// 视图离开或应用进入后台时结束订阅，避免服务端连接悬挂。
/// 快速停止再恢复由 `ContainerLogStreamStore` 按代次丢弃旧回调。
struct ContainerLogsFollowView: View {
    let containerName: String
    let fetchSnapshot: () async throws -> String

    @EnvironmentObject private var translations: TranslationsManager
    @EnvironmentObject private var navigation: ServerNavigation
    @Environment(\.scenePhase) private var scenePhase
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

    @State private var snapshot: String?
    @State private var snapshotError: String?
    @State private var isLoadingSnapshot = false
    @State private var snapshotRequest = 0
    @State private var followServerID: String?

    private let bottomID = "container-log-bottom"

    var body: some View {
        VStack(spacing: 0) {
            followBar
            Divider()
            content
        }
        .task {
            followServerID = navigation.activeServerID
            await stream.follow(container: containerName)
        }
        .onChange(of: navigation.activeServerID) { serverID in
            guard stream.isActive, followServerID != serverID else { return }
            followServerID = serverID
            Task { await stream.stopFollowing() }
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .background else { return }
            Task { await stream.stopFollowing() }
        }
        .onDisappear {
            Task { await stream.close() }
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
            get: { stream.isActive },
            set: { enabled in
                if enabled {
                    Task { await stream.follow(container: containerName) }
                } else {
                    Task { await stopAndLoadSnapshot() }
                }
            }
        )
    }

    @ViewBuilder
    private var statusContent: some View {
        switch stream.phase {
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
                    Task { await stream.follow(container: containerName) }
                }
                .font(.caption)
            }
        case .failed:
            HStack(spacing: 8) {
                Text(stream.errorMessage
                     ?? t("commonLoadFailedTitle", "Failed to load"))
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                Button(t("commonRetry", "Retry")) {
                    Task { await stream.follow(container: containerName) }
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
        if stream.isActive || stream.hasEnded || stream.phase == .failed {
            streamContent
        } else if isLoadingSnapshot || snapshot != nil || snapshotError != nil {
            snapshotContent
        } else if !stream.text.isEmpty {
            logScroll(stream.text, autoScroll: false)
        } else {
            LoadingView()
        }
    }

    @ViewBuilder
    private var streamContent: some View {
        if stream.text.isEmpty {
            if stream.phase == .failed {
                ErrorView(message: stream.errorMessage
                          ?? t("commonLoadFailedTitle", "Failed to load")) {
                    Task { await stream.follow(container: containerName) }
                }
            } else if stream.hasEnded {
                EmptyStateView(
                    icon: "doc.text",
                    message: t("containerLogsEmpty", "No logs")
                )
            } else {
                LoadingView()
            }
        } else {
            logScroll(stream.text, autoScroll: stream.isActive)
        }
    }

    @ViewBuilder
    private var snapshotContent: some View {
        if isLoadingSnapshot && snapshot == nil {
            LoadingView()
        } else if let snapshotError, snapshot == nil {
            ErrorView(message: snapshotError) {
                Task { await loadSnapshot() }
            }
        } else if let snapshot {
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
            .onChange(of: stream.revision) { _ in
                guard autoScroll, stream.isActive else { return }
                proxy.scrollTo(bottomID, anchor: .bottom)
            }
            .onAppear {
                if autoScroll {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
        }
    }

    private func stopAndLoadSnapshot() async {
        isLoadingSnapshot = true
        snapshotError = nil
        await stream.stopFollowing()
        await loadSnapshot()
    }

    private func loadSnapshot() async {
        snapshotRequest += 1
        let request = snapshotRequest
        isLoadingSnapshot = true
        snapshotError = nil
        do {
            let text = try await fetchSnapshot()
            guard request == snapshotRequest else { return }
            snapshot = text
        } catch {
            guard request == snapshotRequest else { return }
            snapshotError = error.localizedDescription
        }
        if request == snapshotRequest {
            isLoadingSnapshot = false
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}