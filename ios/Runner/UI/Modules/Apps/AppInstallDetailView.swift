import SwiftUI
import AppleSharedUI

/// 已安装应用详情：基本信息、访问地址、安装参数与详情操作（启停/重启/更新/卸载）。
struct AppInstallDetailView: View {
    let installId: Int
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var translations: TranslationsManager
    @State private var toastText: String?
    @State private var showUninstallConfirm = false

    var body: some View {
        Group {
            if viewModel.detailLoading && viewModel.installInfo == nil && viewModel.installConfig == nil {
                LoadingView()
            } else if viewModel.installInfo == nil && viewModel.installConfig == nil {
                EmptyStateView(
                    icon: "app.badge",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                detailList
            }
        }
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .apps)
                Button {
                    viewModel.fetchInstallDetail(installId: installId)
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.detailLoading)
            }
        }
        .confirmationDialog(
            translations.get("uninstallConfirm", fallback: "Confirm Uninstall"),
            isPresented: $showUninstallConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("appActionUninstall", fallback: "Uninstall"), role: .destructive) {
                viewModel.uninstallApp(installId: installId) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("uninstallCannotUndo", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetchInstallDetail(installId: installId)
        }
    }

    @ViewBuilder
    private var detailList: some View {
        let info = viewModel.installInfo
        List {
            Section {
                HStack(spacing: 14) {
                    AppIconView(
                        url: info?.icon ?? "",
                        size: 56,
                        fallbackSymbol: "app.fill",
                        fallbackColor: .blue
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(catalogTitle(info))
                            .font(.title3.weight(.semibold))
                        if let name = info?.name, !name.isEmpty, name != catalogTitle(info) {
                            Text(name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if let status = info?.status, !status.isEmpty {
                        StatusBadge(text: status, color: StatusPalette.appStatus(status))
                    }
                }
                .padding(.vertical, 4)
            }

            Section(translations.get("appDetailTitle", fallback: "App Details")) {
                InfoLine(label: translations.get("appInfoName", fallback: "Name"),
                         value: info?.name ?? "")
                InfoLine(label: translations.get("appInfoVersion", fallback: "Version"),
                         value: info?.version ?? "")
                InfoLine(label: translations.get("appInfoStatus", fallback: "Status"),
                         value: info?.status ?? "")
                InfoLine(label: translations.get("containerInfoId", fallback: "Container ID"),
                         value: info?.container ?? "")
                if let createdAt = info?.createdAt, !createdAt.isEmpty {
                    InfoLine(label: translations.get("appInfoCreated", fallback: "Created At"),
                             value: createdAt)
                }
            }

            if let httpPort = info?.httpPort, httpPort > 0 {
                Section(translations.get("containerInfoPorts", fallback: "Ports")) {
                    InfoLine(label: translations.get("databasePortLabel", fallback: "Port"),
                             value: String(httpPort))
                }
            }

            if let config = viewModel.installConfig {
                Section(translations.get("appInstallParamsTitle", fallback: "Install Parameters")) {
                    InfoLine(label: translations.get("appInstallContainerName", fallback: "Container Name"),
                             value: config.containerName)
                    if config.cpuQuota > 0 {
                        InfoLine(label: translations.get("appInstallCpuLimit", fallback: "CPU Limit"),
                                 value: String(format: "%.2f", config.cpuQuota))
                    }
                    if config.memoryLimit > 0 {
                        InfoLine(label: translations.get("appInstallMemoryLimit", fallback: "Memory Limit"),
                                 value: "\(Int(config.memoryLimit)) \(config.memoryUnit.isEmpty ? "MB" : config.memoryUnit)")
                    }
                    ForEach(config.params) { param in
                        InfoLine(
                            label: param.label(chinese: isChinese),
                            value: param.type == "password" ? "********" : param.value
                        )
                    }
                }
            }

            Section(translations.get("websitesDetailActionsTitle", fallback: "Quick actions")) {
                let running = (info?.status ?? "").lowercased() == "running"
                Button {
                    operate(operate: running ? "stopApp" : "startApp")
                } label: {
                    Label(
                        translations.get(running ? "appActionStop" : "appActionStart",
                                         fallback: running ? "Stop" : "Start"),
                        systemImage: running ? "stop.fill" : "play.fill"
                    )
                }
                Button {
                    operate(operate: "restartApp")
                } label: {
                    Label(translations.get("appActionRestart", fallback: "Restart"),
                          systemImage: "arrow.clockwise")
                }
                Button {
                    viewModel.updateApp(installId: installId) { success in
                        showToast(success
                            ? translations.get("commonSaveSuccess", fallback: "Saved")
                            : translations.get("commonSaveFailed", fallback: "Save failed"))
                    }
                } label: {
                    Label(translations.get("appUpdate", fallback: "Update"),
                          systemImage: "arrow.triangle.2.circlepath")
                }
                Button(role: .destructive) {
                    showUninstallConfirm = true
                } label: {
                    Label(translations.get("appActionUninstall", fallback: "Uninstall"),
                          systemImage: "trash")
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.fetchInstallDetail(installId: installId)
        }
    }

    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
    }

    /// 目录展示名（OpenResty、MySQL 这类官方写法），缺失时退回安装名。
    private func catalogTitle(_ info: AppInstallInfoModel?) -> String {
        guard let info else { return "" }
        return info.appName.isEmpty ? info.name : info.appName
    }

    private var displayTitle: String {
        let title = catalogTitle(viewModel.installInfo)
        return title.isEmpty ? String(installId) : title
    }

    private func operate(operate: String) {
        viewModel.operateApp(installId: installId, operate: operate) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchInstallDetail(installId: installId)
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
