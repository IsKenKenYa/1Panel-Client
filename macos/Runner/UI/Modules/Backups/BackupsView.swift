import SwiftUI
import AppleSharedUI

struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var backupToDelete: BackupModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.backups.isEmpty {
                EmptyStateView(
                    icon: "archivebox",
                    message: translations.get("backupRecordsEmptyTitle", fallback: "No backups found")
                )
            } else {
                Table(viewModel.backups) {
                    TableColumn(translations.get("backupRecordsNameLabel", fallback: "Name")) { backup in
                        HStack {
                            Image(systemName: "archivebox")
                                .foregroundColor(.blue)
                            Text(backup.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                backupToDelete = backup
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("backupRecordsTypeLabel", fallback: "Type")) { backup in
                        Text(backup.type.isEmpty ? "--" : backup.type)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("appInfoStatus", fallback: "Status")) { backup in
                        if !backup.status.isEmpty {
                            let ok = backup.status.lowercased() == "success" || backup.status.lowercased() == "done"
                            Text(backup.status)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(ok ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                .foregroundColor(ok ? .green : .orange)
                                .cornerRadius(4)
                        }
                    }
                    TableColumn(translations.get("backupRecordsSizeLabel", fallback: "Size")) { backup in
                        Text(backup.size.isEmpty ? "--" : backup.size)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("backupRecordsDateLabel", fallback: "Date")) { backup in
                        Text(backup.date.isEmpty ? "--" : backup.date)
                            .foregroundColor(.secondary)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("operationsBackupsTitle", fallback: "Backups"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchBackups() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete \"\(backupToDelete?.name ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let b = backupToDelete { Task { await viewModel.deleteBackup(id: b.originalId) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This will permanently delete the backup file."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchBackups() }
    }
}
