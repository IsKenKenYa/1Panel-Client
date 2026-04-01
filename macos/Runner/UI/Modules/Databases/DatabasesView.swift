import SwiftUI

struct DatabasesView: View {
    @StateObject private var viewModel = DatabasesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var dbToDelete: DatabaseModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.databases.isEmpty {
                Text("No databases found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.databases) {
                    TableColumn(translations.get("database_name", fallback: "Name")) { db in
                        HStack {
                            Image(systemName: "externaldrive.connected.to.line.below")
                                .foregroundColor(.blue)
                            Text(db.name)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                dbToDelete = db
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("database_type", fallback: "Type")) { db in
                        Text(db.type.isEmpty ? "--" : db.type)
                            .foregroundColor(.secondary)
                    }
                    TableColumn("Version") { db in
                        Text(db.version.isEmpty ? "--" : db.version)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { db in
                        let isRunning = db.status.lowercased() == "running"
                        Text(db.status.isEmpty ? "--" : db.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isRunning ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                            .foregroundColor(isRunning ? .green : .red)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleDatabases", fallback: "Databases"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchDatabases() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(dbToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let d = dbToDelete { Task { await viewModel.deleteDatabase(id: d.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete the database and all its data. This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchDatabases() }
    }
}
