import SwiftUI

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.apps.isEmpty {
                Text("No apps found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.apps) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { app in
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.blue)
                            Text(app.name)
                        }
                        .contextMenu {
                            let isRunning = app.status.lowercased() == "running"
                            Button(action: {
                                Task {
                                    await viewModel.toggleAppStatus(id: app.originalId, currentStatus: app.status)
                                }
                            }) {
                                Text(isRunning ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"))
                                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            }
                            Divider()
                            Button(action: {
                                Task {
                                    await viewModel.uninstallApp(id: app.originalId)
                                }
                            }) {
                                Text(translations.get("uninstall", fallback: "Uninstall"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("app_version", fallback: "Version")) { app in
                        Text(app.version)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { app in
                        Text(app.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.disabled)
            }
        }
        .navigationTitle(translations.get("serverModuleApps", fallback: "Apps"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchApps()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchApps()
        }
    }
}
