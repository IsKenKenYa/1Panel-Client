import SwiftUI

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var appToUninstall: AppModel?
    @State private var showUninstallConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.apps.isEmpty {
                EmptyStateView(
                    icon: "app.badge",
                    message: translations.get("appsListEmptyTitle", fallback: "No apps found")
                )
            } else {
                Table(viewModel.apps) {
                    TableColumn(translations.get("commonName", fallback: "Name")) { app in
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.blue)
                            Text(app.name)
                        }
                        .contextMenu {
                            let isRunning = app.status.lowercased() == "running"
                            Button {
                                Task { await viewModel.toggleAppStatus(id: app.originalId, currentStatus: app.status) }
                            } label: {
                                Label(
                                    isRunning ? translations.get("commonStop", fallback: "Stop") : translations.get("commonStart", fallback: "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            Divider()
                            Button(role: .destructive) {
                                appToUninstall = app
                                showUninstallConfirm = true
                            } label: {
                                Label(translations.get("appActionUninstall", fallback: "Uninstall"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("appInfoVersion", fallback: "Version")) { app in
                        Text(app.version.isEmpty ? "--" : app.version)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("appInfoStatus", fallback: "Status")) { app in
                        let isRunning = app.status.lowercased() == "running"
                        Text(app.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isRunning ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                            .foregroundColor(isRunning ? .green : .gray)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleApps", fallback: "Apps"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchApps() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("uninstallConfirm", fallback: "Uninstall \"\(appToUninstall?.name ?? "")\"?"),
            isPresented: $showUninstallConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("appActionUninstall", fallback: "Uninstall"), role: .destructive) {
                if let a = appToUninstall { Task { await viewModel.uninstallApp(id: a.originalId) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("uninstallCannotUndo", fallback: "This will remove the app and its data. This action cannot be undone."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchApps() }
    }
}
