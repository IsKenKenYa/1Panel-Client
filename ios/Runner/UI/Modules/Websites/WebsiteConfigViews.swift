import SwiftUI
import AppleSharedUI

/// 网站配置入口：访问控制、优化与基础认证。
struct WebsiteConfigHubView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        List {
            Section(translations.get("websitesTabConfig", fallback: "Configuration")) {
                NavigationLink {
                    WebsiteRedirectsView(websiteId: websiteId)
                } label: {
                    Label(translations.get("hostWebsiteTabRedirect", fallback: "Redirect"),
                          systemImage: "arrow.turn.down.right")
                }
                NavigationLink {
                    WebsiteAuthView(websiteId: websiteId)
                } label: {
                    Label(translations.get("hostWebsiteTabBasicAuth", fallback: "Password Access"),
                          systemImage: "lock.shield")
                }
            }
            Section {
                NavigationLink {
                    WebsiteRewriteView(websiteId: websiteId)
                } label: {
                    Label(translations.get("hostWebsiteTabRewrite", fallback: "Rewrite"),
                          systemImage: "doc.badge.gearshape")
                }
                NavigationLink {
                    WebsiteCorsView(websiteId: websiteId)
                } label: {
                    Label(translations.get("hostWebsiteTabCors", fallback: "CORS"),
                          systemImage: "arrow.left.and.right.circle")
                }
                NavigationLink {
                    WebsiteLeechView(websiteId: websiteId)
                } label: {
                    Label(translations.get("hostWebsiteTabAntiLeech", fallback: "Anti-Leech"),
                          systemImage: "hand.raised.slash")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

/// 重定向规则行。
struct WebsiteRedirectRow: Identifiable {
    let name: String
    let type: String
    let domains: [String]
    let path: String
    let redirect: String
    let target: String
    let keepPath: Bool
    let redirectRoot: Bool
    let enable: Bool

    var id: String { name }

    /// 来源展示：域名型拼域名列表，其他展示路径。
    var sourceText: String {
        type == "domain" ? domains.joined(separator: ", ") : path
    }
}

/// 重定向列表：新建、编辑、启停与删除。
struct WebsiteRedirectsView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    @State private var redirects: [WebsiteRedirectRow] = []
    @State private var isLoading = false
    @State private var toastText: String?
    @State private var editing: WebsiteRedirectRow?
    @State private var showSheet = false
    @State private var pendingDelete: WebsiteRedirectRow?

    // 表单状态
    @State private var formName = ""
    @State private var formType = "domain"
    @State private var formRedirect = "301"
    @State private var formTarget = ""
    @State private var formPath = ""
    @State private var formDomains = ""
    @State private var formKeepPath = true
    @State private var formRedirectRoot = false

    var body: some View {
        Group {
            if isLoading && redirects.isEmpty {
                LoadingView()
            } else if redirects.isEmpty {
                EmptyStateView(
                    icon: "arrow.turn.down.right",
                    message: translations.get("hostRedirectEmpty", fallback: "No redirect rules")
                )
            } else {
                List {
                    ForEach(redirects) { rule in
                        Button {
                            openEdit(rule)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(rule.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    StatusBadge(
                                        text: rule.enable
                                            ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                            : translations.get("systemSettingsDisabled", fallback: "Disabled"),
                                        color: rule.enable ? .green : .gray
                                    )
                                }
                                Text(rule.sourceText.isEmpty ? typeLabel(rule.type) : rule.sourceText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                if !rule.target.isEmpty {
                                    Label("\(rule.redirect) → \(rule.target)",
                                          systemImage: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = rule
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                toggle(rule)
                            } label: {
                                Label(
                                    translations.get(rule.enable ? "hostRedirectDisable" : "commonEnable",
                                                     fallback: rule.enable ? "Disable" : "Enable"),
                                    systemImage: rule.enable ? "pause.circle" : "play.circle"
                                )
                            }
                            .tint(rule.enable ? .orange : .green)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .navigationTitle(translations.get("websiteRedirectTitle", fallback: "Redirect"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    openCreate()
                } label: {
                    Label(translations.get("hostRedirectAdd", fallback: "Add redirect"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showSheet) {
            editSheet
        }
        .confirmationDialog(
            translations.get("hostRedirectDeleteConfirmTitle", fallback: "Delete redirect"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                confirmDelete()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        }
        .operationNotice(toastText)
        .onAppear {
            if redirects.isEmpty {
                fetch()
            }
        }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $formName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(editing != nil || formType == "404")
                    Picker(translations.get("commonType", fallback: "Type"), selection: $formType) {
                        Text(translations.get("hostRedirectTypeDomain", fallback: "Domain"))
                            .tag("domain")
                        Text(translations.get("hostRedirectTypePath", fallback: "Path"))
                            .tag("path")
                        Text("404").tag("404")
                    }
                    .disabled(editing != nil)
                    Picker(translations.get("hostRedirectWay", fallback: "Way"), selection: $formRedirect) {
                        Text("301").tag("301")
                        Text("302").tag("302")
                    }
                } footer: {
                    Text(translations.get("hostRedirectWayHelper",
                                          fallback: "301 permanent, 302 temporary"))
                        .font(.footnote)
                }
                Section {
                    if formType == "domain" {
                        TextField(translations.get("hostRedirectDomainsPlaceholder",
                                                   fallback: "One domain per line"),
                                  text: $formDomains, axis: .vertical)
                            .lineLimit(3...6)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    if formType == "path" {
                        TextField(translations.get("commonPath", fallback: "Path"), text: $formPath)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    if formType == "404" {
                        Toggle(translations.get("hostRedirectRoot",
                                                fallback: "Redirect site root to this rule"),
                               isOn: $formRedirectRoot)
                    }
                    if !(formType == "404" && formRedirectRoot) {
                        TextField(translations.get("hostRedirectTarget", fallback: "Target URL"),
                                  text: $formTarget)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                    }
                    if formType != "404" {
                        Toggle(translations.get("hostRedirectKeepPath", fallback: "Keep path"),
                               isOn: $formKeepPath)
                    }
                }
            }
            .navigationTitle(editing == nil
                ? translations.get("hostRedirectAdd", fallback: "Add redirect")
                : translations.get("hostRedirectEditTitle", fallback: "Edit redirect"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        submit()
                    }
                    .disabled(!canSubmit)
                }
            }
        }
    }

    private var canSubmit: Bool {
        if formName.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if !(formType == "404" && formRedirectRoot)
            && formTarget.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        if formType == "domain" && parsedDomains.isEmpty { return false }
        if formType == "path" && formPath.trimmingCharacters(in: .whitespaces).isEmpty {
            return false
        }
        return true
    }

    private var parsedDomains: [String] {
        formDomains
            .split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func openCreate() {
        editing = nil
        formName = ""
        formType = "domain"
        formRedirect = "301"
        formTarget = ""
        formPath = ""
        formDomains = ""
        formKeepPath = true
        formRedirectRoot = false
        showSheet = true
    }

    private func openEdit(_ rule: WebsiteRedirectRow) {
        editing = rule
        formName = rule.name
        formType = rule.type
        formRedirect = rule.redirect.isEmpty ? "301" : rule.redirect
        formTarget = rule.target
        formPath = rule.path
        formDomains = rule.domains.joined(separator: "\n")
        formKeepPath = rule.keepPath
        formRedirectRoot = rule.redirectRoot
        showSheet = true
    }

    private func submit() {
        var arguments: [String: Any] = [
            "websiteID": websiteId,
            "operate": editing == nil ? "create" : "edit",
            "enable": true,
            "name": formName.trimmingCharacters(in: .whitespaces),
            "type": formType,
            "redirect": formRedirect.isEmpty ? "301" : formRedirect,
            "keepPath": formKeepPath,
            "target": formTarget.trimmingCharacters(in: .whitespaces).isEmpty
                ? "http://"
                : formTarget.trimmingCharacters(in: .whitespaces),
        ]
        if formType == "domain" {
            arguments["domains"] = parsedDomains
        }
        if formType == "path" {
            arguments["path"] = formPath.trimmingCharacters(in: .whitespaces)
        }
        if formType == "404" {
            arguments["redirectRoot"] = formRedirectRoot
        }
        ChannelManager.shared.invokeDataMethod("updateWebsiteRedirect", arguments: arguments) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showSheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetch() }
            }
        }
    }

    private func ruleArguments(_ rule: WebsiteRedirectRow, operate: String, enable: Bool) -> [String: Any] {
        var arguments: [String: Any] = [
            "websiteID": websiteId,
            "operate": operate,
            "enable": enable,
            "name": rule.name,
            "type": rule.type,
            "redirect": rule.redirect.isEmpty ? "301" : rule.redirect,
            "target": rule.target.isEmpty ? "http://" : rule.target,
            "keepPath": rule.keepPath,
            "redirectRoot": rule.redirectRoot,
        ]
        if rule.type == "domain" {
            arguments["domains"] = rule.domains
        }
        if rule.type == "path" {
            arguments["path"] = rule.path
        }
        return arguments
    }

    private func toggle(_ rule: WebsiteRedirectRow) {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteRedirect",
            arguments: ruleArguments(rule, operate: rule.enable ? "disable" : "enable",
                                     enable: !rule.enable)
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                fetch()
            }
        }
    }

    private func confirmDelete() {
        guard let rule = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteRedirect",
            arguments: ruleArguments(rule, operate: "delete", enable: rule.enable)
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("hostRedirectDeleted", fallback: "Redirect deleted")
                    : translations.get("hostRedirectDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteRedirects",
            arguments: ["websiteID": websiteId]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                redirects = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return WebsiteRedirectRow(
                        name: name,
                        type: item["type"] as? String ?? "",
                        domains: (item["domains"] as? [Any])?.compactMap { $0 as? String } ?? [],
                        path: item["path"] as? String ?? "",
                        redirect: item["redirect"] as? String ?? "",
                        target: item["target"] as? String ?? "",
                        keepPath: item["keepPath"] as? Bool ?? true,
                        redirectRoot: item["redirectRoot"] as? Bool ?? false,
                        enable: item["enable"] as? Bool ?? true
                    )
                }
            }
        }
    }

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "domain":
            return translations.get("hostRedirectTypeDomain", fallback: "Domain")
        case "path":
            return translations.get("hostRedirectTypePath", fallback: "Path")
        case "404":
            return "404"
        default:
            return type
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

/// 伪静态：方案选择与规则内容编辑。
struct WebsiteRewriteView: View {
    let websiteId: Int
    @EnvironmentObject var translations: TranslationsManager

    @State private var mode = "current"
    @State private var content = ""
    @State private var isLoading = false
    @State private var toastText: String?

    private let modes = [
        "current", "default", "wordpress", "wp2", "typecho", "typecho2",
        "thinkphp", "yii2", "laravel5", "discuz", "discuzx", "discuzx2",
        "discuzx3", "EduSoho", "EmpireCMS", "ShopWind", "crmeb", "dabr",
        "dbshop", "dedecms", "drupal", "ecshop", "emlog", "maccms", "mvc",
        "niushop", "phpcms", "sablog", "seacms", "shopex", "zblog",
    ]

    var body: some View {
        VStack(spacing: 0) {
            if isLoading && content.isEmpty {
                LoadingView()
            } else {
                Form {
                    Section {
                        Picker(translations.get("hostRewriteMode", fallback: "Mode"),
                               selection: $mode) {
                            ForEach(modes, id: \.self) { name in
                                Text(modeLabel(name)).tag(name)
                            }
                        }
                    } footer: {
                        Text(translations.get("hostRewriteHelper2",
                                              fallback: "Changing rewrite rules may affect site access."))
                            .font(.footnote)
                    }
                    Section(translations.get("websitesRewriteHint", fallback: "Rewrite content")) {
                        TextEditor(text: $content)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 260)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
            }
        }
        .navigationTitle(translations.get("websitesTabRewrite", fallback: "Rewrite"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    save()
                } label: {
                    Label(translations.get("hostRewriteSaveAndReload", fallback: "Save and reload"),
                          systemImage: "square.and.arrow.down")
                }
                .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .operationNotice(toastText)
        .onChange(of: mode) { _ in
            fetch()
        }
        .onAppear {
            if content.isEmpty {
                fetch()
            }
        }
    }

    private func modeLabel(_ name: String) -> String {
        name == "current"
            ? translations.get("hostRewriteCurrent", fallback: "Current")
            : name
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteRewrite",
            arguments: ["websiteID": websiteId, "name": mode]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any] else {
                    content = ""
                    return
                }
                content = dict["content"] as? String ?? ""
            }
        }
    }

    private func save() {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteRewrite",
            arguments: ["websiteID": websiteId, "name": mode, "content": content]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("hostRewriteSaved", fallback: "Rewrite saved")
                    : translations.get("hostRewriteSaveFailed", fallback: "Save failed"))
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
