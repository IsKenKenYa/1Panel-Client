import SwiftUI
import AppleSharedUI

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
            if viewModel.isLoading && viewModel.servers.isEmpty {
                LoadingView()
            } else if viewModel.servers.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    message: translations.get("serverListEmptyTitle", fallback: "No servers found")
                )
            } else {
                List {
                    ForEach(viewModel.servers) { server in
                        row(server)
                    }
                }
                .listStyle(.inset)
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
                Button {
                    editingServer = nil
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .help(translations.get("addServer", fallback: "Add Server"))
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            editingServer = nil
        }) {
            AddServerSheet(viewModel: viewModel, editingServer: editingServer)
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

    /// 每行只承载名称、地址与状态，按 HIG 用列表行表达运维对象；
    /// 操作直接做成行内可见按钮，右键菜单保留作补充。
    private func row(_ server: ServerModel) -> some View {
        HStack(spacing: 12) {
            Image(systemName: server.isCurrent ? "checkmark.circle.fill" : "server.rack")
                .foregroundStyle(server.isCurrent ? Color.green : Color.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(server.name)
                        .font(.subheadline.weight(server.isCurrent ? .semibold : .regular))
                    if server.isCurrent {
                        Text(translations.get("serverOnline", fallback: "Connected"))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.14), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
                Text(server.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 12)
            HStack(spacing: 4) {
                if !server.isCurrent {
                    rowAction(
                        title: translations.get("connect", fallback: "Connect"),
                        systemImage: "link",
                        destructive: false
                    ) {
                        Task { await viewModel.connectServer(id: server.originalId) }
                    }
                }
                rowAction(
                    title: translations.get("commonEdit", fallback: "Edit"),
                    systemImage: "pencil",
                    destructive: false
                ) {
                    editingServer = server
                    showAddSheet = true
                }
                rowAction(
                    title: translations.get("commonDelete", fallback: "Delete"),
                    systemImage: "trash",
                    destructive: true
                ) {
                    serverToDelete = server
                    showDeleteConfirm = true
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            editingServer = server
            showAddSheet = true
        }
        .contextMenu {
            Button {
                Task { await viewModel.connectServer(id: server.originalId) }
            } label: {
                Label(translations.get("connect", fallback: "Connect"),
                      systemImage: "link")
            }
            Button {
                editingServer = server
                showAddSheet = true
            } label: {
                Label(translations.get("commonEdit", fallback: "Edit"),
                      systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                serverToDelete = server
                showDeleteConfirm = true
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
        }
    }

    private func rowAction(
        title: String,
        systemImage: String,
        destructive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
                .font(.system(size: 12, weight: .medium))
                .frame(width: 26, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(destructive ? Color.red : Color.secondary)
        .help(title)
    }
}

// ── Add Server Sheet ──────────────────────────────────────────────────────────

struct AddServerSheet: View {
    let viewModel: ServersViewModel
    /// 非空表示编辑模式（预填名称/地址，API Key 留空沿用原值）。
    let editingServer: ServerModel?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var name: String
    @State private var url: String
    @State private var token = ""
    @State private var submission = NativeFormSubmission.idle

    init(viewModel: ServersViewModel, editingServer: ServerModel?) {
        self.viewModel = viewModel
        self.editingServer = editingServer
        // 仅在打开表单时预填，后续输入由表单管理。
        _name = State(initialValue: editingServer?.name ?? "")
        _url = State(initialValue: editingServer?.url ?? "")
    }

    private var isEditing: Bool { editingServer != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedURL: String { url.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedToken: String { token.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSubmit: Bool {
        !trimmedName.isEmpty && !trimmedURL.isEmpty &&
            (editingServer?.url == trimmedURL || !trimmedToken.isEmpty)
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
            .disabled(submission.isSubmitting)

            NativeFormSubmissionFeedback(
                submission: submission,
                errorFallback: translations.get("commonSaveFailed", fallback: "Failed to save")
            )

            HStack {
                Spacer()
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .disabled(submission.isSubmitting)
                Button(isEditing
                    ? translations.get("commonSave", fallback: "Save")
                    : translations.get("commonAdd", fallback: "Add"), action: submit)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit || submission.isSubmitting)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
        .interactiveDismissDisabled(submission.isSubmitting)
    }

    private func submit() {
        guard canSubmit, submission.begin() else { return }
        let name = trimmedName
        let url = trimmedURL
        let token = trimmedToken
        Task {
            let outcome: NativeMutationOutcome
            if let editingServer {
                outcome = await viewModel.updateServer(server: editingServer, name: name, url: url, token: token)
            } else {
                outcome = await viewModel.addServer(name: name, url: url, token: token)
            }
            if submission.finish(outcome) {
                dismiss()
            }
        }
    }
}
