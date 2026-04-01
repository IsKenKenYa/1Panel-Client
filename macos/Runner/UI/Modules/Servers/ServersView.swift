import SwiftUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var showAddSheet = false
    @State private var serverToDelete: ServerModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.servers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(translations.get("noServersFound", fallback: "No servers found"))
                        .foregroundColor(.secondary)
                    Button(translations.get("addServer", fallback: "Add Server")) {
                        showAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.servers) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { server in
                        HStack(spacing: 6) {
                            if server.isCurrent {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                            Text(server.name)
                                .fontWeight(server.isCurrent ? .semibold : .regular)
                        }
                        .contextMenu {
                            Button {
                                Task { await viewModel.connectServer(id: server.originalId) }
                            } label: {
                                Label(translations.get("connect", fallback: "Connect"), systemImage: "link")
                            }
                            Divider()
                            Button(role: .destructive) {
                                serverToDelete = server
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("server_url", fallback: "URL")) { server in
                        Text(server.url)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn("Status") { server in
                        if server.isCurrent {
                            Text("Connected")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("navServer", fallback: "Servers"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchServers() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help("Add Server")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddServerSheet(isPresented: $showAddSheet) { name, url, token in
                Task {
                    await viewModel.addServer(name: name, url: url, token: token)
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(serverToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let s = serverToDelete {
                    Task { await viewModel.deleteServer(id: s.originalId) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.fetchServers()
        }
    }
}

// ── Add Server Sheet ──────────────────────────────────────────────────────────

struct AddServerSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String, String, String) -> Void

    @State private var name = ""
    @State private var url = ""
    @State private var token = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Add Server")
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField("Name", text: $name)
                TextField("URL (https://host:port)", text: $url)
                    .autocorrectionDisabled()
                SecureField("API Token", text: $token)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Add") {
                    onAdd(name, url, token)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || url.isEmpty || token.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
}
