import SwiftUI
import AppleSharedUI

struct BackupModel: Identifiable {
    let id: Int
    let name: String
    let type: String
    let size: String
    let status: String
    let createdAt: String
    let detailName: String
    let fileName: String
    let fileDir: String
    let downloadAccountID: Int
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
                        createdAt: item["createdAt"] as? String ?? "",
                        detailName: item["detailName"] as? String ?? "",
                        fileName: item["fileName"] as? String ?? "",
                        fileDir: item["fileDir"] as? String ?? "",
                        downloadAccountID: item["downloadAccountID"] as? Int ?? 0
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

    /// 恢复备份（restoreBackup 通道，整行字段回传）。
    func restore(record: BackupModel, completion: @escaping (Bool, String?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "restoreBackup",
            arguments: [
                "id": record.id,
                "name": record.name,
                "type": record.type,
                "detailName": record.detailName,
                "fileName": record.fileName,
                "fileDir": record.fileDir,
                "downloadAccountID": record.downloadAccountID,
            ]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(
                    dict?["success"] as? Bool ?? false,
                    dict?["error"] as? String
                )
            }
        }
    }
}

/// 备份记录列表：名称、类型、大小与生成时间，支持恢复与删除。
struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: BackupModel?
    @State private var showDeleteConfirm = false
    @State private var pendingRestore: BackupModel?
    @State private var showRestoreConfirm = false
    @State private var detailBackup: BackupModel?
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
                                    Label(TimestampFormat.display(backup.createdAt), systemImage: "calendar")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            detailBackup = backup
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = backup
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                pendingRestore = backup
                                showRestoreConfirm = true
                            } label: {
                                Label(translations.get("databaseBackupRestoreAction", fallback: "Restore"),
                                      systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
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
        .confirmationDialog(
            translations.get("databaseBackupRestoreConfirmMessage",
                             fallback: "Restore this backup? Existing data may be overwritten."),
            isPresented: $showRestoreConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("databaseBackupRestoreAction", fallback: "Restore")) {
                restoreConfirmed()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingRestore = nil
            }
        }
        .operationNotice(toastText)
        .sheet(item: $detailBackup) { backup in
            BackupDetailView(backup: backup, viewModel: viewModel)
                .environmentObject(translations)
        }
        .onAppear {
            viewModel.fetch()
        }
    }

    private func restoreConfirmed() {
        guard let backup = pendingRestore else { return }
        pendingRestore = nil
        viewModel.restore(record: backup) { success, error in
            if success {
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
}
