import SwiftUI

struct ContainersView: View {
    @StateObject private var viewModel = ContainersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(TranslationsManager.shared.get("serverModuleContainers", fallback: "Containers"))
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
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.containers) { container in
                            MDCard {
                                MDListItem(
                                    title: container.name,
                                    subtitle: container.image,
                                    icon: "square.stack.3d.up"
                                ) {
                                    Text(container.state)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(container.state.lowercased() == "running" ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                                        .foregroundColor(container.state.lowercased() == "running" ? .green : .gray)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchContainers()
        }
    }
}
