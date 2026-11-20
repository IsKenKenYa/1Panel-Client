import SwiftUI
import AppleSharedUI

struct DatabaseModel: Identifiable {
    let id: Int
    let name: String
    let lookupName: String
    let source: String
    let type: String
    let engine: String
    let version: String
    let status: String
    let description: String

    var reference: DatabaseRef {
        DatabaseRef(
            scope: type,
            id: id,
            name: name,
            lookupName: lookupName,
            source: source,
            engine: engine,
            version: version,
            status: status,
            description: description
        )
    }
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
                        lookupName: item["lookupName"] as? String ?? name,
                        source: item["source"] as? String ?? "local",
                        type: item["type"] as? String ?? "",
                        engine: item["engine"] as? String ?? "",
                        version: item["version"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        description: item["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    /// 新建 MySQL 数据库（createDatabase 通道，目标实例由通道自动发现）。
    func createDatabase(name: String, description: String,
                        completion: @escaping (Bool, String?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "createDatabase",
            arguments: [
                "name": name,
                "type": "mysql",
                "description": description,
                "format": "utf8mb4",
                "permission": "%",
            ]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(dict?["success"] as? Bool ?? false, dict?["error"] as? String)
            }
        }
    }
}

/// 数据库列表：名称、类型与版本、运行状态，点击进入详情（用户、改密与删除）。
struct DatabasesView: View {
    @StateObject private var viewModel = DatabasesViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newDescription = ""
    @State private var toastText: String?

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
                        NavigationLink(value: ServerRoute.database(database.reference)) {
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
                        .tint(.primary)
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
                    newName = ""
                    newDescription = ""
                    showCreateSheet = true
                } label: {
                    Label(translations.get("hostDatabaseCreate", fallback: "Create Database"),
                          systemImage: "plus")
                }
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetch()
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("databaseNameLabel", fallback: "Name"), text: $newName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("commonDescription", fallback: "Description"),
                              text: $newDescription)
                } footer: {
                    Text("MySQL · utf8mb4 · %")
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("hostDatabaseCreate", fallback: "Create Database"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createDatabase()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func createDatabase() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        viewModel.createDatabase(
            name: name,
            description: newDescription.trimmingCharacters(in: .whitespaces)
        ) { success, error in
            if success {
                showCreateSheet = false
                showToast(translations.get("commonSaveSuccess", fallback: "Saved"))
                viewModel.fetch()
            } else {
                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                showToast(template.replacingOccurrences(of: "{error}", with: error ?? ""))
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }

    private func versionLine(_ database: DatabaseModel) -> String {
        if database.type.isEmpty { return database.version }
        if database.version.isEmpty { return database.type }
        return "\(database.type) · \(database.version)"
    }
}
