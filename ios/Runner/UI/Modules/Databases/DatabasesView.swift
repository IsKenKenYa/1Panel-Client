import SwiftUI

struct DatabaseModel: Identifiable {
    let id: Int
    let name: String
    let type: String
    let version: String
    let status: String
}

class DatabasesViewModel: ObservableObject {
    @Published var databases: [DatabaseModel] = []
    @Published var isLoading = false

    func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getDatabases") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.databases = items.compactMap { item in
                    guard let id = item["id"] as? Int,
                          let name = item["name"] as? String else { return nil }
                    return DatabaseModel(
                        id: id,
                        name: name,
                        type: item["type"] as? String ?? "",
                        version: item["version"] as? String ?? "",
                        status: item["status"] as? String ?? ""
                    )
                }
            }
        }
    }
}

/// 数据库列表：名称、类型与版本、运行状态。
struct DatabasesView: View {
    @StateObject private var viewModel = DatabasesViewModel()
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.databases.isEmpty {
                LoadingView()
            } else if viewModel.databases.isEmpty {
                EmptyStateView(
                    icon: "cylinder.split.1x2",
                    message: translations.get("databasesEmptyTitle", fallback: "No databases"),
                    description: translations.get("databasesEmptyHint",
                                                  fallback: "Databases created in 1Panel appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.databases) { database in
                        HStack(spacing: 14) {
                            Image(systemName: "cylinder.split.1x2")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(database.name)
                                    .font(.headline)
                                Text(versionLine(database))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            StatusBadge(text: database.status, color: database.status.lowercased() == "running" ? .green : .gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleDatabases", fallback: "Databases"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .databases)
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.fetch()
        }
    }

    private func versionLine(_ database: DatabaseModel) -> String {
        if database.type.isEmpty { return database.version }
        if database.version.isEmpty { return database.type }
        return "\(database.type) · \(database.version)"
    }
}
