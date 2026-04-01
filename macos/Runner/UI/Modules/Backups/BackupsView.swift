import SwiftUI

struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var backupToDelete: BackupModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.backups.isEmpty {
                Text("No backups found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.backups) {
                    TableColumn(translations.get("backup_name", fallback: "Name")) { backup in
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
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("backup_type", fallback: "Type")) { backup in
                        Text(backup.type.isEmpty ? "--" : backup.type)
                            .foregroundColor(.secondary)
                    }
                    TableColumn("Status") { backup in
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
                    TableColumn(translations.get("backup_size", fallback: "Size")) { backup in
                        Text(backup.size.isEmpty ? "--" : backup.size)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("backup_date", fallback: "Date")) { backup in
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
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(backupToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let b = backupToDelete { Task { await viewModel.deleteBackup(id: b.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the backup file.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchBackups() }
    }
}
