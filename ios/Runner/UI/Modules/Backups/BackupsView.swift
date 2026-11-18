import SwiftUI

struct BackupModel: Identifiable {
    let id: Int
    let name: String
    let type: String
    let size: String
    let status: String
    let createdAt: String
}

class BackupsViewModel: ObservableObject {
    @Published var backups: [BackupModel] = []
    @Published var isLoading = false

    func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getBackups") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.backups = items.compactMap { item in
                    guard let id = item["id"] as? Int,
                          let name = item["name"] as? String else { return nil }
                    return BackupModel(
                        id: id,
                        name: name,
                        type: item["type"] as? String ?? "",
                        size: "\(item["size"] as? Int ?? 0)",
                        status: item["status"] as? String ?? "",
                        createdAt: item["createdAt"] as? String ?? ""
                    )
                }
            }
        }
    }

    func delete(record: BackupModel, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteBackup",
            arguments: [
                "id": record.id,
                "name": record.name,
                "type": record.type,
                "status": record.status,
            ]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }
}

/// 备份记录列表：名称、类型、大小与生成时间，支持删除。
struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: BackupModel?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.backups.isEmpty {
                LoadingView()
            } else if viewModel.backups.isEmpty {
                EmptyStateView(
                    icon: "externaldrive",
                    message: translations.get("backupRecordsEmptyTitle", fallback: "No backup records"),
                    description: translations.get("backupsEmptyHint",
                                                  fallback: "Backup records appear here after backups run in 1Panel.")
                )
            } else {
                List {
                    ForEach(viewModel.backups) { backup in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(backup.name)
                                    .font(.headline)
                                Spacer()
                                StatusBadge(
                                    text: backup.status,
                                    color: backup.status.lowercased() == "success" ? .green : .gray
                                )
                            }
                            HStack(spacing: 12) {
                                if !backup.type.isEmpty {
                                    Label(backup.type, systemImage: "doc")
                                }
                                Label(backup.size, systemImage: "internaldrive")
                                if !backup.createdAt.isEmpty {
                                    Label(backup.createdAt, systemImage: "calendar")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = backup
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .navigationTitle(translations.get("operationsBackupsTitle", fallback: "Backups"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .backups)
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let backup = pendingDelete else { return }
                pendingDelete = nil
                viewModel.delete(record: backup) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetch()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetch()
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
}
