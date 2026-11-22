import AppleSharedUI
import SwiftUI

/// macOS 容器详情：信息、日志、文件与终端四个分栏。
struct ContainerDetailView: View {
    @ObservedObject var viewModel: ContainersViewModel
    @EnvironmentObject private var translations: TranslationsManager
    let container: ContainerModel

    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_CONTAINER_TAB"] ?? "info"
    @State private var inspectText = ""
    @State private var inspectError: String?
    @State private var isLoadingInspect = false
    @State private var logs = ""
    @State private var logsError: String?
    @State private var isLoadingLogs = false
    @State private var pendingAction: ContainerDetailAction?
    @State private var actionError: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text(translations.get("containerTabInfo", fallback: "Info")).tag("info")
                Text(translations.get("containerTabLogs", fallback: "Logs")).tag("logs")
                Text(translations.get("containerTabFiles", fallback: "Files")).tag("files")
                Text(translations.get("containerTabTerminal", fallback: "Terminal")).tag("terminal")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "logs":
                logsContent
            case "files":
                ContainerFilesView(containerId: container.name)
            case "terminal":
                ContainerTerminalView(containerName: container.name)
            default:
                infoContent
            }
        }
        .navigationTitle(container.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
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
                    Label(translations.get("websitesDetailActionsTitle", fallback: "Actions"),
                          systemImage: "ellipsis.circle")
                }
                .disabled(viewModel.isBusy)
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        if tab == "info" {
                            await loadInspect()
                        } else if tab == "logs" {
                            await loadLogs()
                        }
                    }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoadingInspect || isLoadingLogs || tab == "terminal" || tab == "files")
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .confirmationDialog(
            pendingAction.map(actionLabel) ?? "",
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(actionLabel(action),
                       role: action == .stop ? .destructive : nil) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            if let action = pendingAction {
                Text("\(container.name)\n\(actionLabel(action))")
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
            if tab == "logs" {
                await loadLogs()
            } else if tab == "info" {
                await loadInspect()
            }
        }
        .onChange(of: tab) { value in
            Task {
                if value == "logs" && logs.isEmpty {
                    await loadLogs()
                }
                if value == "info" && inspectText.isEmpty {
                    await loadInspect()
                }
            }
        }
    }

    private var infoContent: some View {
        Group {
            if isLoadingInspect && inspectText.isEmpty {
                LoadingView()
            } else if let inspectError, inspectText.isEmpty {
                ErrorView(message: inspectError) {
                    Task { await loadInspect() }
                }
            } else {
                ScrollView {
                    Text(inspectText)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    private var logsContent: some View {
        Group {
            if isLoadingLogs && logs.isEmpty {
                LoadingView()
            } else if let logsError, logs.isEmpty {
                ErrorView(message: logsError) {
                    Task { await loadLogs() }
                }
            } else if logs.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("containerLogsEmpty", fallback: "No logs")
                )
            } else {
                ScrollView {
                    Text(logs)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
    }

    private func loadInspect() async {
        isLoadingInspect = true
        inspectError = nil
        do {
            inspectText = try await viewModel.fetchInspect(name: container.name)
        } catch {
            inspectError = error.localizedDescription
        }
        isLoadingInspect = false
    }

    private func loadLogs() async {
        isLoadingLogs = true
        logsError = nil
        do {
            logs = try await viewModel.fetchLogs(name: container.name, tail: "500")
        } catch {
            logsError = error.localizedDescription
        }
        isLoadingLogs = false
    }

    private func actionLabel(_ action: ContainerDetailAction) -> String {
        switch action {
        case .start: return translations.get("containerActionStart", fallback: "Start")
        case .stop: return translations.get("containerActionStop", fallback: "Stop")
        case .restart: return translations.get("containerActionRestart", fallback: "Restart")
        }
    }

    private func run(_ action: ContainerDetailAction) {
        pendingAction = nil
        Task {
            switch action {
            case .start:
                await viewModel.toggleContainerState(
                    id: container.originalId,
                    currentState: "stopped"
                )
            case .stop:
                await viewModel.toggleContainerState(
                    id: container.originalId,
                    currentState: "running"
                )
            case .restart:
                await viewModel.restartContainer(id: container.originalId)
            }
            if let error = viewModel.errorMessage {
                actionError = error
            }
        }
    }
}

enum ContainerDetailAction: String {
    case start
    case stop
    case restart
}