import SwiftUI
import AppleSharedUI

struct DatabasesView: View {
    @StateObject private var viewModel = DatabasesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var selection: DatabaseModel.ID?
    @State private var detailDatabase: DatabaseModel?

    private var selectedDatabase: DatabaseModel? {
        viewModel.databases.first { $0.id == selection }
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.databases.isEmpty {
                EmptyStateView(
                    icon: "externaldrive.connected.to.line.below",
                    message: translations.get("databasesEmptyTitle", fallback: "No databases found")
                )
            } else {
                Table(viewModel.databases, selection: $selection) {
                    TableColumn(translations.get("databaseNameLabel", fallback: "Name")) { db in
                        HStack {
                            Image(systemName: "externaldrive.connected.to.line.below")
                                .foregroundColor(.blue)
                            Text(db.name)
                            .onTapGesture(count: 2) {
                                detailDatabase = db
                            }
                        }
                        .contextMenu {
                            Button {
                                detailDatabase = db
                            } label: {
                                Label(translations.get("containerDetailTitle", fallback: "Details"),
                                      systemImage: "info.circle")
                            }
                            if db.unbindArguments != nil {
                                Button(role: .destructive) {
                                    Task { await viewModel.unbind(db, confirmed: false) }
                                } label: {
                                    Label(translations.get("databaseRemoteUnbindAction", fallback: "Unbind"), systemImage: "link.badge.minus")
                                }
                                .disabled(viewModel.isProcessing)
                            }
                        }
                    }
                    TableColumn(translations.get("databaseEngineLabel", fallback: "Type")) { db in
                        Text(db.type.isEmpty ? "--" : db.type)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("databaseVersionLabel", fallback: "Version")) { db in
                        Text(db.version.isEmpty ? "--" : db.version)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("appInfoStatus", fallback: "Status")) { db in
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
            ToolbarItemGroup(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    if let database = selectedDatabase, database.unbindArguments != nil {
                        Button(role: .destructive) {
                            Task { await viewModel.unbind(database, confirmed: false) }
                        } label: {
                            Label(translations.get("databaseRemoteUnbindAction", fallback: "Unbind"), systemImage: "link.badge.minus")
                        }
                    }
                    Button { viewModel.fetchDatabases() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .alert(
            translations.get("databaseRemoteUnbindAction", fallback: "Unbind"),
            isPresented: Binding(
                get: { viewModel.databaseToUnbind != nil },
                set: { if !$0 { viewModel.databaseToUnbind = nil } }
            ),
            presenting: viewModel.databaseToUnbind
        ) { database in
            Button(translations.get("databaseRemoteUnbindAction", fallback: "Unbind"), role: .destructive) {
                Task { await viewModel.unbind(database, confirmed: true) }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { database in
            Text(database.name + "\n" + translations.get("databaseRemoteUnbindMessage", fallback: "Remove this connection from the panel. The database and its backups are preserved."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchDatabases() }
        .sheet(item: $detailDatabase) { database in
            DatabaseDetailView(database: database)
                .frame(minWidth: 720, minHeight: 580)
                .id(database.id)
        }
    }
}
