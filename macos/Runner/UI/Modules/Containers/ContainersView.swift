import SwiftUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
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
                            Button(action: {
                                Task {
                                    await viewModel.toggleContainerState(id: container.originalId, currentState: container.state)
                                }
                            }) {
                                Text(isRunning ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"))
                                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            }
                            Button(action: {
                                Task {
                                    await viewModel.restartContainer(id: container.originalId)
                                }
                            }) {
                                Text(translations.get("restart", fallback: "Restart"))
                                Image(systemName: "arrow.clockwise")
                            }
                            Divider()
                            Button(action: {
                                Task {
                                    await viewModel.deleteContainer(id: container.originalId)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("container_image", fallback: "Image")) { container in
                        Text(container.image)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("container_state", fallback: "State")) { container in
                        let isRunning = container.state.lowercased() == "running"
                        Text(container.state)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isRunning ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(isRunning ? .green : .gray)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.disabled)
            }
        }
        .navigationTitle(translations.get("serverModuleContainers", fallback: "Containers"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchContainers()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchContainers()
        }
    }
}
