import AppleSharedUI
import SwiftUI

struct WebsiteDetailData {
    let websiteId: Int
    let alias: String
    let primaryDomain: String
    let type: String
    let status: String
    let remark: String
    let group: String
    let domains: [WebsiteDetailDomain]
}

struct WebsiteDetailDomain: Identifiable {
    let domainId: Int?
    let domain: String
    let port: Int?
    let ssl: Bool

    var id: String { "\(domain):\(port ?? 0)" }
}

struct WebsiteProxyRow: Identifiable {
    let name: String
    let match: String
    let proxyPass: String
    let enable: Bool

    var id: String { name }
}

struct WebsiteCertificateRow: Identifiable {
    let certificateId: Int
    let primaryDomain: String
    let status: String
    let expireDate: String

    var id: Int { certificateId }

    init(payload: [String: Any]) {
        certificateId = payload["id"] as? Int ?? 0
        primaryDomain = payload["primaryDomain"] as? String ?? ""
        status = payload["status"] as? String ?? ""
        expireDate = payload["expireDate"] as? String ?? ""
    }
}

/// macOS 网站配置中心：概览、域名、HTTPS、代理、重定向、伪静态、
/// CORS、防盗链、认证与证书。
struct WebsiteDetailView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let website: WebsiteModel

    @State private var section = ProcessInfo.processInfo.environment["ONEPANEL_WEBSITE_TAB"]
        ?? "overview"
    @State private var detail: WebsiteDetailData?
    @State private var isLoading = true
    @State private var loadError: String?
    @State private var actionError: String?
    @State private var statusMessage: String?

    @State private var httpsEnable = false
    @State private var httpsSSLId: Int?
    @State private var httpsSSLName = ""
    @State private var httpsLoaded = false
    @State private var httpsHTTPConfig = "HTTP"
    @State private var httpsHSTS = false
    @State private var httpsHSTSSubdomains = false
    @State private var httpsHTTP3 = false
    @State private var certificates: [WebsiteCertificateRow] = []
    @State private var isSavingHttps = false

    @State private var newDomain = ""
    @State private var newDomainPort = "80"

    @State private var proxies: [WebsiteProxyRow] = []
    @State private var proxiesLoaded = false
    @State private var pendingProxyAction: WebsiteProxyAction?
    @State private var proxyEditor: WebsiteProxyEditor?

    private var websiteId: Int {
        detail?.websiteId ?? Int(website.originalId) ?? 0
    }

    var body: some View {
        Group {
            if isLoading && detail == nil {
                LoadingView()
            } else if let detail {
                content(detail)
            } else {
                ErrorView(message: loadError ?? translations.get("commonLoadFailedTitle",
                                                                 fallback: "Failed to load")) {
                    Task { await load() }
                }
            }
        }
        .navigationTitle(detail?.primaryDomain ?? website.primaryDomain)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(translations.get("commonClose", fallback: "Close")) {
                    dismiss()
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    ForEach(Self.sections, id: \.key) { item in
                        Button {
                            section = item.key
                        } label: {
                            if section == item.key {
                                Label(sectionTitle(item.key), systemImage: "checkmark")
                            } else {
                                Text(sectionTitle(item.key))
                            }
                        }
                    }
                } label: {
                    Label(sectionTitle(section), systemImage: "square.grid.2x2")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
            }
        }
        .sheet(item: $proxyEditor) { editor in
            WebsiteProxyFormView(websiteId: websiteId, editor: editor) {
                Task { await loadProxies() }
            }
        }
        .confirmationDialog(
            proxyPendingTitle,
            isPresented: Binding(
                get: { pendingProxyAction != nil },
                set: { if !$0 { pendingProxyAction = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let action = pendingProxyAction {
                Button(proxyPendingButton(action),
                       role: action.isDestructive ? .destructive : nil) {
                    run(action)
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                    pendingProxyAction = nil
                }
            }
        } message: {
            Text(proxyPendingMessage)
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
        .overlay(alignment: .bottom) {
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.thinMaterial, in: Capsule())
                    .padding(20)
            }
        }
        .task {
            await load()
        }
    }

    private func content(_ detail: WebsiteDetailData) -> some View {
        VStack(spacing: 0) {
            switch section {
            case "domains":
                domainsContent
            case "https":
                httpsContent
            case "proxies":
                proxiesContent
            case "redirects":
                WebsiteRedirectsSection(websiteId: websiteId)
            case "rewrite":
                WebsiteRewriteSection(websiteId: websiteId, siteName: detail.alias)
            case "cors":
                WebsiteCorsSection(websiteId: websiteId)
            case "cache":
                WebsiteProxyCacheSection(websiteId: websiteId)
            case "realip":
                WebsiteRealIPSection(websiteId: websiteId)
            case "loadbalance":
                WebsiteLoadBalancerListView(
                    channel: MacOSDataChannel(channelManager: .shared),
                    websiteID: websiteId
                )
            case "stream":
                WebsiteStreamSection(websiteId: websiteId)
            case "leech":
                WebsiteLeechSection(websiteId: websiteId)
            case "auth":
                WebsiteAuthSection(websiteId: websiteId)
            case "certificates":
                WebsiteCertificatesSection()
            default:
                overviewContent(detail)
            }
        }
    }

    private func overviewContent(_ detail: WebsiteDetailData) -> some View {
        List {
            Section(translations.get("websitesDetailInfoTitle", fallback: "Site Info")) {
                InfoLine(label: translations.get("websitesPrimaryDomainLabel",
                                                 fallback: "Primary Domain"),
                         value: detail.primaryDomain)
                InfoLine(label: translations.get("websitesAliasLabel", fallback: "Alias"),
                         value: detail.alias)
                InfoLine(label: translations.get("websitesTypeLabel", fallback: "Type"),
                         value: detail.type)
                InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                         value: detail.status)
                InfoLine(label: translations.get("websitesGroupLabel", fallback: "Group"),
                         value: detail.group)
                if !detail.remark.isEmpty {
                    InfoLine(label: translations.get("websitesRemarkLabel", fallback: "Remark"),
                             value: detail.remark)
                }
                InfoLine(label: translations.get("websitesTabSsl", fallback: "SSL"),
                         value: httpsEnable
                            ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                            : translations.get("systemSettingsDisabled", fallback: "Disabled"))
            }

            Section(translations.get("websitesDetailActionsTitle", fallback: "Quick actions")) {
                Button {
                    Task { await toggleWebsiteStatus() }
                } label: {
                    Label(detail.status.lowercased() == "running"
                          ? translations.get("commonStop", fallback: "Stop")
                          : translations.get("commonStart", fallback: "Start"),
                          systemImage: detail.status.lowercased() == "running"
                            ? "stop.fill" : "play.fill")
                }
                Button {
                    section = "https"
                } label: {
                    Label(translations.get("websitesHttpsTitle", fallback: "HTTPS"),
                          systemImage: "lock.shield")
                }
                Button(role: .destructive) {
                    Task { await deleteWebsite() }
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            }
        }
        .listStyle(.inset)
    }

    private var domainsContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                TextField(translations.get("websitesDomainLabel", fallback: "Domain"),
                          text: $newDomain)
                    .textFieldStyle(.roundedBorder)
                TextField(translations.get("websitesPortLabel", fallback: "Port"),
                          text: $newDomainPort)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                Button {
                    Task { await addDomain() }
                } label: {
                    Label(translations.get("websitesDomainAddAction", fallback: "Add domain"),
                          systemImage: "plus")
                }
                .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(16)

            let domains = detail?.domains ?? []
            if domains.isEmpty {
                EmptyStateView(icon: "globe",
                               message: translations.get("websitesDomainsEmpty",
                                                         fallback: "No domains"))
            } else {
                List {
                    Section(translations.get("websitesTabDomains", fallback: "Domains")) {
                        ForEach(domains) { domain in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(domain.domain)
                                    Text(domain.port.map { ":\($0)" } ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if domain.ssl {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.green)
                                }
                                Button(role: .destructive) {
                                    Task { await deleteDomain(domain) }
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
            }
        }
    }

    private var httpsContent: some View {
        Form {
            Section {
                Toggle(translations.get("websitesHttpsEnableLabel", fallback: "Enable HTTPS"),
                       isOn: $httpsEnable)
                Picker(translations.get("websitesHttpsCertificateLabel", fallback: "Certificate"),
                       selection: Binding(
                        get: { httpsSSLId ?? 0 },
                        set: { httpsSSLId = $0 > 0 ? $0 : nil }
                       )) {
                    Text(translations.get("websitesHttpsNoCertificate", fallback: "Not bound"))
                        .tag(0)
                    ForEach(certificates) { certificate in
                        Text("\(certificate.primaryDomain) (\(certificate.status))")
                            .tag(certificate.certificateId)
                    }
                }
                Picker(translations.get("websitesHttpsHTTPConfigLabel", fallback: "HTTP"),
                       selection: $httpsHTTPConfig) {
                    Text(translations.get("websitesHttpsHTTPConfigHTTP", fallback: "HTTP"))
                        .tag("HTTP")
                    Text(translations.get("websitesHttpsHTTPConfigHTTPS", fallback: "HTTPS"))
                        .tag("HTTPS")
                }
            } footer: {
                if httpsSSLId == nil {
                    Text(translations.get("websitesHttpsCertificateRequired",
                                          fallback: "Bind a certificate before enabling HTTPS"))
                        .font(.caption)
                }
            }
            Section(translations.get("websitesHttpsAdvancedTitle", fallback: "Advanced")) {
                Toggle("HSTS", isOn: $httpsHSTS)
                Toggle(translations.get("websitesHttpsHstsSubdomains",
                                        fallback: "Include subdomains"),
                       isOn: $httpsHSTSSubdomains)
                Toggle("HTTP/3", isOn: $httpsHTTP3)
            }
            Section {
                Button {
                    Task { await saveHTTPS() }
                } label: {
                    if isSavingHttps {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(translations.get("commonSave", fallback: "Save"))
                    }
                }
                .disabled(isSavingHttps || (httpsEnable && httpsSSLId == nil))
            }
        }
        .formStyle(.grouped)
        .task {
            if !httpsLoaded {
                await loadHTTPS()
                await loadCertificates()
            }
        }
    }

    private var proxiesContent: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    proxyEditor = WebsiteProxyEditor.blank
                } label: {
                    Label(translations.get("websitesProxyCreateAction", fallback: "Add proxy"),
                          systemImage: "plus")
                }
                Spacer()
                Button {
                    Task { await loadProxies() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
            }
            .padding(16)

            if proxies.isEmpty {
                EmptyStateView(icon: "arrow.triangle.branch",
                               message: translations.get("websitesProxyEmpty",
                                                         fallback: "No proxy rules"))
            } else {
                List {
                    Section(translations.get("websitesTabProxy", fallback: "Reverse Proxy")) {
                        ForEach(proxies) { proxy in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text(proxy.name).font(.subheadline.weight(.medium))
                                        StatusBadge(
                                            text: proxy.enable
                                                ? translations.get("systemSettingsEnabled",
                                                                   fallback: "Enabled")
                                                : translations.get("systemSettingsDisabled",
                                                                   fallback: "Disabled"),
                                            color: proxy.enable ? .green : .gray
                                        )
                                    }
                                    Text("\(proxy.match) → \(proxy.proxyPass)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                Spacer()
                                Button {
                                    Task { await toggleProxy(proxy) }
                                } label: {
                                    Image(systemName: proxy.enable ? "pause.circle" : "play.circle")
                                }
                                .buttonStyle(.borderless)
                                Button {
                                    proxyEditor = WebsiteProxyEditor(proxy: proxy)
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                                Button(role: .destructive) {
                                    pendingProxyAction = .delete(proxy)
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
            }
        }
        .task {
            if !proxiesLoaded {
                await loadProxies()
            }
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteDetail",
                arguments: ["id": websiteId > 0 ? websiteId : Int(website.originalId) ?? 0]
            )
            let dict = raw as? [String: Any] ?? [:]
            let domains = (dict["domains"] as? [[String: Any]] ?? []).map { item in
                WebsiteDetailDomain(
                    domainId: item["id"] as? Int,
                    domain: item["domain"] as? String ?? "",
                    port: item["port"] as? Int,
                    ssl: item["ssl"] as? Bool ?? false
                )
            }
            detail = WebsiteDetailData(
                websiteId: dict["id"] as? Int ?? Int(website.originalId) ?? 0,
                alias: dict["alias"] as? String ?? "",
                primaryDomain: dict["primaryDomain"] as? String ?? website.primaryDomain,
                type: dict["type"] as? String ?? "",
                status: dict["status"] as? String ?? website.status,
                remark: dict["remark"] as? String ?? website.remark,
                group: dict["group"] as? String ?? "",
                domains: domains
            )
            loadError = nil
            await loadHTTPS()
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    private func loadHTTPS() async {
        guard websiteId > 0 else { return }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteHttpsConfig",
                arguments: ["id": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            httpsEnable = dict["enable"] as? Bool ?? false
            let ssl = dict["SSL"] as? [String: Any]
            let sslId = ssl?["id"] as? Int ?? 0
            httpsSSLId = sslId > 0 ? sslId : nil
            httpsSSLName = ssl?["primaryDomain"] as? String ?? ""
            httpsHTTPConfig = dict["httpConfig"] as? String ?? "HTTP"
            httpsHSTS = dict["hsts"] as? Bool ?? false
            httpsHSTSSubdomains = dict["hstsIncludeSubDomains"] as? Bool ?? false
            httpsHTTP3 = dict["http3"] as? Bool ?? false
            httpsLoaded = true
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func loadCertificates() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteCertificates"
            )
            certificates = (raw as? [[String: Any]] ?? []).map(WebsiteCertificateRow.init)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func saveHTTPS() async {
        isSavingHttps = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteHttpsConfig",
                arguments: [
                    "websiteId": websiteId,
                    "enable": httpsEnable,
                    "websiteSSLId": httpsSSLId ?? 0,
                    "type": "existed",
                    "httpConfig": httpsHTTPConfig,
                    "sslProtocol": ["TLSv1.1", "TLSv1.2", "TLSv1.3"],
                    "algorithm": "default",
                    "hsts": httpsHSTS,
                    "hstsIncludeSubDomains": httpsHSTSSubdomains,
                    "http3": httpsHTTP3,
                ]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            showStatus(translations.get("commonSaveSuccess", fallback: "Saved"))
            await loadHTTPS()
        } catch {
            actionError = error.localizedDescription
        }
        isSavingHttps = false
    }

    private func addDomain() async {
        let name = newDomain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "addWebsiteDomains",
                arguments: [
                    "websiteID": websiteId,
                    "domains": [["domain": name,
                                 "port": Int(newDomainPort.trimmingCharacters(in: .whitespaces)) ?? 80,
                                 "ssl": false]],
                ]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            newDomain = ""
            await load()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteDomain(_ domain: WebsiteDetailDomain) async {
        guard let domainId = domain.domainId else { return }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteWebsiteDomain",
                arguments: ["id": domainId]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            await load()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func loadProxies() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteProxies",
                arguments: ["id": websiteId]
            )
            proxies = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                return WebsiteProxyRow(
                    name: name,
                    match: item["match"] as? String ?? "",
                    proxyPass: item["proxyPass"] as? String ?? "",
                    enable: item["enable"] as? Bool ?? true
                )
            }
            proxiesLoaded = true
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func toggleProxy(_ proxy: WebsiteProxyRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteProxyStatus",
                arguments: [
                    "id": websiteId,
                    "name": proxy.name,
                    "status": proxy.enable ? "disable" : "enable",
                ]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            await loadProxies()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func toggleWebsiteStatus() async {
        guard let detail else { return }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "toggleWebsiteStatus",
                arguments: ["id": websiteId, "currentStatus": detail.status]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            await load()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func deleteWebsite() async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteWebsite",
                arguments: ["id": websiteId]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            dismiss()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func run(_ action: WebsiteProxyAction) {
        pendingProxyAction = nil
        Task {
            switch action {
            case .delete(let proxy):
                await deleteProxy(proxy)
            }
        }
    }

    private func deleteProxy(_ proxy: WebsiteProxyRow) async {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "deleteWebsiteProxy",
                arguments: ["id": websiteId, "name": proxy.name]
            )
            guard success(raw) else {
                actionError = errorText(raw)
                return
            }
            await loadProxies()
        } catch {
            actionError = error.localizedDescription
        }
    }

    private func success(_ raw: Any?) -> Bool {
        (raw as? [String: Any])?["success"] as? Bool ?? false
    }

    private func errorText(_ raw: Any?) -> String {
        (raw as? [String: Any])?["error"] as? String
            ?? translations.get("commonOperationFailed", fallback: "Operation failed")
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }

    private var proxyPendingTitle: String {
        guard let action = pendingProxyAction else { return "" }
        switch action {
        case .delete:
            return translations.get("websitesProxyDeleteAction", fallback: "Delete proxy")
        }
    }

    private var proxyPendingMessage: String {
        guard let action = pendingProxyAction else { return "" }
        switch action {
        case .delete(let proxy):
            return proxy.name
        }
    }

    private func proxyPendingButton(_ action: WebsiteProxyAction) -> String {
        switch action {
        case .delete:
            return translations.get("commonDelete", fallback: "Delete")
        }
    }

    private func sectionTitle(_ key: String) -> String {
        switch key {
        case "overview": return translations.get("vmTabOverview", fallback: "Overview")
        case "domains": return translations.get("websitesTabDomains", fallback: "Domains")
        case "https": return translations.get("websitesTabSsl", fallback: "SSL")
        case "proxies": return translations.get("websitesTabProxy", fallback: "Reverse Proxy")
        case "redirects": return translations.get("websiteRedirectTitle", fallback: "Redirect")
        case "rewrite": return translations.get("websiteRewriteTitle", fallback: "Rewrite")
        case "cors": return translations.get("websiteCorsTitle", fallback: "CORS")
        case "cache": return translations.get("websitesCacheTitle", fallback: "Proxy Cache")
        case "realip": return translations.get("websitesRealIpTitle", fallback: "Real IP")
        case "loadbalance": return translations.get("websitesLoadBalanceTitle", fallback: "Load Balance")
        case "stream": return translations.get("websitesStreamTitle", fallback: "TCP/UDP Forwarding")
        case "leech": return translations.get("websiteLeechTitle", fallback: "Anti-Leech")
        case "auth": return translations.get("websiteAuthTitle", fallback: "Authentication")
        case "certificates": return translations.get("websiteCertificatesTitle", fallback: "Certificates")
        default: return key
        }
    }

    private static let sections: [(key: String, title: String)] = [
        ("overview", ""),
        ("domains", ""),
        ("https", ""),
        ("proxies", ""),
        ("redirects", ""),
        ("rewrite", ""),
        ("cors", ""),
        ("cache", ""),
        ("realip", ""),
        ("loadbalance", ""),
        ("stream", ""),
        ("leech", ""),
        ("auth", ""),
        ("certificates", ""),
    ]
}

enum WebsiteProxyAction: Identifiable {
    case delete(WebsiteProxyRow)

    var id: String {
        switch self {
        case .delete(let proxy): return "delete-\(proxy.name)"
        }
    }

    var isDestructive: Bool { true }
}

struct WebsiteProxyEditor: Identifiable {
    let id = UUID()
    let name: String
    let match: String
    let proxyPass: String
    let isNew: Bool

    static let blank = WebsiteProxyEditor(name: "", match: "/", proxyPass: "", isNew: true)

    init(name: String, match: String, proxyPass: String, isNew: Bool) {
        self.name = name
        self.match = match
        self.proxyPass = proxyPass
        self.isNew = isNew
    }

    init(proxy: WebsiteProxyRow) {
        self.init(name: proxy.name,
                  match: proxy.match,
                  proxyPass: proxy.proxyPass,
                  isNew: false)
    }
}

/// 代理创建与编辑表单。
struct WebsiteProxyFormView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let websiteId: Int
    let editor: WebsiteProxyEditor
    let onSaved: () -> Void

    @State private var name: String
    @State private var match: String
    @State private var address: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(websiteId: Int, editor: WebsiteProxyEditor, onSaved: @escaping () -> Void) {
        self.websiteId = websiteId
        self.editor = editor
        self.onSaved = onSaved
        _name = State(initialValue: editor.name)
        _match = State(initialValue: editor.match)
        _address = State(initialValue: Self.stripProtocol(editor.proxyPass))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(translations.get("websitesProxyNameLabel", fallback: "Name"),
                          text: $name)
                TextField(translations.get("websitesProxyMatchLabel", fallback: "Path"),
                          text: $match)
                TextField(translations.get("websitesProxyAddressLabel", fallback: "Target address"),
                          text: $address)
            }
            .formStyle(.grouped)
            .navigationTitle(editor.isNew
                             ? translations.get("websitesProxyCreateAction", fallback: "Add proxy")
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
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty
                              || match.trimmingCharacters(in: .whitespaces).isEmpty
                              || address.trimmingCharacters(in: .whitespaces).isEmpty)
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
            .frame(minWidth: 460, minHeight: 300)
        }
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteProxy",
                arguments: [
                    "websiteID": websiteId,
                    "operate": editor.isNew ? "create" : "edit",
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "match": match.trimmingCharacters(in: .whitespacesAndNewlines),
                    "proxyProtocol": "http://",
                    "proxyAddress": address.trimmingCharacters(in: .whitespacesAndNewlines),
                ]
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

    private static func stripProtocol(_ value: String) -> String {
        if value.hasPrefix("http://") { return String(value.dropFirst(7)) }
        if value.hasPrefix("https://") { return String(value.dropFirst(8)) }
        return value
    }
}