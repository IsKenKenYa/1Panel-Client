import SwiftUI
import AppleSharedUI

/// 数据库详情：基础信息、MySQL 用户管理、修改密码与删除。
/// 列表行已携带 scope/名称等字段，详情页按需再取服务端基础信息。
struct DatabaseUserRow: Identifiable {
    let username: String
    let host: String
    let description: String

    var id: String { "\(username)@\(host)" }
}

struct DatabaseDetailView: View {
    let reference: DatabaseRef
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    @State private var baseInfo: [String: Any] = [:]
    @State private var isLoading = false
    @State private var showPasswordSheet = false
    @State private var showDeleteConfirm = false
    @State private var newPassword = ""
    @State private var toastText: String?

    @State private var users: [DatabaseUserRow] = []
    @State private var isLoadingUsers = false
    @State private var showCreateUserSheet = false
    @State private var newUsername = ""
    @State private var newUserHost = "%"
    @State private var newUserPassword = ""
    @State private var userForPassword: DatabaseUserRow?
    @State private var userPasswordDraft = ""
    @State private var userToDelete: DatabaseUserRow?

    var body: some View {
        List {
            Section(translations.get("databaseBaseInfoTitle", fallback: "Base Info")) {
                InfoLine(label: translations.get("databaseNameLabel", fallback: "Name"),
                         value: reference.name)
                InfoLine(label: translations.get("databaseTypeMysql", fallback: "MySQL"),
                         value: reference.scope)
                InfoLine(label: translations.get("databaseEngineLabel", fallback: "Engine"),
                         value: reference.engine)
                InfoLine(label: translations.get("databaseVersionLabel", fallback: "Version"),
                         value: reference.version)
                InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                         value: reference.status)
                if !reference.description.isEmpty {
                    InfoLine(label: translations.get("websitesRemarkLabel", fallback: "Remark"),
                             value: reference.description)
                }
            }

            if !baseInfoFields.isEmpty {
                Section(translations.get("databaseStatusTitle", fallback: "Status")) {
                    ForEach(baseInfoFields, id: \.0) { item in
                        InfoLine(label: item.0, value: item.1)
                    }
                }
            }

            if reference.scope == "mysql" {
                Section {
                    ForEach(users) { user in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.username)
                                .font(.subheadline.weight(.medium))
                            Text("@\(user.host)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                userToDelete = user
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                            Button {
                                userPasswordDraft = ""
                                userForPassword = user
                            } label: {
                                Label(translations.get("databaseUserChangePassword", fallback: "Change Password"),
                                      systemImage: "key")
                            }
                            .tint(.orange)
                        }
                    }
                    Button {
                        newUsername = ""
                        newUserHost = "%"
                        newUserPassword = ""
                        showCreateUserSheet = true
                    } label: {
                        Label(translations.get("databaseUserCreateAction", fallback: "New User"),
                              systemImage: "person.badge.plus")
                    }
                } header: {
                    Text(translations.get("databaseUserListTitle", fallback: "Database Users"))
                }
            }

