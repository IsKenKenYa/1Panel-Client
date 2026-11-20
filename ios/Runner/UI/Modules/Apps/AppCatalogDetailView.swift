import SwiftUI
import AppleSharedUI

/// 应用商店详情：简介、版本、架构与说明文档，顶部可直接安装。
struct AppCatalogDetailView: View {
    let appKey: String
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var translations: TranslationsManager
    @State private var installTarget: StoreApp?

    var body: some View {
        Group {
            if viewModel.catalogLoading && viewModel.catalogDetail == nil {
                LoadingView()
            } else if let detail = viewModel.catalogDetail {
                detailList(detail)
            } else {
                EmptyStateView(
                    icon: "shippingbox",
                    message: translations.get("appCatalogReadmeEmpty",
                                              fallback: "This app does not provide a readme.")
                )
            }
        }
        .navigationTitle(viewModel.catalogDetail?.name ?? appKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .apps)
                Button {
                    viewModel.fetchCatalogDetail(key: appKey)
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.catalogLoading)
            }
        }
        .sheet(item: $installTarget) { app in
            InstallAppSheet(viewModel: viewModel, app: app)
                .environmentObject(translations)
        }
        .onAppear {
            if viewModel.catalogDetail == nil {
                viewModel.fetchCatalogDetail(key: appKey)
            }
        }
    }

    private func detailList(_ detail: AppCatalogDetail) -> some View {
        List {
            Section {
                HStack(spacing: 14) {
                    AppIconView(url: detail.icon, size: 56, fallbackSymbol: "shippingbox.fill", fallbackColor: .indigo)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.name)
                            .font(.title3.weight(.semibold))
                        let summary = summaryText(detail)
                        if !summary.isEmpty {
                            Text(summary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
                if !detail.installed {
                    Button {
                        installTarget = StoreApp(
                            id: detail.id,
                            name: detail.name,
                            key: detail.key,
                            type: detail.type,
                            versions: detail.versions,
                            installed: detail.installed,
                            summary: summaryText(detail),
                            icon: detail.icon
                        )
                    } label: {
                        Label(translations.get("appStoreInstall", fallback: "Install"),
                              systemImage: "arrow.down.circle")
                    }
                } else {
                    Label(translations.get("appStoreInstalled", fallback: "Installed"),
                          systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            Section(translations.get("appDetailTitle", fallback: "App Details")) {
                InfoLine(label: translations.get("appCatalogVersionsLabel", fallback: "Versions"),
                         value: detail.versions.joined(separator: ", "))
                InfoLine(label: translations.get("appCatalogArchLabel", fallback: "Architectures"),
                         value: detail.architectures)
                if detail.memoryRequired > 0 {
                    InfoLine(label: translations.get("appCatalogMemoryLabel", fallback: "Memory Required"),
                             value: "\(detail.memoryRequired) MB")
                }
                InfoLine(label: translations.get("appCatalogGpuLabel", fallback: "GPU Support"),
                         value: detail.gpuSupport
                            ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                            : translations.get("systemSettingsDisabled", fallback: "Disabled"))
                if !detail.website.isEmpty, let url = URL(string: detail.website) {
                    Link(destination: url) {
                        InfoLinkRow(label: translations.get("appCatalogHomepageLabel", fallback: "Homepage"),
                                    value: detail.website)
                    }
                }
                if !detail.github.isEmpty, let url = URL(string: detail.github) {
                    Link(destination: url) {
                        InfoLinkRow(label: translations.get("appCatalogSourceLabel", fallback: "Source"),
                                    value: detail.github)
                    }
                }
            }

            Section(translations.get("appCatalogReadmeTitle", fallback: "Readme")) {
                if detail.readMe.isEmpty {
                    Text(translations.get("appCatalogReadmeEmpty", fallback: "This app does not provide a readme."))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Text(readmeAttributed(detail.readMe))
                        .font(.footnote)
                        .textSelection(.enabled)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.fetchCatalogDetail(key: appKey)
        }
    }

    private func summaryText(_ detail: AppCatalogDetail) -> String {
        let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
        let localized = isChinese ? detail.summaryZh : detail.summaryEn
        return localized.isEmpty ? detail.summaryZh : localized
    }

    /// 说明文档按 Markdown 解析（标题、列表与强调都转成富文本），解析失败时退回原文。
    private func readmeAttributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown, options: .init())) ?? AttributedString(markdown)
    }
}

/// 信息行 + 外链图标。
struct InfoLinkRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundColor(.accentColor)
            Image(systemName: "arrow.up.right.square")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }
}
