import SwiftUI
import AppleSharedUI

/// 容器列表：行级操作——启动/停止、重启、删除（二次确认）。
struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var containerToDelete: ContainerModel?
    @State private var showDeleteConfirm = false
    @State private var showCreateSheet = false
    @State private var toastText: String?

    /// 走查钩子：`ONEPANEL_OPEN_CONTAINER_LOGS=<容器名>` 直接呈现日志页。
    private var logsOverride: String? {
        ProcessInfo.processInfo.environment["ONEPANEL_OPEN_CONTAINER_LOGS"]
    }

    var body: some View {
        if let name = logsOverride {
            ContainerDetailView(containerName: name)
        } else {
            containerList
        }
    }

    private var containerList: some View {
        Group {
            if viewModel.isLoading && viewModel.containers.isEmpty {
                LoadingView()
            } else if viewModel.loadFailed && viewModel.containers.isEmpty {
                ErrorView(message: translations.get("commonLoadFailedTitle", fallback: "Failed to load")) {
                    viewModel.fetchContainers()
                }
            } else if viewModel.containers.isEmpty {
                EmptyStateView(
                    icon: "cube.box",
                    message: translations.get("containerEmptyTitle", fallback: "No containers found"),
                    description: translations.get("containerEmptyDesc",
                                                  fallback: "Tap the button below to create a container")
                )
            } else {
                List {
                    ForEach(viewModel.containers) { container in
                        NavigationLink(value: ServerRoute.container(name: container.name)) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(container.name)
                                        .font(.headline)
                                    Spacer()
                                    StatusBadge(
                                        text: container.state,
                                        color: StatusPalette.containerState(container.state)
                                    )
                                }
                                Text(container.image)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                HStack(spacing: 16) {
                                    if let cpu = container.cpuUsage {
                                        Label(String(format: "%.2f%%", cpu), systemImage: "cpu")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                    }
                                    if let mem = container.memoryUsage {
                                        Label(formatSize(Int64(mem)), systemImage: "memorychip")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                containerToDelete = container
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            let isRunning = container.state.lowercased() == "running"
                            Button {
                                toggle(container, running: isRunning)
                            } label: {
                                Label(
                                    translations.get(isRunning ? "commonStop" : "commonStart",
                                                     fallback: isRunning ? "Stop" : "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            .tint(isRunning ? .orange : .green)
                            Button {
                                restart(container)
                            } label: {
                                Label(translations.get("commonRestart", fallback: "Restart"),
                                      systemImage: "arrow.clockwise")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetchContainers()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("containerCreate", fallback: "Create Container"),
                          systemImage: "plus")
                }
                Button {
                    viewModel.fetchContainers()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerCreateSheet(onCreated: {
                viewModel.fetchContainers()
            })
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let container = containerToDelete else { return }
                containerToDelete = nil
                viewModel.deleteContainer(id: container.originalId) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetchContainers()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                containerToDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onChange(of: viewModel.loadFailed) { failed in
            if failed && !viewModel.containers.isEmpty {
                showToast(translations.get("commonLoadFailedTitle", fallback: "Failed to load"))
            }
        }
        .onAppear {
            viewModel.fetchContainers()
        }
    }

    private func toggle(_ container: ContainerModel, running: Bool) {
        let targetState = running ? "stop" : "start"
        viewModel.toggleState(id: container.originalId, to: targetState) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchContainers()
        }
    }

    private func restart(_ container: ContainerModel) {
        viewModel.restart(id: container.originalId) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchContainers()
        }
    }

    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
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
