import SwiftUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var showAddSheet = false
    @State private var editingServer: ServerModel?
    @State private var serverToDelete: ServerModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.servers.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    message: translations.get("serverListEmptyTitle", fallback: "No servers found")
                )
            } else {
                Table(viewModel.servers) {
                    TableColumn(translations.get("commonName", fallback: "Name")) { server in
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
                            Button {
                                editingServer = server
                                showAddSheet = true
                            } label: {
                                Label(translations.get("commonEdit", fallback: "Edit"), systemImage: "pencil")
                            }
                            Divider()
                            Button(role: .destructive) {
                                serverToDelete = server
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("serverFormUrl", fallback: "URL")) { server in
                        Text(server.url)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    TableColumn(translations.get("appInfoStatus", fallback: "Status")) { server in
                        if server.isCurrent {
                            Text(translations.get("serverOnline", fallback: "Connected"))
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
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
            ToolbarItem(placement: .automatic) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
                .help(translations.get("addServer", fallback: "Add Server"))
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            editingServer = nil
        }) {
            AddServerSheet(isPresented: $showAddSheet, editingServer: editingServer) { name, url, token in
                Task {
                    if let editing = editingServer {
                        await viewModel.updateServer(
                            id: editing.originalId,
                            name: name,
                            url: url,
                            token: token
                        )
                    } else {
                        await viewModel.addServer(name: name, url: url, token: token)
                    }
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete \"\(serverToDelete?.name ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let s = serverToDelete {
                    Task { await viewModel.deleteServer(id: s.originalId) }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
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
    /// 非空表示编辑模式（预填名称/地址，API Key 留空沿用原值）。
    var editingServer: ServerModel? = nil
    let onAdd: (String, String, String) -> Void
    @EnvironmentObject var translations: TranslationsManager

    @State private var name = ""
    @State private var url = ""
    @State private var token = ""
    @State private var didPrefill = false

    private var isEditing: Bool { editingServer != nil }

    private var canSubmit: Bool {
        !name.isEmpty && !url.isEmpty && (isEditing || !token.isEmpty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isEditing
                ? translations.get("commonEdit", fallback: "Edit")
                : translations.get("addServer", fallback: "Add Server"))
                .font(.title2)
                .fontWeight(.semibold)

            Form {
                TextField(translations.get("serverFormName", fallback: "Name"), text: $name)
                TextField(translations.get("serverFormUrl", fallback: "URL (https://host:port)"), text: $url)
                    .autocorrectionDisabled()
                SecureField(translations.get("serverFormApiKey", fallback: "API Token"), text: $token)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing
                    ? translations.get("commonSave", fallback: "Save")
                    : translations.get("commonAdd", fallback: "Add")) {
                    onAdd(name, url, token)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            guard !didPrefill, let server = editingServer else { return }
            didPrefill = true
            name = server.name
            url = server.url
        }
    }
}
