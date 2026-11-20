import SwiftUI
import AppleSharedUI

/// 网站详情：概览、域名与日志三个分栏。
/// 上游详情缺少日志时，日志分栏按 `/websites/log/search` 拉取访问日志。
struct WebsiteDetailData {
    let alias: String
    let primaryDomain: String
    let type: String
    let status: String
    let remark: String
    let group: String
    let domains: [WebsiteDetailDomain]
}

struct WebsiteDetailDomain: Identifiable {
    let id: Int?
    let domain: String
    let port: Int?
    let ssl: Bool

    var rowID: String { "\(domain):\(port ?? 0)" }
}

/// 反向代理规则行。
struct WebsiteProxyRow: Identifiable {
    let name: String
    let match: String
    let proxyPass: String
    let enable: Bool

    var id: String { name }
}

class WebsiteDetailViewModel: ObservableObject {
    @Published var detail: WebsiteDetailData?
    @Published var isLoading = false
    @Published var logs: String = ""
    @Published var isLoadingLogs = false
    @Published private(set) var logsEnable = true
    @Published var httpsEnable = false
    @Published var httpsSSLId: Int?
    @Published var httpsConfigLoaded = false

    func fetch(id: Int) {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteDetail",
            arguments: ["id": id]
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dict = result as? [String: Any] else { return }
                let domains = (dict["domains"] as? [[String: Any]] ?? []).map { item in
                    WebsiteDetailDomain(
                        id: item["id"] as? Int,
                        domain: item["domain"] as? String ?? "",
                        port: item["port"] as? Int,
                        ssl: item["ssl"] as? Bool ?? false
                    )
                }
                self?.detail = WebsiteDetailData(
                    alias: dict["alias"] as? String ?? "",
                    primaryDomain: dict["primaryDomain"] as? String ?? "",
                    type: dict["type"] as? String ?? "",
                    status: dict["status"] as? String ?? "",
                    remark: dict["remark"] as? String ?? "",
                    group: dict["group"] as? String ?? "",
                    domains: domains
                )
            }
        }
    }

    /// HTTPS 配置（getWebsiteHttpsConfig 通道，SSL 对象存在才允许开启）。
    func fetchHttpsConfig(id: Int) {
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteHttpsConfig",
            arguments: ["id": id]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.httpsConfigLoaded = true
                guard let dict = result as? [String: Any] else { return }
                self.httpsEnable = dict["enable"] as? Bool ?? false
                let ssl = dict["SSL"] as? [String: Any]
                let sslId = ssl?["id"] as? Int ?? 0
                self.httpsSSLId = sslId > 0 ? sslId : nil
            }
        }
    }

    /// 开关 HTTPS（updateWebsiteHttpsConfig 通道）。开启需要已绑定证书。
    func updateHttps(id: Int, enable: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard !enable || httpsSSLId != nil else {
            completion(false, nil)
            return
        }
        var args: [String: Any] = ["websiteId": id, "enable": enable]
        if let sslId = httpsSSLId, enable {
            args["websiteSSLId"] = sslId
        }
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteHttpsConfig",
            arguments: args
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                completion(success, dict?["error"] as? String)
            }
        }
    }

    /// 添加域名（addWebsiteDomains 通道）。
    func addDomain(websiteId: Int, domain: String, port: Int,
                   completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "addWebsiteDomains",
            arguments: [
                "websiteID": websiteId,
                "domains": [["domain": domain, "port": port, "ssl": false]],
            ]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }

    /// 删除域名（deleteWebsiteDomain 通道）。
    func deleteDomain(id: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteWebsiteDomain",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }

    /// 访问日志（getWebsiteLogs 通道，服务端按行分页返回 content）。
    func fetchLogs(id: Int, logType: String = "access.log") {
        guard !isLoadingLogs else { return }
        isLoadingLogs = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteLogs",
            arguments: ["id": id, "logType": logType, "page": 1, "pageSize": 300]
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoadingLogs = false
                guard let dict = result as? [String: Any] else {
                    self.logs = ""
                    return
                }
                self.logsEnable = dict["enable"] as? Bool ?? true
                self.logs = dict["content"] as? String ?? ""
            }
        }
    }
}

