import AppleSharedUI
import SwiftUI

/// 备份记录详情：基本字段、文件位置与恢复、删除操作。
struct BackupDetailView: View {
    let backup: BackupModel
    @ObservedObject var viewModel: BackupsViewModel

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var showDeleteConfirm = false
    @State private var showRestoreConfirm = false
    @State private var actionMessage: String?
    @State private var isDownloading = false

    var body: some View {
        NavigationStack {
            List {
                Section(translations.get("backupRecordsDetailTitle", fallback: "Backup Details")) {
                    HStack {
                        Text(backup.name)
                            .font(.headline)
                        Spacer()
                        StatusBadge(
                            text: backup.status.isEmpty ? "--" : backup.status,
                            color: backup.status.lowercased() == "success" ? .green : .gray
                        )
                    }
                    InfoLine(label: translations.get("backupRecordsNameLabel", fallback: "Name"),
                             value: backup.name)
                    InfoLine(label: translations.get("backupRecordsTypeLabel", fallback: "Type"),
                             value: backup.type.isEmpty ? "--" : backup.type)
                    InfoLine(label: translations.get("backupRecordsSizeLabel", fallback: "Size"),
                             value: sizeText)
                    InfoLine(label: translations.get("backupRecordsDateLabel", fallback: "Created"),
                             value: backup.createdAt.isEmpty
                                 ? "--"
                                 : TimestampFormat.display(backup.createdAt))
                    InfoLine(label: translations.get("backupRecordsStatusLabel", fallback: "Status"),
                             value: backup.status.isEmpty ? "--" : backup.status)
                }

                Section(translations.get("backupRecordsFileNameLabel", fallback: "File name")) {
                    InfoLine(
                        label: translations.get("backupRecordsDetailNameLabel",
                                                fallback: "Resource"),
                        value: backup.detailName.isEmpty ? "--" : backup.detailName
                    )
                    InfoLine(
                        label: translations.get("backupRecordsFileNameLabel",
                                                fallback: "File name"),
                        value: backup.fileName.isEmpty ? "--" : backup.fileName
                    )
                    InfoLine(
                        label: translations.get("backupRecordsFilePathLabel",
                                                fallback: "File path"),
                        value: backup.fileDir.isEmpty ? "--" : backup.fileDir
                    )
                    if backup.downloadAccountID > 0 {
                        InfoLine(
                            label: translations.get("backupRecordsAccountLabel",
                                                    fallback: "Download account"),
                            value: "\(backup.downloadAccountID)"
                        )
                    }
                }

                Section(translations.get("websitesDetailActionsTitle", fallback: "Actions")) {
                    Button {
                        Task { await download() }
                    } label: {
                        HStack {
                            Label(translations.get("backupRecordsDownloadAction",
                                                   fallback: "Download"),
                                  systemImage: "arrow.down.circle")
                            if isDownloading {
                                Spacer()
                                ProgressView().controlSize(.small)
                            }
                        }
                    }
                    .disabled(isDownloading || backup.fileName.isEmpty)
                    Button {
                        showRestoreConfirm = true
                    } label: {
                        Label(translations.get("backupRecordsRecoverAction", fallback: "Restore"),
                              systemImage: "arrow.uturn.backward")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(translations.get("commonDelete", fallback: "Delete"),
                              systemImage: "trash")
                    }
                }

                if let actionMessage {
                    Section {
                        Text(actionMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(translations.get("backupRecordsDetailTitle", fallback: "Backup Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                translations.get("databaseBackupRestoreConfirmMessage",
                                 fallback: "Restore this backup? Existing data may be overwritten."),
                isPresented: $showRestoreConfirm,
                titleVisibility: .visible
            ) {
                Button(translations.get("backupRecordsRecoverAction", fallback: "Restore")) {
                    restore()
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            }
            .confirmationDialog(
                translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                    delete()
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            } message: {
                Text(translations.get("deleteCannotUndoMessage",
                                      fallback: "This action cannot be undone."))
            }
        }
    }

    private var sizeText: String {
        guard let bytes = Int64(backup.size), bytes > 0 else {
            return backup.size.isEmpty ? "--" : backup.size
        }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private func download() async {
        guard !backup.fileName.isEmpty else { return }
        isDownloading = true
        actionMessage = nil
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "downloadBackupRecord",
                arguments: [
                    "downloadAccountID": backup.downloadAccountID,
                    "fileDir": backup.fileDir,
                    "fileName": backup.fileName,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                actionMessage = translations.get("filesDownloadSuccess",
                                                 fallback: "Download successful")
            } else if payload["cancelled"] as? Bool == true {
                actionMessage = nil
            } else {
                actionMessage = payload["error"] as? String
                    ?? translations.get("filesDownloadFailed", fallback: "Download failed")
            }
        } catch {
            actionMessage = error.localizedDescription
        }
        isDownloading = false
    }

    private func restore() {
        viewModel.restore(record: backup) { success, error in
            if success {
                actionMessage = translations.get("commonOperationSuccess",
                                                 fallback: "Operation succeeded")
                viewModel.fetch()
            } else {
                let template = translations.get("appOperateFailed",
                                                fallback: "Operation failed: {error}")
                actionMessage = template.replacingOccurrences(
                    of: "{error}",
                    with: error ?? ""
                )
            }
        }
    }

    private func delete() {
        viewModel.delete(record: backup) { success in
            if success {
                viewModel.fetch()
                dismiss()
            } else {
                actionMessage = translations.get("commonDeleteFailed", fallback: "Delete failed")
            }
        }
    }
}