import SwiftUI
import AppleSharedUI

/// 容器详情：信息（inspect JSON）、日志与终端三个分栏，等宽文本只读展示。
/// 终端分栏通过 `NativeTerminalBridge` 在容器内执行 `/bin/sh`，
/// 工具栏提供启停与重启的等价入口。
struct ContainerDetailView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var translations: TranslationsManager
    let containerName: String

    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_CONTAINER_TAB"] ?? "info"
    @State private var toastText: String?
    @State private var pendingAction: ContainerAction?

    private enum ContainerAction: String, Identifiable {
        case start, stop, restart

        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(translations.get("containerDetailTitle", fallback: "Container details"), selection: $tab) {
                Text(translations.get("containerTabInfo", fallback: "Info")).tag("info")
                Text(translations.get("containerTabLogs", fallback: "Logs")).tag("logs")
                Text(translations.get("containerTabFiles", fallback: "Files")).tag("files")
                Text(translations.get("containerTabTerminal", fallback: "Terminal")).tag("terminal")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "logs":
                ContainerLogsFollowView(containerName: containerName) {
                    try await viewModel.fetchLogsAsync(name: containerName)
                }
                .id(containerName)
            case "files":
                ContainerFilesView(containerId: containerName)
            case "terminal":
                ContainerTerminalView(containerName: containerName)
            default:
                inspectContent
            }
        }
        .navigationTitle(containerName)
        .navigationBarTitleDisplayMode(.inline)
        .operationNotice(refreshFailed
            ? translations.get("commonLoadFailedTitle", fallback: "Failed to load")
            : toastText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        pendingAction = .start
                    } label: {
                        Label(translations.get("containerActionStart", fallback: "Start"),
                              systemImage: "play.fill")
                    }
                    Button {
                        pendingAction = .restart
                    } label: {
                        Label(translations.get("containerActionRestart", fallback: "Restart"),
                              systemImage: "arrow.clockwise")
                    }
                    Button {
                        pendingAction = .stop
                    } label: {
                        Label(translations.get("containerActionStop", fallback: "Stop"),
                              systemImage: "stop.fill")
                    }
                } label: {
                    Label(translations.get("websitesDetailActionsTitle", fallback: "Quick actions"),
                          systemImage: "ellipsis.circle")
                }
                if tab == "info" {
                    Button {
                        viewModel.fetchInspect(name: containerName)
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoadingInspect)
                }
            }
        }
        .confirmationDialog(
            actionConfirmTitle,
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(pendingAction.map(actionLabel) ?? "") {
                runAction()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingAction = nil
            }
        }
        .onAppear {
            if tab == "info" {
                viewModel.fetchInspect(name: containerName)
            }
        }
        .onChange(of: tab) { newValue in
            if newValue == "info" && viewModel.inspectText.isEmpty {
                viewModel.fetchInspect(name: containerName)
            }
        }
    }

    private var actionConfirmTitle: String {
        switch pendingAction {
        case .start:
            return translations.get("containerActionStart", fallback: "Start")
        case .restart:
            return translations.get("containerActionRestart", fallback: "Restart")
        case .stop:
            return translations.get("containerActionStop", fallback: "Stop")
        case .none:
            return ""
        }
    }

    private func actionLabel(_ action: ContainerAction) -> String {
        switch action {
        case .start: return translations.get("containerActionStart", fallback: "Start")
        case .restart: return translations.get("containerActionRestart", fallback: "Restart")
        case .stop: return translations.get("containerActionStop", fallback: "Stop")
        }
    }

    private func runAction() {
        guard let action = pendingAction else { return }
        pendingAction = nil
        switch action {
        case .start:
            viewModel.start(id: containerName) { success in
                notify(success)
            }
        case .stop:
            viewModel.stop(id: containerName) { success in
                notify(success)
            }
        case .restart:
            viewModel.restart(id: containerName) { success in
                notify(success)
            }
        }
    }

    private func notify(_ success: Bool) {
        showToast(success
            ? translations.get("containerOperateSuccess", fallback: "Operation succeeded")
            : translations.get("containerOperateFailed", fallback: "Operation failed"))
        viewModel.fetchInspect(name: containerName)
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }

    private var refreshFailed: Bool {
        viewModel.inspectFailed && !viewModel.inspectText.isEmpty
    }

    @ViewBuilder
    private var inspectContent: some View {
        if viewModel.isLoadingInspect && viewModel.inspectText.isEmpty {
            LoadingView()
        } else if viewModel.inspectFailed && viewModel.inspectText.isEmpty {
            ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                viewModel.fetchInspect(name: containerName)
            }
        } else if viewModel.inspectText.isEmpty {
            EmptyStateView(
                icon: "doc.text.magnifyingglass",
                message: translations.get("commonEmpty", fallback: "No data available")
            )
        } else {
            ScrollView {
                Text(viewModel.inspectText)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }
}
