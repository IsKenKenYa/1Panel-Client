import SwiftUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(translations.get("serverModuleContainers", fallback: "Containers"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
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
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchContainers()
        }
    }
}
