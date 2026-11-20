import SwiftUI
import AppleSharedUI

/// CORS 配置表单。
struct WebsiteCorsView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    @State private var enabled = false
    @State private var allowOrigins = "*"
    @State private var allowMethods = "GET,POST,OPTIONS,PUT,DELETE"
    @State private var allowHeaders = ""
    @State private var allowCredentials = false
    @State private var preflight = true
    @State private var isLoading = false
    @State private var toastText: String?

    var body: some View {
        Form {
            Section {
                Toggle(translations.get("hostCorsEnable", fallback: "Enable CORS"), isOn: $enabled)
                TextField(translations.get("hostCorsAllowOrigins", fallback: "Allowed origins"),
                          text: $allowOrigins)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(translations.get("hostCorsAllowMethods", fallback: "Allowed methods"),
                          text: $allowMethods)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(translations.get("hostCorsAllowHeaders", fallback: "Allowed headers"),
                          text: $allowHeaders)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Toggle(translations.get("hostCorsAllowCredentials", fallback: "Allow credentials"),
                       isOn: $allowCredentials)
                Toggle(translations.get("hostCorsPreflight", fallback: "Preflight response"),
                       isOn: $preflight)
            } footer: {
                Text(translations.get("hostCorsPreflightHelper", fallback: ""))
                    .font(.footnote)
            }
        }
        .navigationTitle(translations.get("websiteCorsTitle", fallback: "CORS"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    save()
                } label: {
                    Label(translations.get("commonSave", fallback: "Save"),
                          systemImage: "square.and.arrow.down")
                }
                .disabled(isLoading)
            }
        }
        .operationNotice(toastText)
        .onAppear {
            fetch()
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteCors",
            arguments: ["id": websiteId]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any], !dict.isEmpty else { return }
                enabled = dict["cors"] as? Bool ?? false
                let origins = dict["allowOrigins"] as? String ?? ""
                if !origins.isEmpty { allowOrigins = origins }
                let methods = dict["allowMethods"] as? String ?? ""
                if !methods.isEmpty { allowMethods = methods }
                allowHeaders = dict["allowHeaders"] as? String ?? ""
                allowCredentials = dict["allowCredentials"] as? Bool ?? false
                preflight = dict["preflight"] as? Bool ?? true
            }
        }
    }

    private func save() {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteCors",
            arguments: [
                "websiteID": websiteId,
                "cors": enabled,
                "allowOrigins": allowOrigins,
                "allowMethods": allowMethods,
                "allowHeaders": allowHeaders,
                "allowCredentials": allowCredentials,
                "preflight": preflight,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("hostCorsSaved", fallback: "CORS saved")
                    : translations.get("hostCorsSaveFailed", fallback: "Save failed"))
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

/// 防盗链配置表单。
struct WebsiteLeechView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    @State private var enabled = false
    @State private var extendsValue = "js,css,png,jpg,jpeg,gif,webp,webm,avif,ico,bmp,swf,eot,svg,ttf,woff,woff2"
    @State private var domainsText = ""
    @State private var noneRef = true
    @State private var blocked = false
    @State private var returnCode = "404"
    @State private var cache = false
    @State private var cacheTime = "30"
    @State private var cacheUnit = "d"
    @State private var logEnable = false
    @State private var isLoading = false
    @State private var toastText: String?

    var body: some View {
        Form {
            Section {
                TextField(translations.get("hostLeechExtends", fallback: "File extensions"),
                          text: $extendsValue, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section(translations.get("hostLeechProtection", fallback: "Anti-leech")) {
                Toggle(translations.get("hostLeechEnable", fallback: "Enable"), isOn: $enabled)
                if enabled {
                    TextField(translations.get("hostLeechAccessDomains", fallback: "Allowed domains"),
                              text: $domainsText, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Toggle(translations.get("hostLeechNoneRef", fallback: "Allow empty Referer"),
                           isOn: $noneRef)
                    Toggle(translations.get("hostLeechBlockedRef", fallback: "Allow non-standard Referer"),
                           isOn: $blocked)
                    Picker(translations.get("hostLeechReturn", fallback: "Response code"),
                           selection: $returnCode) {
                        Text("400").tag("400")
                        Text("403").tag("403")
                        Text("404").tag("404")
                    }
                }
            }
            Section(translations.get("hostLeechCacheControl", fallback: "Cache control")) {
                Toggle(translations.get("hostLeechBrowserCache", fallback: "Browser cache"),
                       isOn: $cache)
                if cache {
                    HStack {
                        TextField(translations.get("hostLeechCacheTime", fallback: "Cache time"),
                                  text: $cacheTime)
                            .keyboardType(.numberPad)
                        Picker("", selection: $cacheUnit) {
                            Text(translations.get("hostLeechUnitSeconds", fallback: "s")).tag("s")
                            Text(translations.get("hostLeechUnitMinutes", fallback: "m")).tag("m")
                            Text(translations.get("hostLeechUnitHours", fallback: "h")).tag("h")
                            Text(translations.get("hostLeechUnitDays", fallback: "d")).tag("d")
                            Text(translations.get("hostLeechUnitWeeks", fallback: "w")).tag("w")
                        }
                        .labelsHidden()
                    }
                }
                if cache || enabled {
                    Toggle(translations.get("hostLeechLogEnable", fallback: "Log requests"),
                           isOn: $logEnable)
                }
            }
        }
        .navigationTitle(translations.get("websiteLeechTitle", fallback: "Anti-Leech"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    save()
                } label: {
                    Label(translations.get("commonSave", fallback: "Save"),
                          systemImage: "square.and.arrow.down")
                }
                .disabled(isLoading)
            }
        }
        .operationNotice(toastText)
        .onAppear {
            fetch()
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteLeech",
            arguments: ["websiteID": websiteId]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any], !dict.isEmpty else { return }
                enabled = dict["enable"] as? Bool ?? false
                cache = dict["cache"] as? Bool ?? false
                let time = dict["cacheTime"] as? Int ?? 0
                cacheTime = time > 0 ? "\(time)" : "30"
                let unit = dict["cacheUnit"] as? String ?? dict["cacheUint"] as? String ?? ""
                cacheUnit = unit.isEmpty ? "d" : unit
                let exts = dict["extends"] as? String ?? ""
                if !exts.isEmpty { extendsValue = exts }
                let code = dict["return"] as? String ?? ""
                returnCode = code.isEmpty ? "404" : code
                logEnable = dict["logEnable"] as? Bool ?? false
                noneRef = dict["noneRef"] as? Bool ?? true
                blocked = dict["blocked"] as? Bool ?? false
                let names = (dict["serverNames"] as? [Any])?.compactMap { $0 as? String } ?? []
                domainsText = names.joined(separator: "\n")
            }
        }
    }

    private func save() {
        let names = domainsText
            .split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !enabled || !names.isEmpty else {
            showToast(translations.get("hostLeechDomainsRequired",
                                       fallback: "Allowed domains are required."))
            return
        }
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteLeech",
            arguments: [
                "websiteID": websiteId,
                "enable": enabled,
                "extends": extendsValue,
                "serverNames": names,
                "noneRef": noneRef,
                "blocked": blocked,
                "return_": returnCode,
                "cache": cache,
                "cacheTime": Int(cacheTime.trimmingCharacters(in: .whitespaces)) ?? 30,
                "cacheUint": cacheUnit,
                "logEnable": logEnable,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("hostLeechSaved", fallback: "Anti-leech saved")
                    : translations.get("hostLeechSaveFailed", fallback: "Save failed"))
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

/// BasicAuth 根用户与路径认证。
struct WebsiteAuthView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    @State private var enabled = false
    @State private var rootUsers: [WebsiteRootAuthRow] = []
    @State private var pathRules: [WebsitePathAuthRow] = []
    @State private var isLoading = false
    @State private var toastText: String?
    @State private var pendingDeleteRoot: WebsiteRootAuthRow?
    @State private var pendingDeletePath: WebsitePathAuthRow?
    @State private var showUserSheet = false
    @State private var showPathSheet = false
    @State private var editingRoot: WebsiteRootAuthRow?

    @State private var formUsername = ""
    @State private var formPassword = ""
    @State private var formRemark = ""
    @State private var formName = ""
    @State private var formPath = ""

    var body: some View {
        Group {
            if isLoading && rootUsers.isEmpty && pathRules.isEmpty {
                LoadingView()
            } else {
                List {
                    Section {
                        Toggle(translations.get("hostAuthEnableSwitch", fallback: "Enable password access"),
                               isOn: Binding(
                                get: { enabled },
                                set: { toggleEnable($0) }
                               ))
                    } footer: {
                        Text(translations.get("hostAuthEditHelper",
                                              fallback: "Passwords cannot be read back; set a new password to edit."))
                            .font(.footnote)
                    }
                    Section(translations.get("hostAuthScopeGlobal", fallback: "Global")) {
                        if rootUsers.isEmpty {
                            Text(translations.get("websiteAuthBasicEmpty", fallback: "No users"))
                                .foregroundColor(.secondary)
                        }
                        ForEach(rootUsers) { user in
                            Button {
                                openEditUser(user)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.username)
                                        .font(.subheadline.weight(.medium))
                                    if !user.remark.isEmpty {
                                        Text(user.remark)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDeleteRoot = user
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                        }
                        Button {
                            editingRoot = nil
                            formUsername = ""
                            formPassword = ""
                            formRemark = ""
                            showUserSheet = true
                        } label: {
                            Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                        }
                    }
                    Section(translations.get("hostAuthPathSectionTitle", fallback: "Path authentication")) {
                        if pathRules.isEmpty {
                            Text(translations.get("hostAuthPathEmpty", fallback: "No path rules"))
                                .foregroundColor(.secondary)
                        }
                        ForEach(pathRules) { rule in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(rule.name)
                                    .font(.subheadline.weight(.medium))
                                HStack(spacing: 12) {
                                    Label(rule.path, systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                                    Label(rule.username, systemImage: "person")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingDeletePath = rule
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                        }
                        Button {
                            formName = ""
                            formPath = "/"
                            formUsername = ""
                            formPassword = ""
                            formRemark = ""
                            showPathSheet = true
                        } label: {
                            Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .navigationTitle(translations.get("websiteAuthBasicTitle", fallback: "Basic Auth"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
            }
        }
        .sheet(isPresented: $showUserSheet) {
            userSheet
        }
        .sheet(isPresented: $showPathSheet) {
            pathSheet
        }
        .confirmationDialog(
            translations.get("hostAuthDeleteConfirm", fallback: "Delete this user?"),
            isPresented: Binding(
                get: { pendingDeleteRoot != nil },
                set: { if !$0 { pendingDeleteRoot = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteRootUser()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDeleteRoot = nil
            }
        }
        .confirmationDialog(
            translations.get("hostAuthPathDeleteConfirm", fallback: "Delete this path rule?")
                .replacingOccurrences(of: "{0}", with: pendingDeletePath?.name ?? ""),
            isPresented: Binding(
                get: { pendingDeletePath != nil },
                set: { if !$0 { pendingDeletePath = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deletePathRule()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDeletePath = nil
            }
        }
        .operationNotice(toastText)
        .onAppear {
            fetch()
        }
    }

    private var userSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonUsername", fallback: "Username"),
                              text: $formUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(editingRoot != nil)
                    SecureField(translations.get("commonPassword", fallback: "Password"),
                                text: $formPassword)
                    TextField(translations.get("hostAuthRemark", fallback: "Remark"),
                              text: $formRemark)
                }
            }
            .navigationTitle(editingRoot == nil
                ? translations.get("websiteAuthBasicTitle", fallback: "Basic Auth")
                : translations.get("commonEdit", fallback: "Edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showUserSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        saveRootUser()
                    }
                    .disabled(formUsername.trimmingCharacters(in: .whitespaces).isEmpty
                              || formPassword.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var pathSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $formName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("commonPath", fallback: "Path"), text: $formPath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("commonUsername", fallback: "Username"),
                              text: $formUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(translations.get("commonPassword", fallback: "Password"),
                                text: $formPassword)
                    TextField(translations.get("hostAuthRemark", fallback: "Remark"),
                              text: $formRemark)
                }
            }
            .navigationTitle(translations.get("hostAuthPathSectionTitle", fallback: "Path authentication"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showPathSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        savePathRule()
                    }
                    .disabled(formName.trimmingCharacters(in: .whitespaces).isEmpty
                              || formPath.trimmingCharacters(in: .whitespaces).isEmpty
                              || formUsername.trimmingCharacters(in: .whitespaces).isEmpty
                              || formPassword.isEmpty)
                }
            }
        }
    }

    private func openEditUser(_ user: WebsiteRootAuthRow) {
        editingRoot = user
        formUsername = user.username
        formPassword = ""
        formRemark = user.remark
        showUserSheet = true
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteAuths",
            arguments: ["websiteID": websiteId]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                if let dict = result as? [String: Any] {
                    enabled = dict["enable"] as? Bool ?? false
                    let items = dict["items"] as? [[String: Any]] ?? []
                    rootUsers = items.compactMap { item in
                        guard let username = item["username"] as? String, !username.isEmpty else {
                            return nil
                        }
                        return WebsiteRootAuthRow(
                            username: username,
                            remark: item["remark"] as? String ?? ""
                        )
                    }
                }
            }
        }
        ChannelManager.shared.invokeDataMethod(
            "getWebsitePathAuths",
            arguments: ["websiteID": websiteId]
        ) { result in
            DispatchQueue.main.async {
                guard let items = result as? [[String: Any]] else { return }
                pathRules = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return WebsitePathAuthRow(
                        name: name,
                        path: item["path"] as? String ?? "",
                        username: item["username"] as? String ?? "",
                        remark: item["remark"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func toggleEnable(_ value: Bool) {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteAuth",
            arguments: [
                "websiteID": websiteId,
                "operate": value ? "enable" : "disable",
                "scope": "root",
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    enabled = value
                }
                showToast(success
                    ? translations.get("hostAuthSaved", fallback: "Password access updated")
                    : translations.get("hostAuthEnableFailed", fallback: "Update failed"))
            }
        }
    }

    private func saveRootUser() {
        let username = formUsername.trimmingCharacters(in: .whitespaces)
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteAuth",
            arguments: [
                "websiteID": websiteId,
                "operate": editingRoot == nil ? "create" : "edit",
                "scope": "root",
                "username": username,
                "password": formPassword,
                "remark": formRemark,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showUserSheet = false
                showToast(success
                    ? translations.get("hostAuthSaved", fallback: "Password access updated")
                    : translations.get("hostAuthSaveFailed", fallback: "Update failed"))
                if success { fetch() }
            }
        }
    }

    private func deleteRootUser() {
        guard let user = pendingDeleteRoot else { return }
        pendingDeleteRoot = nil
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteAuth",
            arguments: [
                "websiteID": websiteId,
                "operate": "delete",
                "scope": "root",
                "username": user.username,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("hostAuthDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func savePathRule() {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsitePathAuth",
            arguments: [
                "websiteID": websiteId,
                "operate": "create",
                "name": formName.trimmingCharacters(in: .whitespaces),
                "path": formPath.trimmingCharacters(in: .whitespaces),
                "username": formUsername.trimmingCharacters(in: .whitespaces),
                "password": formPassword,
                "remark": formRemark,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showPathSheet = false
                showToast(success
                    ? translations.get("hostAuthSaved", fallback: "Password access updated")
                    : translations.get("hostAuthSaveFailed", fallback: "Update failed"))
                if success { fetch() }
            }
        }
    }

    private func deletePathRule() {
        guard let rule = pendingDeletePath else { return }
        pendingDeletePath = nil
        ChannelManager.shared.invokeDataMethod(
            "updateWebsitePathAuth",
            arguments: [
                "websiteID": websiteId,
                "operate": "delete",
                "name": rule.name,
                "path": rule.path,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("hostAuthDeleteFailed", fallback: "Delete failed"))
                fetch()
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
