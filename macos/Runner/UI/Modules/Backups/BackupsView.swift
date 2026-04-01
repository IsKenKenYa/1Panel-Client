import SwiftUI

struct BackupsView: View {
    @StateObject private var viewModel = BackupsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
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
                            Button(action: {
                                Task {
                                    await viewModel.deleteBackup(id: backup.originalId)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("backup_type", fallback: "Type")) { backup in
                        Text(backup.type)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("backup_size", fallback: "Size")) { backup in
                        Text(backup.size)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("backup_date", fallback: "Date")) { backup in
                        Text(backup.date)
                            .foregroundColor(.secondary)
                    }
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.disabled)
            }
        }
        .navigationTitle(translations.get("operationsBackupsTitle", fallback: "Backups"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchBackups()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchBackups()
        }
    }
}