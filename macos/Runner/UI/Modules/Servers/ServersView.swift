import SwiftUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.servers.isEmpty {
                Text("No servers found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.servers) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { server in
                        Text(server.name)
                            .contextMenu {
                                Button(action: {
                                    Task {
                                        await viewModel.connectServer(id: server.originalId)
                                    }
                                }) {
                                    Text(translations.get("connect", fallback: "Connect"))
                                    Image(systemName: "link")
                                }
                                Divider()
                                Button(action: {
                                    Task {
                                        await viewModel.deleteServer(id: server.originalId)
                                    }
                                }) {
                                    Text(translations.get("delete", fallback: "Delete"))
                                    Image(systemName: "trash")
                                }
                            }
                    }
                    TableColumn(translations.get("server_url", fallback: "URL")) { server in
                        Text(server.url)
                    }
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.disabled)
            }
        }
        .navigationTitle(translations.get("navServer", fallback: "Servers"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchServers()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchServers()
        }
    }
}
