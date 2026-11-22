import AppleSharedUI
import SwiftUI

/// macOS 数据库详情：基础信息、MySQL 用户管理与密码、删除。
struct DatabaseDetailView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let database: DatabaseModel

    @State private var baseInfo: [String: Any] = [:]
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var users: [DatabaseUserRow] = []
    @State private var isLoadingUsers = false
    @State private var activeSheet: DatabaseDetailSheet?
    @State private var pendingAction: DatabasePendingAction?
    @State private var actionError: String?

    @State private var newUsername = ""
    @State private var newUserHost = "%"
    @State private var newUserPassword = ""
    @State private var databasePasswordDraft = ""
    @State private var userPasswordDraft = ""

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section(translations.get("databaseBaseInfoTitle", fallback: "Base Info")) {
                    InfoLine(label: translations.get("databaseNameLabel", fallback: "Name"),
                             value: database.name)
                    InfoLine(label: translations.get("databaseEngineLabel", fallback: "Engine"),
                             value: database.engine.isEmpty ? database.type : database.engine)
                    InfoLine(label: translations.get("databaseVersionLabel", fallback: "Version"),
                             value: database.version)
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: database.status)
                    InfoLine(label: translations.get("databaseTypeMysql", fallback: "Scope"),
                             value: database.scope)
                    if !database.description.isEmpty {
                        InfoLine(label: translations.get("websitesRemarkLabel", fallback: "Remark"),
                                 value: database.description)
                    }
                }

                if !baseInfoFields.isEmpty {
                    Section(translations.get("databaseStatusTitle", fallback: "Status")) {
                        ForEach(baseInfoFields, id: \.0) { item in
                            InfoLine(label: item.0, value: item.1)
                        }
                    }
                }

                if database.scope == "mysql" {
                    Section(translations.get("databaseUserListTitle", fallback: "Database Users")) {
                        if isLoadingUsers && users.isEmpty {
                            ProgressView().controlSize(.small)
                        } else if users.isEmpty {
                            Text(translations.get("databaseUserEmpty", fallback: "No users"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(users) { user in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.username).font(.subheadline.weight(.medium))
                                    Text("@\(user.host)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    userPasswordDraft = ""
                                    activeSheet = .changeUserPassword(user)
                                } label: {
                                    Image(systemName: "key")
                                }
                                .buttonStyle(.borderless)
                                .help(translations.get("databaseUserChangePassword",
                                                       fallback: "Change Password"))
                                Button(role: .destructive) {
                                    pendingAction = .deleteUser(user)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                                .help(translations.get("commonDelete", fallback: "Delete"))
                            }
                            .padding(.vertical, 2)
                        }
                        Button {
                            newUsername = ""
                            newUserHost = "%"
                            newUserPassword = ""
                            activeSheet = .createUser
                        } label: {
                            Label(translations.get("databaseUserCreateAction", fallback: "New User"),
                                  systemImage: "person.badge.plus")
                        }
                        .disabled(database.lookupName.isEmpty)
                    }
                }

                Section(translations.get("websitesDetailActionsTitle", fallback: "Quick actions")) {
                    Button {
                        databasePasswordDraft = ""
                        activeSheet = .changeDatabasePassword
                    } label: {
                        Label(translations.get("databaseChangePasswordAction",
                                               fallback: "Change Password"),
                              systemImage: "key")
                    }
                    .disabled(database.lookupName.isEmpty)
                    Button(role: .destructive) {
                        pendingAction = .deleteDatabase
                    } label: {
                        Label(translations.get("commonDelete", fallback: "Delete"),
                              systemImage: "trash")
                    }
                }

                if let loadError {
                    Section {
                        Text(loadError).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .listStyle(.inset)
        }
        .navigationTitle(database.name)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task {
                        await loadBaseInfo()
                        if database.scope == "mysql" {
                            await loadUsers()
                        }
                    }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .createUser:
                createUserSheet
            case .changeDatabasePassword:
                databasePasswordSheet
            case .changeUserPassword(let user):
                userPasswordSheet(user)
            }
        }
        .confirmationDialog(
            pendingTitle,
            isPresented: Binding(
                get: { pendingAction != nil },
                set: { if !$0 { pendingAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingAction {
                Button(pendingButton(action), role: .destructive) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingAction = nil
                }
            }
        } message: {
            Text(pendingMessage)
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await loadBaseInfo()
            if database.scope == "mysql" {
                await loadUsers()
            }
        }
    }

    private var createUserSheet: some View {
        NavigationStack {
            Form {
                TextField(translations.get("databaseUsernameLabel", fallback: "Username"),
                          text: $newUsername)
                TextField(translations.get("databaseUserHostLabel", fallback: "Host"),
                          text: $newUserHost)
                SecureField(translations.get("databasePasswordLabel", fallback: "Password"),
                            text: $newUserPassword)
            }
            .navigationTitle(translations.get("databaseUserCreateAction", fallback: "New User"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        activeSheet = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await createUser() }
                    }
                    .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty
                              || newUserHost.trimmingCharacters(in: .whitespaces).isEmpty
                              || newUserPassword.isEmpty)
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 440, minHeight: 280)
        }
    }

    private var databasePasswordSheet: some View {
        NavigationStack {
            Form {
                SecureField(translations.get("databasePasswordLabel", fallback: "Password"),
                            text: $databasePasswordDraft)
                Text(translations.get("databaseChangePasswordHint",
                                      fallback: "The database password is updated immediately."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle(translations.get("databaseChangePasswordAction", fallback: "Change Password"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        activeSheet = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await changeDatabasePassword() }
                    }
                    .disabled(databasePasswordDraft.isEmpty)
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 440, minHeight: 240)
        }
    }

    private func userPasswordSheet(_ user: DatabaseUserRow) -> some View {
        NavigationStack {
            Form {
                SecureField(translations.get("databaseUserNewPasswordLabel",
                                             fallback: "New Password"),
                            text: $userPasswordDraft)
            }
            .navigationTitle(translations.get("databaseUserChangePassword",
                                              fallback: "Change Password"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        activeSheet = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await changeUserPassword(user) }
                    }
                    .disabled(userPasswordDraft.isEmpty)
                }
            }
            .formStyle(.grouped)
            .frame(minWidth: 440, minHeight: 220)
        }
    }

    private var baseInfoFields: [(String, String)] {
        baseInfo
            .filter { _, value in
                value is String || value is Int || value is Double || value is Bool
            }
            .sorted { $0.key < $1.key }
            .map { ($0.key, "\($0.value)") }
    }

    private func loadBaseInfo() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getDatabaseBaseInfo",
                arguments: ["type": database.scope, "name": database.name]
            )
            baseInfo = raw as? [String: Any] ?? [:]
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func loadUsers() async {
        guard database.scope == "mysql", !isLoadingUsers else { return }
        isLoadingUsers = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getDatabaseUsers",
                arguments: ["database": database.lookupName]
            )
            let items = raw as? [[String: Any]] ?? []
            users = items.compactMap { item in
                guard let username = item["username"] as? String, !username.isEmpty else {
                    return nil
                }
                return DatabaseUserRow(
                    username: username,
                    host: item["host"] as? String ?? "%",
                    description: item["description"] as? String ?? ""
                )
            }
        } catch {
            loadError = error.localizedDescription
        }
        isLoadingUsers = false
    }

    private func createUser() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "createDatabaseUser",
                arguments: [
                    "database": database.lookupName,
                    "username": newUsername.trimmingCharacters(in: .whitespaces),
                    "host": newUserHost.trimmingCharacters(in: .whitespaces),
                    "password": newUserPassword,
                    "description": "",
                ]
            )
            guard success(raw) else {
                actionError = translations.get("commonSaveFailed", fallback: "Save failed")
                return
            }
            activeSheet = nil
            await loadUsers()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func changeDatabasePassword() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "changeDatabasePassword",
                arguments: [
                    "scope": database.scope,
                    "name": database.name,
                    "lookupName": database.lookupName,
                    "engine": database.engine,
                    "source": database.source,
                    "id": database.recordId ?? 0,
                    "password": databasePasswordDraft,
                ]
            )
            guard success(raw) else {
                actionError = translations.get("commonSaveFailed", fallback: "Save failed")
                return
            }
            activeSheet = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func changeUserPassword(_ user: DatabaseUserRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateDatabaseUserPassword",
                arguments: [
                    "database": database.lookupName,
                    "username": user.username,
                    "host": user.host,
                    "password": userPasswordDraft,
                ]
            )
            guard success(raw) else {
                actionError = translations.get("commonSaveFailed", fallback: "Save failed")
                return
            }
            activeSheet = nil
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteUser(_ user: DatabaseUserRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteDatabaseUser",
                arguments: [
                    "database": database.lookupName,
                    "username": user.username,
                    "host": user.host,
                ]
            )
            guard success(raw) else {
                actionError = translations.get("commonDeleteFailed", fallback: "Delete failed")
                return
            }
            await loadUsers()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteDatabase() async {
        guard let id = database.recordId else {
            actionError = translations.get("commonDeleteFailed", fallback: "Delete failed")
            return
        }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteDatabase",
                arguments: ["id": id]
            )
            guard success(raw) else {
                actionError = translations.get("commonDeleteFailed", fallback: "Delete failed")
                return
            }
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func success(_ raw: Any?) -> Bool {
        (raw as? [String: Any])?["success"] as? Bool ?? false
    }

    private var pendingTitle: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .deleteDatabase:
            return translations.get("deleteConfirmTitle", fallback: "Confirm Deletion")
        case .deleteUser:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private var pendingMessage: String {
        guard let pendingAction else { return "" }
        switch pendingAction {
        case .deleteDatabase:
            return translations.get("deleteCannotUndoMessage",
                                    fallback: "This action cannot be undone.")
        case .deleteUser(let user):
            return translations.get("databaseUserDeleteConfirm", fallback: "Delete user {name}?")
                .replacingOccurrences(of: "{name}", with: user.username)
                .replacingOccurrences(of: "{0}", with: user.username)
        }
    }

    private func pendingButton(_ action: DatabasePendingAction) -> String {
        switch action {
        case .deleteDatabase, .deleteUser:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private func run(_ action: DatabasePendingAction) {
        pendingAction = nil
        Task {
            switch action {
            case .deleteDatabase:
                await deleteDatabase()
            case .deleteUser(let user):
                await deleteUser(user)
            }
        }
    }
}

struct DatabaseUserRow: Identifiable {
    let username: String
    let host: String
    let description: String

    var id: String { "\(username)@\(host)" }
}

enum DatabaseDetailSheet: Identifiable {
    case createUser
    case changeDatabasePassword
    case changeUserPassword(DatabaseUserRow)

    var id: String {
        switch self {
        case .createUser: return "create-user"
        case .changeDatabasePassword: return "database-password"
        case .changeUserPassword(let user): return "user-password-\(user.id)"
        }
    }
}

enum DatabasePendingAction: Identifiable {
    case deleteDatabase
    case deleteUser(DatabaseUserRow)

    var id: String {
        switch self {
        case .deleteDatabase: return "delete-database"
        case .deleteUser(let user): return "delete-user-\(user.id)"
        }
    }
}