struct WebsiteDetailView: View {
    let websiteId: Int
    @StateObject private var viewModel = WebsiteDetailViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var tab = "overview"
    @State private var toastText: String?
    @State private var showAddDomainSheet = false
    @State private var newDomain = ""
    @State private var newDomainPort = "80"
    @State private var domainToDelete: WebsiteDetailDomain?
    @State private var proxies: [WebsiteProxyRow] = []
    @State private var isLoadingProxies = false
    @State private var showProxySheet = false
    @State private var proxyName = ""
    @State private var proxyMatch = "/"
    @State private var proxyAddress = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker(translations.get("websitesDetailTitle", fallback: "Website"), selection: $tab) {
                Text(translations.get("websitesTabOverview", fallback: "Overview")).tag("overview")
                Text(translations.get("websitesTabDomains", fallback: "Domains")).tag("domains")
                Text(translations.get("websitesTabProxy", fallback: "Proxy")).tag("proxy")
                Text(translations.get("containerTabLogs", fallback: "Logs")).tag("logs")
                Text(translations.get("websitesTabConfig", fallback: "Configuration")).tag("config")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "domains":
                domainsContent
            case "proxy":
                proxiesContent
            case "logs":
                logsContent
            case "config":
                WebsiteConfigHubView(websiteId: websiteId)
            default:
                overviewContent
            }
        }
        .navigationTitle(translations.get("websitesDetailTitle", fallback: "Website"))
        .navigationBarTitleDisplayMode(.inline)
        .operationNotice(toastText)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                if tab == "domains" {
                    Button {
                        newDomain = ""
                        newDomainPort = "80"
                        showAddDomainSheet = true
                    } label: {
                        Label(translations.get("websitesDomainAddTitle", fallback: "Add domain"),
                              systemImage: "plus")
                    }
                }
                if tab == "proxy" {
                    Button {
                        proxyName = ""
                        proxyMatch = "/"
                        proxyAddress = ""
                        showProxySheet = true
                    } label: {
                        Label(translations.get("hostProxyAdd", fallback: "Add proxy"),
                              systemImage: "plus")
                    }
                }
                Button {
                    if tab == "logs" {
                        viewModel.fetchLogs(id: websiteId)
                    } else if tab == "proxy" {
                        fetchProxies()
                    } else {
                        viewModel.fetch(id: websiteId)
                    }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isLoadingLogs)
            }
        }
        .sheet(isPresented: $showAddDomainSheet) {
            addDomainSheet
        }
        .sheet(isPresented: $showProxySheet) {
            proxySheet
        }
        .confirmationDialog(
            domainDeleteMessage,
            isPresented: Binding(
                get: { domainToDelete != nil },
                set: { if !$0 { domainToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteDomain()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                domainToDelete = nil
            }
        }
        .onAppear {
            viewModel.fetch(id: websiteId)
            viewModel.fetchHttpsConfig(id: websiteId)
            if ProcessInfo.processInfo.environment["ONEPANEL_WEBSITE_DETAIL_CONFIG"] == "1" {
                tab = "config"
            }
        }
        .onChange(of: tab) { newValue in
            if newValue == "logs" && viewModel.logs.isEmpty {
                viewModel.fetchLogs(id: websiteId)
            }
            if newValue == "proxy" && proxies.isEmpty {
                fetchProxies()
            }
        }
    }

    @ViewBuilder
    private var proxiesContent: some View {
        if isLoadingProxies && proxies.isEmpty {
            LoadingView()
        } else if proxies.isEmpty {
            EmptyStateView(
                icon: "arrow.left.arrow.right",
                message: translations.get("hostProxyEmpty", fallback: "No proxy rules")
            )
        } else {
            List {
                ForEach(proxies) { proxy in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(proxy.name)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            StatusBadge(
                                text: proxy.enable
                                    ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                    : translations.get("systemSettingsDisabled", fallback: "Disabled"),
                                color: proxy.enable ? .green : .gray
                            )
                        }
                        HStack(spacing: 12) {
                            Label(proxy.match, systemImage: "link")
                            Label("→ \(proxy.proxyPass)", systemImage: "arrow.right")
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteProxy(proxy)
                        } label: {
                            Label(translations.get("commonDelete", fallback: "Delete"),
                                  systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            toggleProxy(proxy)
                        } label: {
                            Label(
                                translations.get(proxy.enable ? "hostProxyDisable" : "commonEnable",
                                                 fallback: proxy.enable ? "Disable" : "Enable"),
                                systemImage: proxy.enable ? "pause.circle" : "play.circle"
                            )
                        }
                        .tint(proxy.enable ? .orange : .green)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                fetchProxies()
            }
        }
    }

    private var proxySheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("websitesProxyNameLabel", fallback: "Proxy Name"),
                              text: $proxyName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("hostProxyMatch", fallback: "Path"),
                              text: $proxyMatch)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("hostProxyAddressPlaceholder",
                                               fallback: "127.0.0.1:8080"),
                              text: $proxyAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } footer: {
                    Text(translations.get("hostProxyPassHelper",
                                          fallback: "The proxied site must be reachable."))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("hostProxyAdd", fallback: "Add proxy"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showProxySheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createProxy()
                    }
                    .disabled(proxyName.trimmingCharacters(in: .whitespaces).isEmpty
                              || proxyMatch.trimmingCharacters(in: .whitespaces).isEmpty
                              || proxyAddress.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func fetchProxies() {
        guard !isLoadingProxies else { return }
        isLoadingProxies = true
        ChannelManager.shared.invokeDataMethod(
            "getWebsiteProxies",
            arguments: ["id": websiteId]
        ) { result in
            DispatchQueue.main.async {
                isLoadingProxies = false
                guard let items = result as? [[String: Any]] else { return }
                proxies = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    return WebsiteProxyRow(
                        name: name,
                        match: item["match"] as? String ?? "",
                        proxyPass: item["proxyPass"] as? String ?? "",
                        enable: item["enable"] as? Bool ?? true
                    )
                }
            }
        }
    }

    private func createProxy() {
        let name = proxyName.trimmingCharacters(in: .whitespaces)
        let match = proxyMatch.trimmingCharacters(in: .whitespaces)
        let address = proxyAddress.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !match.isEmpty, !address.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteProxy",
            arguments: [
                "websiteID": websiteId,
                "operate": "create",
                "name": name,
                "match": match,
                "proxyProtocol": "http://",
                "proxyAddress": address,
                "enable": true,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showProxySheet = false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success { fetchProxies() }
            }
        }
    }

    private func toggleProxy(_ proxy: WebsiteProxyRow) {
        ChannelManager.shared.invokeDataMethod(
            "updateWebsiteProxyStatus",
            arguments: [
                "id": websiteId,
                "name": proxy.name,
                "status": proxy.enable ? "disable" : "enable",
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                fetchProxies()
            }
        }
    }

    private func deleteProxy(_ proxy: WebsiteProxyRow) {
        ChannelManager.shared.invokeDataMethod(
            "deleteWebsiteProxy",
            arguments: ["id": websiteId, "name": proxy.name]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetchProxies()
            }
        }
    }

    @ViewBuilder
    private var overviewContent: some View {
        if viewModel.isLoading && viewModel.detail == nil {
            LoadingView()
        } else if let detail = viewModel.detail {
            List {
                Section(translations.get("websitesDetailInfoTitle", fallback: "Site Info")) {
                    InfoLine(label: translations.get("websitesAliasLabel", fallback: "Alias"),
                             value: detail.alias)
                    InfoLine(label: translations.get("websitesPrimaryDomainLabel", fallback: "Primary Domain"),
                             value: detail.primaryDomain)
                    InfoLine(label: translations.get("websitesTypeLabel", fallback: "Type"),
                             value: typeLabel(detail.type))
                    InfoLine(label: translations.get("commonStatus", fallback: "Status"),
                             value: detail.status)
                    if !detail.group.isEmpty {
                        InfoLine(label: translations.get("websitesGroupLabel", fallback: "Group"),
                                 value: detail.group)
                    }
                    if !detail.remark.isEmpty {
                        InfoLine(label: translations.get("websitesRemarkLabel", fallback: "Remark"),
                                 value: detail.remark)
                    }
                }

                Section(translations.get("websitesTabSsl", fallback: "SSL")) {
                    Toggle(isOn: Binding(
                        get: { viewModel.httpsEnable },
                        set: { newValue in
                            updateHttps(newValue)
                        }
                    )) {
                        Label(translations.get("websiteSiteSslEnableHttpsLabel", fallback: "Enable HTTPS"),
                              systemImage: "lock.shield")
                    }
                    if !viewModel.httpsEnable && viewModel.httpsSSLId == nil {
                        Text(translations.get("websiteSiteSslNoCertificateBound", fallback: "No certificate bound"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(translations.get("websitesDetailActionsTitle", fallback: "Quick actions")) {
                    if let url = siteURL(detail) {
                        Link(destination: url) {
                            Label(translations.get("commonOpenAction", fallback: "Open"),
                                  systemImage: "safari")
                        }
                    }
                    let running = detail.status.lowercased() == "running"
                    Button {
                        toggleStatus(detail)
                    } label: {
                        Label(
                            translations.get(running ? "containerActionStop" : "containerActionStart",
                                             fallback: running ? "Stop" : "Start"),
                            systemImage: running ? "stop.fill" : "play.fill"
                        )
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.fetch(id: websiteId)
            }
        } else {
            EmptyStateView(
                icon: "globe",
                message: translations.get("websitesListEmptyTitle", fallback: "No websites")
            )
        }
    }

    /// 站点访问地址：主域名可直接打开；非 80 端口时按域名列表补端口。
    private func siteURL(_ detail: WebsiteDetailData) -> URL? {
        guard !detail.primaryDomain.isEmpty else { return nil }
        let port = detail.domains.first(where: { $0.domain == detail.primaryDomain })?.port ?? 80
        let suffix = port == 80 || port == 0 ? "" : ":\(port)"
        return URL(string: "http://\(detail.primaryDomain)\(suffix)")
    }

    private func toggleStatus(_ detail: WebsiteDetailData) {
        let running = detail.status.lowercased() == "running"
        ChannelManager.shared.invokeDataMethod(
            "toggleWebsiteStatus",
            arguments: ["id": websiteId, "currentStatus": running ? "running" : "stopped"]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonSaveSuccess", fallback: "Saved")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                viewModel.fetch(id: websiteId)
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

    @ViewBuilder
    private var domainsContent: some View {
        if let detail = viewModel.detail, !detail.domains.isEmpty {
            List {
                Section(translations.get("websitesTabDomains", fallback: "Domains")) {
                    ForEach(detail.domains, id: \.rowID) { domain in
                        HStack {
                            Text(domain.domain)
                            Spacer()
                            if let port = domain.port {
                                // 直接插值 Int 会被当成富文本按本地化处理并插入千位分隔符（8090 → 8,090）。
                                Text(String(port))
                                    .foregroundColor(.secondary)
                            }
                            Text(translations.get("websitesDomainSslLabel", fallback: "SSL"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: domain.ssl ? "checkmark.circle" : "minus.circle")
                                .foregroundStyle(domain.ssl ? Color.green : Color.secondary)
                                .accessibilityLabel(domain.ssl
                                    ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                    : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if domain.id != nil {
                                Button(role: .destructive) {
                                    domainToDelete = domain
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.fetch(id: websiteId)
            }
        } else {
            EmptyStateView(
                icon: "globe",
                message: translations.get("commonEmpty", fallback: "No data")
            )
        }
    }

    private var addDomainSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("websitesPrimaryDomainLabel", fallback: "Domain"),
                              text: $newDomain)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("websitesDomainPortLabel", fallback: "Port"),
                              text: $newDomainPort)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(translations.get("websitesDomainAddTitle", fallback: "Add domain"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showAddDomainSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        addDomain()
                    }
                    .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var domainDeleteMessage: String {
        let template = translations.get("websitesDomainDeleteMessage",
                                        fallback: "Delete domain {domain}?")
        return template.replacingOccurrences(of: "{domain}", with: domainToDelete?.domain ?? "")
    }

    private func addDomain() {
        let domain = newDomain.trimmingCharacters(in: .whitespaces)
        guard !domain.isEmpty else { return }
        let port = Int(newDomainPort.trimmingCharacters(in: .whitespaces)) ?? 80
        viewModel.addDomain(websiteId: websiteId, domain: domain, port: port) { success in
            showAddDomainSheet = false
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetch(id: websiteId)
        }
    }

    private func deleteDomain() {
        guard let domain = domainToDelete, let id = domain.id else { return }
        domainToDelete = nil
        viewModel.deleteDomain(id: id) { success in
            showToast(success
                ? translations.get("commonDeleted", fallback: "Deleted")
                : translations.get("commonDeleteFailed", fallback: "Delete failed"))
            viewModel.fetch(id: websiteId)
        }
    }

    private func updateHttps(_ enable: Bool) {
        viewModel.updateHttps(id: websiteId, enable: enable) { success, error in
            if success {
                showToast(translations.get("commonSaveSuccess", fallback: "Saved"))
            } else if enable && viewModel.httpsSSLId == nil {
                showToast(translations.get("websiteSiteSslNoCertificateBound", fallback: "No certificate bound"))
            } else {
                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                showToast(template.replacingOccurrences(of: "{error}", with: error ?? ""))
            }
            viewModel.fetchHttpsConfig(id: websiteId)
        }
    }

    @ViewBuilder
    private var logsContent: some View {
        if viewModel.isLoadingLogs && viewModel.logs.isEmpty {
            LoadingView()
        } else if !viewModel.logsEnable {
            EmptyStateView(
                icon: "doc.text",
                message: translations.get("containerLogsEmpty", fallback: "No logs")
            )
        } else if viewModel.logs.isEmpty {
            EmptyStateView(
                icon: "doc.text",
                message: translations.get("containerLogsEmpty", fallback: "No logs")
            )
        } else {
            ScrollView {
                Text(viewModel.logs)
                    .font(.system(.caption2, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
    }

    private func typeLabel(_ type: String) -> String {
        switch type {
        case "static":
            return translations.get("websitesLifecycleTypeStatic", fallback: "Static")
        case "proxy":
            return translations.get("websitesLifecycleTypeProxy", fallback: "Proxy")
        case "subsite":
            return translations.get("websitesLifecycleTypeSubsite", fallback: "Subsite")
        case "runtime":
            return translations.get("websitesLifecycleTypeRuntime", fallback: "Runtime")
        default:
            return type
        }
    }
}

