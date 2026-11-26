import SwiftUI
import AppleSharedUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var editorTarget: ServerEditorTarget?
    @State private var serverToDelete: ServerModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.servers.isEmpty {
                LoadingView()
            } else if let error = viewModel.errorMessage, viewModel.servers.isEmpty {
                ErrorView(message: error) {
                    viewModel.fetchServers()
                }
            } else if viewModel.servers.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    message: translations.get("serverListEmptyTitle", fallback: "No servers found"),
                    description: translations.get("serverListEmptyDesc",
                                                  fallback: "Add a 1Panel server to get started.")
                ) {
                    Button {
                        editorTarget = ServerEditorTarget(server: nil)
                    } label: {
                        Label(translations.get("addServer", fallback: "Add Server"),
                              systemImage: "plus")
                    }
                    .controlSize(.large)
                    .prominentActionButton()
                }
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
                    editorTarget = ServerEditorTarget(server: nil)
                } label: {
                    Image(systemName: "plus")
                }
                .help(translations.get("addServer", fallback: "Add Server"))
            }
        }
        .sheet(item: $editorTarget) { target in
            AddServerSheet(viewModel: viewModel, editingServer: target.server)
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
        // 列表为空时错误由失败占位呈现，弹窗只负责已有列表上的操作失败。
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.servers.isEmpty },
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

    /// 资源占用只在有数值时显示；缺失时给出占位文案。
    ///
    /// 列表按可达性着色：当前连接用主色强调，其余服务器用次要色，
    /// 进入提示与危险区间后由 `GaugePalette` 统一改为橙与红。
    @ViewBuilder
    private func metrics(_ server: ServerModel) -> some View {
        if let cpu = server.cpu, let memory = server.memory {
            HStack(spacing: 14) {
                Label(String(format: "%.1f%%", cpu), systemImage: "cpu")
                Label(String(format: "%.1f%%", memory), systemImage: "memorychip")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        } else {
            Text(translations.get("serverMetricsUnavailable", fallback: "Metrics unavailable"))
                .font(.caption2)
                .foregroundStyle(.secondary)
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
                        StatusBadge(
                            text: translations.get("serverOnline", fallback: "Connected"),
                            color: .green
                        )
                    }
                }
                Text(server.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                metrics(server)
            }
            Spacer(minLength: 12)
            RowActionsMenu {
                if !server.isCurrent {
                    Button {
                        Task { await viewModel.connectServer(id: server.originalId) }
                    } label: {
                        Label(translations.get("connect", fallback: "Connect"),
                              systemImage: "link")
                    }
                }
                Button {
                    editorTarget = ServerEditorTarget(server: server)
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
            .disabled(viewModel.isProcessing)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            editorTarget = ServerEditorTarget(server: server)
        }
        .contextMenu {
            Button {
                Task { await viewModel.connectServer(id: server.originalId) }
            } label: {
                Label(translations.get("connect", fallback: "Connect"),
                      systemImage: "link")
            }
            Button {
                editorTarget = ServerEditorTarget(server: server)
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
}

/// 服务器表单的打开目标。`server` 为空表示创建，非空表示编辑。
///
/// 用 `.sheet(item:)` 绑定这个目标，表单内容由目标里的服务器唯一确定；
/// 先改选中项再切布尔值的写法会在动画或快速点击时读到空选中项，
/// 编辑请求会退化成创建表单。
struct ServerEditorTarget: Identifiable {
    let id = UUID()
    let server: ServerModel?
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
    @State private var tokenValidity: String
    @State private var allowInsecureTls: Bool
    @State private var submission = NativeFormSubmission.idle

    init(viewModel: ServersViewModel, editingServer: ServerModel?) {
        self.viewModel = viewModel
        self.editingServer = editingServer
        // 仅在打开表单时预填，后续输入由表单管理。
        _name = State(initialValue: editingServer?.name ?? "")
        _url = State(initialValue: editingServer?.url ?? "")
        _tokenValidity = State(
            initialValue: String(editingServer?.tokenValidity ?? 0)
        )
        _allowInsecureTls = State(
            initialValue: editingServer?.allowInsecureTls ?? false
        )
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
                Section {
                    TextField(translations.get("serverFormName", fallback: "Name"),
                              text: $name)
                    TextField(
                        translations.get("serverFormUrl",
                                         fallback: "URL (https://host:port)"),
                        text: $url
                    )
                    .autocorrectionDisabled()
                    SecureField(translations.get("serverFormApiKey", fallback: "API key"),
                                text: $token)
                } footer: {
                    if isEditing, editingServer?.url == trimmedURL {
                        Text(translations.get("serverFormApiKeyKeepHint",
                                              fallback: "Leave empty to keep the saved key."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    TextField(
                        translations.get("serverTokenValidity",
                                         fallback: "Token validity (minutes)"),
                        text: $tokenValidity
                    )
                    Toggle(
                        translations.get("serverFormAllowInsecureTls",
                                         fallback: "Ignore TLS certificate validation"),
                        isOn: $allowInsecureTls
                    )
                } footer: {
                    Text(translations.get("serverTokenValidityHint",
                                          fallback: "Set to 0 to skip timestamp validation"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
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
                .prominentActionButton()
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
        let validity = Int(tokenValidity.trimmingCharacters(in: .whitespaces)) ?? 0
        let insecureTls = allowInsecureTls
        Task {
            let outcome: NativeMutationOutcome
            if let editingServer {
                outcome = await viewModel.updateServer(
                    server: editingServer,
                    name: name,
                    url: url,
                    token: token,
                    tokenValidity: validity,
                    allowInsecureTls: insecureTls
                )
            } else {
                outcome = await viewModel.addServer(
                    name: name,
                    url: url,
                    token: token,
                    tokenValidity: validity,
                    allowInsecureTls: insecureTls
                )
            }
            if submission.finish(outcome) {
                dismiss()
            }
        }
    }
}