            Section(translations.get("websitesDetailActionsTitle", fallback: "Quick actions")) {
                Button {
                    newPassword = ""
                    showPasswordSheet = true
                } label: {
                    Label(translations.get("databaseChangePasswordAction", fallback: "Change Password"),
                          systemImage: "key")
                }
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(reference.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .databases)
                Button {
                    fetchBaseInfo()
                    if reference.scope == "mysql" {
                        fetchUsers()
                    }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showPasswordSheet) {
            passwordSheet
        }
        .sheet(isPresented: $showCreateUserSheet) {
            createUserSheet
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteDatabase()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .confirmationDialog(
            userDeleteMessage,
            isPresented: Binding(
                get: { userToDelete != nil },
                set: { if !$0 { userToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteUser()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                userToDelete = nil
            }
        }
        .alert(
            translations.get("databaseUserChangePassword", fallback: "Change Password"),
            isPresented: Binding(
                get: { userForPassword != nil },
                set: { if !$0 { userForPassword = nil } }
            )
        ) {
            SecureField(translations.get("databaseUserNewPasswordLabel", fallback: "New Password"),
                        text: $userPasswordDraft)
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                userForPassword = nil
            }
            Button(translations.get("commonSave", fallback: "Save")) {
                changeUserPassword()
            }
        }
        .operationNotice(toastText)
        .onAppear {
            fetchBaseInfo()
            if reference.scope == "mysql" {
                fetchUsers()
            }
        }
    }

    private var createUserSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("databaseUsernameLabel", fallback: "Username"),
                              text: $newUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("databaseUserHostLabel", fallback: "Host"),
                              text: $newUserHost)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(translations.get("databasePasswordLabel", fallback: "Password"),
                                text: $newUserPassword)
                }
            }
            .navigationTitle(translations.get("databaseUserCreateAction", fallback: "New User"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateUserSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createUser()
                    }
                    .disabled(newUsername.trimmingCharacters(in: .whitespaces).isEmpty
                              || newUserHost.trimmingCharacters(in: .whitespaces).isEmpty
                              || newUserPassword.isEmpty)
                }
            }
        }
    }

    private var passwordSheet: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(translations.get("databasePasswordLabel", fallback: "Password"),
                                text: $newPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text(translations.get("databaseChangePasswordHint",
                                          fallback: "The database password is updated immediately."))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("databaseChangePasswordAction", fallback: "Change Password"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showPasswordSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        submitPassword()
                    }
                    .disabled(newPassword.isEmpty)
                }
            }
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

    private func fetchBaseInfo() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getDatabaseBaseInfo",
            arguments: ["type": reference.scope, "name": reference.name]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                if let dict = result as? [String: Any] {
                    baseInfo = dict
                }
            }
        }
    }

    private func fetchUsers() {
        guard !isLoadingUsers else { return }
        isLoadingUsers = true
        ChannelManager.shared.invokeDataMethod(
            "getDatabaseUsers",
            arguments: ["database": reference.lookupName]
        ) { result in
            DispatchQueue.main.async {
                isLoadingUsers = false
                guard let items = result as? [[String: Any]] else { return }
                users = items.compactMap { item in
                    guard let username = item["username"] as? String, !username.isEmpty else { return nil }
                    return DatabaseUserRow(
                        username: username,
                        host: item["host"] as? String ?? "%",
                        description: item["description"] as? String ?? ""
                    )
                }
            }
        }
    }

    private var userDeleteMessage: String {
        let template = translations.get("databaseUserDeleteConfirm", fallback: "Delete user {name}?")
        return template.replacingOccurrences(of: "{name}", with: userToDelete?.username ?? "")
    }

    private func createUser() {
        let username = newUsername.trimmingCharacters(in: .whitespaces)
        let host = newUserHost.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty, !host.isEmpty, !newUserPassword.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "createDatabaseUser",
            arguments: [
                "database": reference.lookupName,
                "username": username,
                "host": host,
                "password": newUserPassword,
                "description": "",
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateUserSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                fetchUsers()
            }
        }
    }

    private func deleteUser() {
        guard let user = userToDelete else { return }
        userToDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteDatabaseUser",
            arguments: [
                "database": reference.lookupName,
                "username": user.username,
                "host": user.host,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetchUsers()
            }
        }
    }

    private func changeUserPassword() {
        guard let user = userForPassword, !userPasswordDraft.isEmpty else { return }
        let password = userPasswordDraft
        userForPassword = nil
        ChannelManager.shared.invokeDataMethod(
            "updateDatabaseUserPassword",
            arguments: [
                "database": reference.lookupName,
                "username": user.username,
                "host": user.host,
                "password": password,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
            }
        }
    }

    private func submitPassword() {
        guard !newPassword.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "changeDatabasePassword",
            arguments: [
                "scope": reference.scope,
                "name": reference.name,
                "lookupName": reference.lookupName,
                "engine": reference.engine,
                "source": reference.source,
                "id": reference.id ?? 0,
                "password": newPassword,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showPasswordSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
            }
        }
    }

    private func deleteDatabase() {
        guard let id = reference.id else {
            showToast(translations.get("commonDeleteFailed", fallback: "Delete failed"))
            return
        }
        ChannelManager.shared.invokeDataMethod(
            "deleteDatabase",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    dismiss()
                } else {
                    showToast(translations.get("commonDeleteFailed", fallback: "Delete failed"))
                }
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}
