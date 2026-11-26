import AppleSharedUI
import SwiftUI

struct WebsiteRootAuthRow: Identifiable {
    let username: String
    let remark: String

    var id: String { username }
}

struct WebsitePathAuthRow: Identifiable {
    let name: String
    let path: String
    let username: String
    let remark: String

    var id: String { name }
}

/// 网站 BasicAuth：根目录用户与路径认证。
struct WebsiteAuthSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var enabled = false
    @State private var rootUsers: [WebsiteRootAuthRow] = []
    @State private var pathRules: [WebsitePathAuthRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    @State private var rootEditor: WebsiteRootAuthEditor?
    @State private var pathEditor: WebsitePathAuthEditor?
    @State private var pendingRoot: WebsiteRootAuthRow?
    @State private var pendingPath: WebsitePathAuthRow?

    var body: some View {
        List {
            Section {
                Toggle(translations.get("hostAuthEnable", fallback: "Enable password access"),
                       isOn: Binding(
                        get: { enabled },
                        set: { value in Task { await toggleEnable(value) } }
                       ))
            }

            Section(translations.get("hostAuthRootSectionTitle", fallback: "Root users")) {
                if rootUsers.isEmpty {
                    Text(translations.get("hostAuthEmpty", fallback: "No users"))
                        .foregroundStyle(.secondary)
                }
                ForEach(rootUsers) { user in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username).font(.subheadline.weight(.medium))
                            if !user.remark.isEmpty {
                                Text(user.remark)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button {
                            rootEditor = WebsiteRootAuthEditor(user: user)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        Button(role: .destructive) {
                            pendingRoot = user
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                }
                Button {
                    rootEditor = .blank
                } label: {
                    Label(translations.get("hostAuthAddUser", fallback: "Add user"),
                          systemImage: "person.badge.plus")
                }
            }

            Section(translations.get("hostAuthPathSectionTitle", fallback: "Path authentication")) {
                if pathRules.isEmpty {
                    Text(translations.get("hostAuthPathEmpty", fallback: "No path rules"))
                        .foregroundStyle(.secondary)
                }
                ForEach(pathRules) { rule in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.name).font(.subheadline.weight(.medium))
                            Text("\(rule.path) · \(rule.username)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            pathEditor = WebsitePathAuthEditor(rule: rule)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.borderless)
                        Button(role: .destructive) {
                            pendingPath = rule
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 2)
                }
                Button {
                    pathEditor = .blank
                } label: {
                    Label(translations.get("hostAuthAddPath", fallback: "Add path rule"),
                          systemImage: "folder.badge.plus")
                }
            }

            if isLoading {
                Section {
                    ProgressView().controlSize(.small)
                }
            }
        }
        .listStyle(.inset)
        .sheet(item: $rootEditor) { editor in
            WebsiteRootAuthFormView(websiteId: websiteId, editor: editor) {
                Task { await load() }
            }
        }
        .sheet(item: $pathEditor) { editor in
            WebsitePathAuthFormView(websiteId: websiteId, editor: editor) {
                Task { await load() }
            }
        }
        .confirmationDialog(
            translations.get("commonDelete", fallback: "Delete"),
            isPresented: Binding(
                get: { pendingRoot != nil },
                set: { if !$0 { pendingRoot = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let user = pendingRoot {
                    pendingRoot = nil
                    Task { await deleteRoot(user) }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingRoot = nil
            }
        } message: {
            Text(pendingRoot?.username ?? "")
        }
        .confirmationDialog(
            translations.get("commonDelete", fallback: "Delete"),
            isPresented: Binding(
                get: { pendingPath != nil },
                set: { if !$0 { pendingPath = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let rule = pendingPath {
                    pendingPath = nil
                    Task { await deletePath(rule) }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingPath = nil
            }
        } message: {
            Text(pendingPath?.name ?? "")
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .operationNotice(statusMessage)
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let rootRaw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteAuths",
                arguments: ["websiteID": websiteId]
            )
            let rootDict = rootRaw as? [String: Any] ?? [:]
            enabled = rootDict["enable"] as? Bool ?? false
            rootUsers = (rootDict["items"] as? [[String: Any]] ?? []).compactMap { item in
                guard let username = item["username"] as? String, !username.isEmpty else {
                    return nil
                }
                return WebsiteRootAuthRow(
                    username: username,
                    remark: item["remark"] as? String ?? ""
                )
            }
            let pathRaw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsitePathAuths",
                arguments: ["websiteID": websiteId]
            )
            pathRules = (pathRaw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                return WebsitePathAuthRow(
                    name: name,
                    path: item["path"] as? String ?? "",
                    username: item["username"] as? String ?? "",
                    remark: item["remark"] as? String ?? ""
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func toggleEnable(_ value: Bool) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteAuth",
                arguments: [
                    "websiteID": websiteId,
                    "operate": value ? "enable" : "disable",
                    "scope": "root",
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                enabled = value
                showStatus(translations.get("hostAuthSaved",
                                            fallback: "Password access updated"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostAuthEnableFailed", fallback: "Update failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteRoot(_ user: WebsiteRootAuthRow) async {
        await mutateAuth([
            "websiteID": websiteId,
            "operate": "delete",
            "scope": "root",
            "username": user.username,
        ])
    }

    private func deletePath(_ rule: WebsitePathAuthRow) async {
        await mutatePath([
            "websiteID": websiteId,
            "operate": "delete",
            "name": rule.name,
            "path": rule.path,
            "username": rule.username,
        ])
    }

    private func mutateAuth(_ arguments: [String: Any]) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteAuth",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostAuthSaveFailed", fallback: "Update failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mutatePath(_ arguments: [String: Any]) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsitePathAuth",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostAuthSaveFailed", fallback: "Update failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }
}

struct WebsiteRootAuthEditor: Identifiable {
    let id = UUID()
    let user: WebsiteRootAuthRow?

    static let blank = WebsiteRootAuthEditor(user: nil)
}

struct WebsitePathAuthEditor: Identifiable {
    let id = UUID()
    let rule: WebsitePathAuthRow?

    static let blank = WebsitePathAuthEditor(rule: nil)
}

struct WebsiteRootAuthFormView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let websiteId: Int
    let editor: WebsiteRootAuthEditor
    let onSaved: () -> Void

    @State private var username: String
    @State private var password = ""
    @State private var remark: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(websiteId: Int, editor: WebsiteRootAuthEditor, onSaved: @escaping () -> Void) {
        self.websiteId = websiteId
        self.editor = editor
        self.onSaved = onSaved
        _username = State(initialValue: editor.user?.username ?? "")
        _remark = State(initialValue: editor.user?.remark ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(translations.get("databaseUsernameLabel", fallback: "Username"),
                          text: $username)
                SecureField(translations.get("commonPassword", fallback: "Password"),
                            text: $password)
                TextField(translations.get("hostAuthRemark", fallback: "Remark"), text: $remark)
            }
            .formStyle(.grouped)
            .navigationTitle(editor.user == nil
                             ? translations.get("hostAuthAddUser", fallback: "Add user")
                             : translations.get("commonEdit", fallback: "Edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || username.trimmingCharacters(in: .whitespaces).isEmpty
                              || password.isEmpty)
                }
            }
            .alert(
                translations.get("commonError", fallback: "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .frame(minWidth: 440, minHeight: 280)
        }
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteAuth",
                arguments: [
                    "websiteID": websiteId,
                    "operate": editor.user == nil ? "create" : "edit",
                    "scope": "root",
                    "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
                    "password": password,
                    "remark": remark,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onSaved()
                dismiss()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostAuthSaveFailed", fallback: "Update failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct WebsitePathAuthFormView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let websiteId: Int
    let editor: WebsitePathAuthEditor
    let onSaved: () -> Void

    @State private var name: String
    @State private var path: String
    @State private var username: String
    @State private var password = ""
    @State private var remark: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(websiteId: Int, editor: WebsitePathAuthEditor, onSaved: @escaping () -> Void) {
        self.websiteId = websiteId
        self.editor = editor
        self.onSaved = onSaved
        _name = State(initialValue: editor.rule?.name ?? "")
        _path = State(initialValue: editor.rule?.path ?? "/")
        _username = State(initialValue: editor.rule?.username ?? "")
        _remark = State(initialValue: editor.rule?.remark ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(translations.get("commonName", fallback: "Name"), text: $name)
                TextField(translations.get("commonPath", fallback: "Path"), text: $path)
                TextField(translations.get("databaseUsernameLabel", fallback: "Username"),
                          text: $username)
                SecureField(translations.get("commonPassword", fallback: "Password"),
                            text: $password)
                TextField(translations.get("hostAuthRemark", fallback: "Remark"), text: $remark)
            }
            .formStyle(.grouped)
            .navigationTitle(editor.rule == nil
                             ? translations.get("hostAuthAddPath", fallback: "Add path rule")
                             : translations.get("commonEdit", fallback: "Edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || !canSave)
                }
            }
            .alert(
                translations.get("commonError", fallback: "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .frame(minWidth: 460, minHeight: 360)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !path.trimmingCharacters(in: .whitespaces).isEmpty
            && !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsitePathAuth",
                arguments: [
                    "websiteID": websiteId,
                    "operate": editor.rule == nil ? "create" : "edit",
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "path": path.trimmingCharacters(in: .whitespacesAndNewlines),
                    "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
                    "password": password,
                    "remark": remark,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onSaved()
                dismiss()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostAuthSaveFailed", fallback: "Update failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}