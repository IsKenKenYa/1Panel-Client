import SwiftUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var containerToDelete: ContainerModel?
    @State private var showDeleteConfirm = false
    @State private var logsContainer: ContainerModel?

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.containers.isEmpty {
                EmptyStateView(
                    icon: "cube.box",
                    message: translations.get("containerEmptyTitle", fallback: "No containers found")
                )
            } else {
                Table(viewModel.containers) {
                    TableColumn(translations.get("containerInfoName", fallback: "Name")) { container in
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundColor(.blue)
                            Text(container.name)
                        }
                        .contextMenu {
                            let isRunning = container.state.lowercased() == "running"
                            Button {
                                Task { await viewModel.toggleContainerState(id: container.originalId, currentState: container.state) }
                            } label: {
                                Label(
                                    isRunning ? translations.get("commonStop", fallback: "Stop") : translations.get("commonStart", fallback: "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            Button {
                                Task { await viewModel.restartContainer(id: container.originalId) }
                            } label: {
                                Label(translations.get("commonRestart", fallback: "Restart"), systemImage: "arrow.clockwise")
                            }
                            Button {
                                viewModel.fetchLogs(name: container.name)
                                logsContainer = container
                            } label: {
                                Label(translations.get("containerActionLogs", fallback: "Logs"), systemImage: "doc.text")
                            }
                            Divider()
                            Button(role: .destructive) {
                                containerToDelete = container
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("containerInfoImage", fallback: "Image")) { container in
                        Text(container.image)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn(translations.get("appInfoStatus", fallback: "Status")) { container in
                        Text(container.status.isEmpty ? container.state : container.status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn(translations.get("containerStateLabel", fallback: "State")) { container in
                        let isRunning = container.state.lowercased() == "running"
                        Text(container.state)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isRunning ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                            .foregroundColor(isRunning ? .green : .gray)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleContainers", fallback: "Containers"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchContainers() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete \"\(containerToDelete?.name ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let c = containerToDelete { Task { await viewModel.deleteContainer(id: c.originalId) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
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
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(container.name) - \(translations.get("containerActionLogs", fallback: "Logs"))")
                        .font(.headline)
                    Spacer()
                    if viewModel.isLoadingLogs {
                        ProgressView().scaleEffect(0.6)
                    }
                    Button {
                        viewModel.fetchLogs(name: container.name)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
                if viewModel.logs.isEmpty {
                    Text(translations.get("containerLogsEmpty", fallback: "No logs"))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        Text(viewModel.logs)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                HStack {
                    Spacer()
                    Button(translations.get("commonClose", fallback: "Close")) {
                        logsContainer = nil
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding(20)
            .frame(width: 640, height: 480)
        }
        .onAppear { viewModel.fetchContainers() }
    }
}
