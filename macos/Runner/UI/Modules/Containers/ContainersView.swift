import SwiftUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var containerToDelete: ContainerModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.containers.isEmpty {
                Text("No containers found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.containers) {
                    TableColumn(translations.get("container_name", fallback: "Name")) { container in
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
                                    isRunning ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            Button {
                                Task { await viewModel.restartContainer(id: container.originalId) }
                            } label: {
                                Label(translations.get("restart", fallback: "Restart"), systemImage: "arrow.clockwise")
                            }
                            Divider()
                            Button(role: .destructive) {
                                containerToDelete = container
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("container_image", fallback: "Image")) { container in
                        Text(container.image)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn("Status") { container in
                        Text(container.status.isEmpty ? container.state : container.status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn(translations.get("container_state", fallback: "State")) { container in
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
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(containerToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let c = containerToDelete { Task { await viewModel.deleteContainer(id: c.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchContainers() }
    }
}
