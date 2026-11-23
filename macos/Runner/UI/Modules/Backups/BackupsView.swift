import SwiftUI
import AppleSharedUI

struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var backupToDelete: BackupModel?
    @State private var showDeleteConfirm = false
    @State private var section = "records"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text(translations.get("backupRecordsTitle", fallback: "Records"))
                    .tag("records")
                Text(translations.get("backupAccountsSectionTitle",
                                      fallback: "Backup accounts"))
                    .tag("accounts")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            Divider()
            Group {
                if section == "accounts" {
                    BackupAccountsSectionView()
                } else {
                    recordsContent
                }
            }
        }
        .navigationTitle(translations.get("operationsBackupsTitle", fallback: "Backups"))
    }

    private var recordsContent: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.backups.isEmpty {
                EmptyStateView(
                    icon: "archivebox",
                    message: translations.get("backupRecordsEmptyTitle", fallback: "No backups found")
                )
            } else {
                List {
                    ForEach(viewModel.backups) { backup in
                        row(backup)
                    }
                }
                .listStyle(.inset)
            }
        }
        .toolbar {
            if section == "records" {
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

    private func row(_ backup: BackupModel) -> some View {
        let ok = ["success", "done"].contains(backup.status.lowercased())
        return ModuleRow(
            icon: "archivebox",
            iconColor: .blue,
            title: backup.name,
            subtitle: [backup.type, backup.size, backup.date]
                .filter { !$0.isEmpty }
                .joined(separator: " · "),
            badge: backup.status.isEmpty ? nil : (backup.status, ok ? .green : .orange)
        ) {
            RowActions {
                RowActionButton(
                    title: translations.get("commonDelete", fallback: "Delete"),
                    systemImage: "trash",
                    destructive: true
                ) {
                    backupToDelete = backup
                    showDeleteConfirm = true
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .contextMenu {
            Button(role: .destructive) {
                backupToDelete = backup
                showDeleteConfirm = true
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
        }
    }
}
