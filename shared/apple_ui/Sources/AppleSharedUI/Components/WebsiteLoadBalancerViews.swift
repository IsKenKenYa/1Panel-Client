import SwiftUI

/// 网站负载均衡列表：查看、新建、编辑与删除，iOS 与 macOS 共用。
public struct WebsiteLoadBalancerListView: View {
    @StateObject private var store: WebsiteLoadBalancerStore
    @Environment(\.translationsProvider) private var translations

    @State private var editorTarget: EditorTarget?
    @State private var fileTarget: FileTarget?
    @State private var pendingDelete: WebsiteLoadBalancer?
    @State private var actionError: String?
    @State private var statusMessage: String?

    public init(channel: any DataChannel, websiteID: Int) {
        _store = StateObject(
            wrappedValue: WebsiteLoadBalancerStore(
                channel: channel,
                websiteID: websiteID
            )
        )
    }

    public var body: some View {
        Group {
            if store.isLoading && store.items.isEmpty {
                LoadingView()
            } else if let loadError = store.loadError, store.items.isEmpty {
                ErrorView(message: loadError) {
                    Task { await store.load() }
                }
            } else if store.items.isEmpty {
                EmptyStateView(
                    icon: "arrow.triangle.branch",
                    message: t("websitesLoadBalanceEmpty", "No load balancers")
                )
            } else {
                loadBalancerList
            }
        }
        .overlay(alignment: .bottom) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 10)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await store.load() }
                } label: {
                    Label(t("commonRefresh", "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                Button {
                    editorTarget = EditorTarget(balancer: nil)
                } label: {
                    Label(t("commonAdd", "Add"), systemImage: "plus")
                }
            }
        }
        .sheet(item: $editorTarget) { target in
            WebsiteLoadBalancerFormView(
                store: store,
                editing: target.balancer
            )
        }
        .sheet(item: $fileTarget) { target in
            WebsiteLoadBalancerFileView(
                store: store,
                balancer: target.balancer
            )
        }
        .confirmationDialog(
            t("deleteConfirmTitle", "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(t("commonDelete", "Delete"), role: .destructive) {
                deleteSelected()
            }
            Button(t("commonCancel", "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(t("deleteCannotUndoMessage",
                   "This action cannot be undone."))
        }
        .alert(
            t("commonError", "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(t("commonOk", "OK"), role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            if store.items.isEmpty {
                await store.load()
            }
        }
    }

    @ViewBuilder
    private var loadBalancerList: some View {
        #if os(macOS)
        List { listRows }
            .listStyle(.inset)
            .refreshable { await store.load() }
        #else
        List { listRows }
            .listStyle(.insetGrouped)
            .refreshable { await store.load() }
        #endif
    }

    private var listRows: some View {
        ForEach(store.items) { balancer in
            row(balancer)
        }
    }

    private func row(_ balancer: WebsiteLoadBalancer) -> some View {
        Button {
            editorTarget = EditorTarget(balancer: balancer)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(balancer.name)
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text(algorithmTitle(balancer.algorithm))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if balancer.servers.isEmpty {
                    Text(t("websitesLoadBalanceEmpty",
                           "No load balancers"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(balancer.servers.enumerated()), id: \.offset) { _, server in
                        Text(server.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editorTarget = EditorTarget(balancer: balancer)
            } label: {
                Label(t("commonEdit", "Edit"), systemImage: "pencil")
            }
            Button {
                fileTarget = FileTarget(balancer: balancer)
            } label: {
                Label(t("websiteSourceFileLabel", "Source file"),
                      systemImage: "doc.text")
            }
            Button(role: .destructive) {
                pendingDelete = balancer
            } label: {
                Label(t("commonDelete", "Delete"), systemImage: "trash")
            }
        }
        #if os(iOS)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                fileTarget = FileTarget(balancer: balancer)
            } label: {
                Label(t("websiteSourceFileLabel", "Source file"),
                      systemImage: "doc.text")
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                pendingDelete = balancer
            } label: {
                Label(t("commonDelete", "Delete"), systemImage: "trash")
            }
        }
        #endif
    }

    private func deleteSelected() {
        guard let balancer = pendingDelete else { return }
        pendingDelete = nil
        Task {
            do {
                try await store.delete(name: balancer.name)
                showStatus(t("commonDeleted", "Deleted"))
            } catch {
                actionError = error.localizedDescription
            }
        }
    }

    private func algorithmTitle(_ value: String) -> String {
        WebsiteLoadBalancerAlgorithm(rawValue: value)?.title(translations)
            ?? value
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if statusMessage == text { statusMessage = nil }
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

private struct EditorTarget: Identifiable {
    let id = UUID()
    let balancer: WebsiteLoadBalancer?
}

private struct FileTarget: Identifiable {
    let id = UUID()
    let balancer: WebsiteLoadBalancer
}

/// 负载均衡源文件编辑：展示 server 端读取到的 nginx upstream 配置并可保存。
public struct WebsiteLoadBalancerFileView: View {
    @ObservedObject private var store: WebsiteLoadBalancerStore
    private let balancer: WebsiteLoadBalancer

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var content = ""
    @State private var originalContent = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(
        store: WebsiteLoadBalancerStore,
        balancer: WebsiteLoadBalancer
    ) {
        self.store = store
        self.balancer = balancer
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if isLoading {
                    LoadingView()
                } else {
                    TextEditor(text: $content)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
            }
            .navigationTitle(balancer.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await save() }
                    }
                    .disabled(isLoading || isSaving || content == originalContent)
                }
            }
            #if os(macOS)
            .frame(width: 720, height: 560)
            #endif
            .onAppear {
                content = balancer.content
                originalContent = balancer.content
                isLoading = false
                if balancer.content.isEmpty {
                    errorMessage = t("websitesLoadBalanceFileEmpty",
                                     "The source file is empty or could not be read.")
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        do {
            try await store.updateFile(name: balancer.name, content: content)
            originalContent = content
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

/// 负载均衡编辑表单：名称、算法与上游服务器参数。
public struct WebsiteLoadBalancerFormView: View {
    @ObservedObject private var store: WebsiteLoadBalancerStore
    private let editing: WebsiteLoadBalancer?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var name = ""
    @State private var algorithm = WebsiteLoadBalancerAlgorithm.standard.rawValue
    @State private var servers: [ServerDraft] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(
        store: WebsiteLoadBalancerStore,
        editing: WebsiteLoadBalancer?
    ) {
        self.store = store
        self.editing = editing
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(t("commonName", "Name"), text: $name)
                        .disabled(editing != nil)
                    Picker(t("websitesLoadBalanceAlgorithmLabel", "Algorithm"),
                           selection: $algorithm) {
                        ForEach(WebsiteLoadBalancerAlgorithm.allCases) { item in
                            Text(item.title(translations)).tag(item.rawValue)
                        }
                    }
                }
                ForEach($servers) { $draft in
                    Section {
                        serverFields($draft)
                    } header: {
                        HStack {
                            Text(draft.server.trimmingCharacters(in: .whitespaces).isEmpty
                                 ? "\(t("websitesLoadBalanceServerLabel", "Server address")) \(serverIndex(draft) + 1)"
                                 : draft.server)
                            Spacer()
                            if servers.count > 1 {
                                Button(role: .destructive) {
                                    removeServer(draft.id)
                                } label: {
                                    Label(t("websitesLoadBalanceRemoveServer",
                                            "Remove server"),
                                          systemImage: "minus.circle")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                Section {
                    Button {
                        servers.append(ServerDraft())
                    } label: {
                        Label(t("websitesLoadBalanceAddServer", "Add server"),
                              systemImage: "plus.circle")
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(editing == nil
                ? t("websitesLoadBalanceCreateTitle", "New Load Balancer")
                : t("websitesLoadBalanceEditTitle", "Edit Load Balancer"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving)
                }
            }
            #if os(macOS)
            .frame(width: 680, height: 680)
            #endif
            .onAppear {
                populate()
            }
        }
    }

    @ViewBuilder
    private func serverFields(_ draft: Binding<ServerDraft>) -> some View {
        TextField(t("websitesLoadBalanceServerLabel", "Server address"),
                  text: draft.server)
        HStack {
            TextField(t("websitesLoadBalanceWeightLabel", "Weight"),
                      text: draft.weight)
            Picker(t("websitesLoadBalanceFlagLabel", "Status strategy"),
                   selection: draft.flag) {
                ForEach(WebsiteLoadBalancerFlag.allCases) { flag in
                    Text(flag.title(translations)).tag(flag.rawValue)
                }
            }
            .labelsHidden()
        }
        TextField(t("websitesLoadBalanceMaxFailsLabel", "Max fails"),
                  text: draft.maxFails)
        HStack {
            TextField(t("websitesLoadBalanceFailTimeoutLabel", "Fail timeout"),
                      text: draft.failTimeout)
            Picker("", selection: draft.failTimeoutUnit) {
                ForEach(Self.timeUnits, id: \.self) { unit in
                    Text(unit).tag(unit)
                }
            }
            .labelsHidden()
            .frame(width: 70)
        }
        TextField(t("websitesLoadBalanceMaxConnsLabel", "Max connections"),
                  text: draft.maxConns)
    }

    private static let timeUnits = ["s", "m", "h", "d", "w", "M", "y"]

    private func serverIndex(_ draft: ServerDraft) -> Int {
        servers.firstIndex(where: { $0.id == draft.id }) ?? 0
    }

    private func removeServer(_ id: UUID) {
        servers.removeAll { $0.id == id }
    }

    private func populate() {
        if let editing {
            name = editing.name
            algorithm = editing.algorithm
            servers = editing.servers.map(ServerDraft.init(server:))
        } else if servers.isEmpty {
            servers = [ServerDraft()]
        }
    }

    private func submit() async {
        guard let balancer = buildBalancer() else { return }
        isSaving = true
        do {
            if editing == nil {
                try await store.create(balancer)
            } else {
                try await store.update(balancer)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func buildBalancer() -> WebsiteLoadBalancer? {
        var built: [WebsiteLoadBalancerServer] = []
        for draft in servers {
            let address = draft.server.trimmingCharacters(in: .whitespaces)
            guard let weight = parseOptional(
                draft.weight,
                range: WebsiteLoadBalancerValidator.weightRange,
                issue: .invalidWeight
            ) else { return nil }
            guard let maxFails = parseOptional(
                draft.maxFails,
                range: WebsiteLoadBalancerValidator.maxFailsRange,
                issue: .invalidMaxFails
            ) else { return nil }
            guard let maxConns = parseOptional(
                draft.maxConns,
                range: WebsiteLoadBalancerValidator.maxConnsRange,
                issue: .invalidMaxConns
            ) else { return nil }
            guard let failTimeout = parseOptional(
                draft.failTimeout,
                range: WebsiteLoadBalancerValidator.failTimeoutRange,
                issue: .invalidFailTimeout
            ) else { return nil }
            built.append(
                WebsiteLoadBalancerServer(
                    server: address,
                    weight: weight,
                    flag: draft.flag,
                    maxFails: maxFails,
                    maxConns: maxConns,
                    failTimeout: failTimeout,
                    failTimeoutUnit: draft.failTimeoutUnit
                )
            )
        }
        let balancer = WebsiteLoadBalancer(
            name: name.trimmingCharacters(in: .whitespaces),
            algorithm: algorithm,
            servers: built
        )
        if let issue = WebsiteLoadBalancerValidator.validate(
            name: balancer.name,
            algorithm: balancer.algorithm,
            servers: balancer.servers
        ) {
            errorMessage = issueMessage(issue)
            return nil
        }
        return balancer
    }

    /// 空文本解析为 nil，非法或越界值时记录错误并返回 nil。
    private func parseOptional(
        _ text: String,
        range: ClosedRange<Int>,
        issue: WebsiteLoadBalancerValidationIssue
    ) -> Int?? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { return .some(nil) }
        guard let value = Int(trimmed), range.contains(value) else {
            errorMessage = issueMessage(issue)
            return nil
        }
        return .some(value)
    }

    private func issueMessage(
        _ issue: WebsiteLoadBalancerValidationIssue
    ) -> String {
        switch issue {
        case .nameRequired:
            return t("websitesLoadBalanceNameRequired", "Enter a name.")
        case .algorithmRequired:
            return t("websitesLoadBalanceAlgorithmRequired",
                     "Select an algorithm.")
        case .serversRequired:
            return t("websitesLoadBalanceServersRequired",
                     "Add at least one server.")
        case .serverRequired:
            return t("websitesLoadBalanceServerRequired",
                     "Enter a server address.")
        case .duplicateServer:
            return t("websitesLoadBalanceDuplicateServer",
                     "Server addresses must be unique.")
        case .invalidWeight:
            return t("websitesLoadBalanceWeightRange",
                     "Weight must be between 0 and 100.")
        case .invalidMaxFails:
            return t("websitesLoadBalanceMaxFailsRange",
                     "Max fails must be between 0 and 1000.")
        case .invalidMaxConns:
            return t("websitesLoadBalanceMaxConnsRange",
                     "Max connections must be between 0 and 10000.")
        case .invalidFailTimeout:
            return t("websitesLoadBalanceFailTimeoutRange",
                     "Fail timeout must be between 0 and 300.")
        case .ipHashBackup:
            return t("websitesLoadBalanceIpHashBackup",
                     "IP hash does not support backup servers.")
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}

private struct ServerDraft: Identifiable {
    let id = UUID()
    var server = ""
    var weight = ""
    var flag = WebsiteLoadBalancerFlag.none.rawValue
    var maxFails = ""
    var failTimeout = ""
    var failTimeoutUnit = "s"
    var maxConns = ""

    init() {}

    init(server: WebsiteLoadBalancerServer) {
        self.server = server.server
        weight = server.weight.map(String.init) ?? ""
        flag = server.flag
        maxFails = server.maxFails.map(String.init) ?? ""
        failTimeout = server.failTimeout.map(String.init) ?? ""
        failTimeoutUnit = server.failTimeoutUnit
        maxConns = server.maxConns.map(String.init) ?? ""
    }
}

extension WebsiteLoadBalancerAlgorithm {
    public func title(_ translations: (any TranslationsProviding)?) -> String {
        let fallback: String
        switch self {
        case .standard: fallback = "Default"
        case .ipHash: fallback = "IP hash"
        case .leastConn: fallback = "Least connections"
        }
        let key: String
        switch self {
        case .standard: key = "websitesLoadBalanceAlgorithmDefault"
        case .ipHash: key = "websitesLoadBalanceAlgorithmIpHash"
        case .leastConn: key = "websitesLoadBalanceAlgorithmLeastConn"
        }
        return translations?.get(key, fallback: fallback) ?? fallback
    }
}

extension WebsiteLoadBalancerFlag {
    public func title(_ translations: (any TranslationsProviding)?) -> String {
        let fallback: String
        switch self {
        case .none: fallback = "Normal"
        case .down: fallback = "Down"
        case .backup: fallback = "Backup"
        }
        let key: String
        switch self {
        case .none: key = "websitesLoadBalanceFlagNone"
        case .down: key = "websitesLoadBalanceFlagDown"
        case .backup: key = "websitesLoadBalanceFlagBackup"
        }
        return translations?.get(key, fallback: fallback) ?? fallback
    }
}