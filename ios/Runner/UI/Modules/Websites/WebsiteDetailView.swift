import SwiftUI

/// 网站详情：站点信息与域名列表，工具栏刷新。
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
    let domain: String
    let port: Int?
    let ssl: Bool

    var id: String { "\(domain):\(port ?? 0)" }
}

class WebsiteDetailViewModel: ObservableObject {
    @Published var detail: WebsiteDetailData?
    @Published var isLoading = false

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
}

struct WebsiteDetailView: View {
    let websiteId: Int
    @StateObject private var viewModel = WebsiteDetailViewModel()
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
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

                    Section(translations.get("websitesTabDomains", fallback: "Domains")) {
                        ForEach(detail.domains) { domain in
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
        .navigationTitle(translations.get("websitesDetailTitle", fallback: "Website"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    viewModel.fetch(id: websiteId)
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.fetch(id: websiteId)
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
