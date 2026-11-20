import SwiftUI
import AppleSharedUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var containerToDelete: ContainerModel?
    @State private var logsContainer: ContainerModel?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.containers.isEmpty {
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
                            .disabled(viewModel.isBusy)
                            Button {
                                Task { await viewModel.restartContainer(id: container.originalId) }
                            } label: {
                                Label(translations.get("commonRestart", fallback: "Restart"), systemImage: "arrow.clockwise")
                            }
                            .disabled(viewModel.isBusy)
                            Button {
                                logsContainer = container
                            } label: {
                                Label(translations.get("containerActionLogs", fallback: "Logs"), systemImage: "doc.text")
                            }
                            Divider()
                            Button(role: .destructive) {
                                containerToDelete = container
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                            .disabled(viewModel.isBusy)
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
        .task { await viewModel.fetchContainers() }
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
                Button {
                    refreshCount += 1
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
            if let logs {
                if let loadError {
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
