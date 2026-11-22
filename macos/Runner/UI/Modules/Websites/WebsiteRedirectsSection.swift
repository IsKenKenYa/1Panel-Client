import AppleSharedUI
import SwiftUI

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

    var sourceText: String {
        type == "domain" ? domains.joined(separator: ", ") : path
    }
}

/// 网站重定向：列表、创建、编辑、启停与删除。
struct WebsiteRedirectsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var redirects: [WebsiteRedirectRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var editor: WebsiteRedirectEditor?
    @State private var pendingDelete: WebsiteRedirectRow?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    editor = .blank
                } label: {
                    Label(translations.get("hostRedirectAdd", fallback: "Add redirect"),
                          systemImage: "plus")
                }
                Spacer()
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
            }
            .padding(16)

            Group {
                if isLoading && redirects.isEmpty {
                    LoadingView()
                } else if redirects.isEmpty {
                    EmptyStateView(icon: "arrow.turn.down.right",
                                   message: translations.get("hostRedirectEmpty",
                                                             fallback: "No redirect rules"))
                } else {
                    List {
                        Section(translations.get("websiteRedirectTitle", fallback: "Redirect")) {
                            ForEach(redirects) { rule in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(rule.name).font(.subheadline.weight(.medium))
                                            StatusBadge(
                                                text: rule.enable
                                                    ? translations.get("systemSettingsEnabled",
                                                                       fallback: "Enabled")
                                                    : translations.get("systemSettingsDisabled",
                                                                       fallback: "Disabled"),
                                                color: rule.enable ? .green : .gray
                                            )
                                        }
                                        Text(rule.sourceText.isEmpty ? rule.type : rule.sourceText)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                        if !rule.target.isEmpty {
                                            Text("\(rule.redirect) → \(rule.target)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                        }
                                    }
                                    Spacer()
                                    Button {
                                        Task { await toggle(rule) }
                                    } label: {
                                        Image(systemName: rule.enable ? "pause.circle" : "play.circle")
                                    }
                                    .buttonStyle(.borderless)
                                    Button {
                                        editor = WebsiteRedirectEditor(rule: rule)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .buttonStyle(.borderless)
                                    Button(role: .destructive) {
                                        pendingDelete = rule
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .listStyle(.inset)
                    .refreshable {
                        await load()
                    }
                }
            }
        }
        .sheet(item: $editor) { item in
            WebsiteRedirectFormView(websiteId: websiteId, editor: item) {
                Task { await load() }
            }
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
                Task {
                    if let rule = pendingDelete {
                        pendingDelete = nil
                        await delete(rule)
                    }
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
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
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteRedirects",
                arguments: ["websiteID": websiteId]
            )
            redirects = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                return WebsiteRedirectRow(
                    name: name,
                    type: item["type"] as? String ?? "",
                    domains: item["domains"] as? [String] ?? [],
                    path: item["path"] as? String ?? "",
                    redirect: item["redirect"] as? String ?? "",
                    target: item["target"] as? String ?? "",
                    keepPath: item["keepPath"] as? Bool ?? false,
                    redirectRoot: item["redirectRoot"] as? Bool ?? false,
                    enable: item["enable"] as? Bool ?? true
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func toggle(_ rule: WebsiteRedirectRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteRedirect",
                arguments: redirectArguments(
                    rule,
                    operate: rule.enable ? "disable" : "enable",
                    enable: !rule.enable
                )
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ rule: WebsiteRedirectRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteRedirect",
                arguments: redirectArguments(rule, operate: "delete", enable: rule.enable)
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                await load()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func redirectArguments(
        _ rule: WebsiteRedirectRow,
        operate: String,
        enable: Bool
    ) -> [String: Any] {
        var values: [String: Any] = [
            "websiteID": websiteId,
            "operate": operate,
            "enable": enable,
            "name": rule.name,
            "type": rule.type,
            "redirect": rule.redirect.isEmpty ? "301" : rule.redirect,
            "keepPath": rule.keepPath,
            "target": rule.target,
            "path": rule.path,
            "redirectRoot": rule.redirectRoot,
        ]
        if !rule.domains.isEmpty {
            values["domains"] = rule.domains
        }
        return values
    }
}

struct WebsiteRedirectEditor: Identifiable {
    let id = UUID()
    let rule: WebsiteRedirectRow?

    static let blank = WebsiteRedirectEditor(rule: nil)

    init(rule: WebsiteRedirectRow?) {
        self.rule = rule
    }
}

struct WebsiteRedirectFormView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let websiteId: Int
    let editor: WebsiteRedirectEditor
    let onSaved: () -> Void

    @State private var name: String
    @State private var type: String
    @State private var redirect: String
    @State private var target: String
    @State private var path: String
    @State private var domainsText: String
    @State private var keepPath: Bool
    @State private var redirectRoot: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(websiteId: Int, editor: WebsiteRedirectEditor, onSaved: @escaping () -> Void) {
        self.websiteId = websiteId
        self.editor = editor
        self.onSaved = onSaved
        let rule = editor.rule
        _name = State(initialValue: rule?.name ?? "")
        _type = State(initialValue: rule?.type.isEmpty == false ? rule!.type : "domain")
        _redirect = State(initialValue: rule?.redirect.isEmpty == false ? rule!.redirect : "301")
        _target = State(initialValue: rule?.target ?? "")
        _path = State(initialValue: rule?.path ?? "")
        _domainsText = State(initialValue: rule?.domains.joined(separator: "\n") ?? "")
        _keepPath = State(initialValue: rule?.keepPath ?? true)
        _redirectRoot = State(initialValue: rule?.redirectRoot ?? false)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                        .disabled(editor.rule != nil || type == "404")
                    Picker(translations.get("commonType", fallback: "Type"), selection: $type) {
                        Text(translations.get("hostRedirectTypeDomain", fallback: "Domain"))
                            .tag("domain")
                        Text(translations.get("hostRedirectTypePath", fallback: "Path"))
                            .tag("path")
                        Text("404").tag("404")
                    }
                    .disabled(editor.rule != nil)
                    Picker(translations.get("hostRedirectWay", fallback: "Way"),
                           selection: $redirect) {
                        Text("301").tag("301")
                        Text("302").tag("302")
                    }
                }
                Section {
                    if type == "domain" {
                        TextField(translations.get("hostRedirectDomainsPlaceholder",
                                                    fallback: "One domain per line"),
                                  text: $domainsText, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    if type == "path" {
                        TextField(translations.get("commonPath", fallback: "Path"), text: $path)
                    }
                    if type == "404" {
                        Toggle(translations.get("hostRedirectRoot",
                                                fallback: "Redirect site root to this rule"),
                               isOn: $redirectRoot)
                    }
                    if !(type == "404" && redirectRoot) {
                        TextField(translations.get("hostRedirectTarget", fallback: "Target URL"),
                                  text: $target)
                    }
                    if type != "404" {
                        Toggle(translations.get("hostRedirectKeepPath", fallback: "Keep path"),
                               isOn: $keepPath)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(editor.rule == nil
                             ? translations.get("hostRedirectAdd", fallback: "Add redirect")
                             : translations.get("hostRedirectEditTitle", fallback: "Edit redirect"))
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
            .frame(minWidth: 480, minHeight: 420)
        }
    }

    private var canSave: Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if !(type == "404" && redirectRoot)
            && target.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        if type == "domain" && parsedDomains.isEmpty { return false }
        if type == "path" && path.trimmingCharacters(in: .whitespaces).isEmpty { return false }
        return true
    }

    private var parsedDomains: [String] {
        domainsText
            .split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    private func save() async {
        isSaving = true
        var arguments: [String: Any] = [
            "websiteID": websiteId,
            "operate": editor.rule == nil ? "create" : "edit",
            "enable": true,
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "type": type,
            "redirect": redirect,
            "keepPath": keepPath,
            "target": target.trimmingCharacters(in: .whitespaces).isEmpty
                ? "http://" : target.trimmingCharacters(in: .whitespaces),
            "redirectRoot": redirectRoot,
        ]
        if type == "domain" { arguments["domains"] = parsedDomains }
        if type == "path" { arguments["path"] = path.trimmingCharacters(in: .whitespaces) }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteRedirect",
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onSaved()
                dismiss()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}