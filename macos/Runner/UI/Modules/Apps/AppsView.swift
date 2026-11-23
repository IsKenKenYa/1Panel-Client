import SwiftUI
import AppleSharedUI

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var appToUninstall: AppModel?
    @State private var showUninstallConfirm = false
    @State private var showAppStore = false

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
                List {
                    ForEach(viewModel.apps) { app in
                        row(app)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(translations.get("serverModuleApps", fallback: "Apps"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showAppStore = true
                } label: {
                    Label(translations.get("appStoreTitle", fallback: "App Store"),
                          systemImage: "bag")
                }
                .help(translations.get("appStoreTitle", fallback: "App Store"))
            }
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { Task { await viewModel.fetchApps() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("uninstallConfirm", fallback: "Confirm Uninstall"),
            isPresented: $showUninstallConfirm,
            titleVisibility: .visible,
            presenting: appToUninstall
        ) { app in
            Button(translations.get("appActionUninstall", fallback: "Uninstall"), role: .destructive) {
                Task { await viewModel.uninstallApp(installId: app.installId) }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: { app in
            Text("\(app.name)\n\(translations.get("uninstallCannotUndo", fallback: "This action cannot be undone."))")
        }
        .sheet(isPresented: $showAppStore) {
            AppStoreSheet {
                Task { await viewModel.fetchApps() }
            }
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task { await viewModel.fetchApps() }
    }

    private func row(_ app: AppModel) -> some View {
        ModuleRow(
            icon: "app.badge",
            iconColor: .blue,
            title: app.name,
            subtitle: app.version.isEmpty ? "--" : app.version,
            badge: (app.status.isEmpty ? "--" : app.status,
                    app.isRunning ? .green : .gray)
        ) {
            RowActions {
                RowActionButton(
                    title: app.isRunning
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: app.isRunning ? "stop.fill" : "play.fill"
                ) {
                    Task { await viewModel.toggleAppStatus(app) }
                }
                RowActionButton(
                    title: translations.get("appActionUninstall", fallback: "Uninstall"),
                    systemImage: "trash",
                    destructive: true
                ) {
                    appToUninstall = app
                    showUninstallConfirm = true
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .contextMenu {
            Button {
                Task { await viewModel.toggleAppStatus(app) }
            } label: {
                Label(
                    app.isRunning
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: app.isRunning ? "stop.fill" : "play.fill"
                )
            }
            .disabled(viewModel.isProcessing)
            Divider()
            Button(role: .destructive) {
                appToUninstall = app
                showUninstallConfirm = true
            } label: {
                Label(translations.get("appActionUninstall", fallback: "Uninstall"),
                      systemImage: "trash")
            }
            .disabled(viewModel.isProcessing)
        }
    }
}
