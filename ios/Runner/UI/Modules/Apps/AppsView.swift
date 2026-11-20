import SwiftUI
import AppleSharedUI

/// 应用模块：已安装列表（启停/重启/更新/卸载与详情）与应用商店（搜索/详情/安装）两个分栏。
struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    @EnvironmentObject private var navigation: ServerNavigation

    @State private var section = "installed"
    @State private var storeSearch = ""
    @State private var appToUninstall: AppModel?
    @State private var showUninstallConfirm = false
    @State private var toastText: String?
    @State private var launchHookApplied = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $section) {
                Text(translations.get("appStoreInstalled", fallback: "Installed")).tag("installed")
                Text(translations.get("appStoreTitle", fallback: "App Store")).tag("store")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if section == "installed" {
                installedList
            } else {
                storeList
            }
        }
        .navigationTitle(translations.get("serverModuleApps", fallback: "Apps"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .apps)
                Button {
                    refreshCurrentSection()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isStoreLoading)
            }
        }
        .confirmationDialog(
            translations.get("uninstallConfirm", fallback: "Confirm Uninstall"),
            isPresented: $showUninstallConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("appActionUninstall", fallback: "Uninstall"), role: .destructive) {
                guard let app = appToUninstall else { return }
                appToUninstall = nil
                viewModel.uninstallApp(installId: app.installId) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetchApps()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                appToUninstall = nil
            }
        } message: {
            Text(translations.get("uninstallCannotUndo", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetchApps()
            if ProcessInfo.processInfo.environment["ONEPANEL_APPS_SECTION"] == "store" {
                section = "store"
                viewModel.fetchStore()
            }
            applyDetailHook()
        }
    }

    @ViewBuilder
    private var installedList: some View {
        if viewModel.isLoading && viewModel.apps.isEmpty {
            LoadingView()
        } else if viewModel.apps.isEmpty {
            EmptyStateView(
                icon: "app.badge",
                message: translations.get("appsListEmptyTitle", fallback: "No apps found"),
                description: translations.get("appsEmptyHint",
                                              fallback: "Apps installed from the App Store appear here.")
            )
        } else {
            List {
                ForEach(viewModel.apps) { app in
                    NavigationLink(value: ServerRoute.appInstall(id: app.installId)) {
                        HStack(spacing: 14) {
                            AppIconView(url: app.icon, size: 40)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.headline)
                                Text(app.version)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            StatusBadge(
                                text: app.status,
                                color: StatusPalette.appStatus(app.status)
                            )
                        }
                        .padding(.vertical, 4)
                    }
                    .tint(.primary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            appToUninstall = app
                            showUninstallConfirm = true
                        } label: {
                            Label(translations.get("appActionUninstall", fallback: "Uninstall"),
                                  systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        let isRunning = app.status.lowercased() == "running"
                        Button {
                            operate(installId: app.installId, running: isRunning)
                        } label: {
                            Label(
                                translations.get(isRunning ? "commonStop" : "commonStart",
                                                 fallback: isRunning ? "Stop" : "Start"),
                                systemImage: isRunning ? "stop.fill" : "play.fill"
                            )
                        }
                        .tint(isRunning ? .orange : .green)
                        Button {
                            restart(installId: app.installId)
                        } label: {
                            Label(translations.get("appActionRestart", fallback: "Restart"),
                                  systemImage: "arrow.clockwise")
                        }
                        .tint(.blue)
                        Button {
                            update(installId: app.installId)
                        } label: {
                            Label(translations.get("appUpdate", fallback: "Update"),
                                  systemImage: "arrow.triangle.2.circlepath")
                        }
                        .tint(.indigo)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.fetchApps()
            }
        }
    }

    @ViewBuilder
    private var storeList: some View {
        if viewModel.isStoreLoading && viewModel.storeApps.isEmpty {
            LoadingView()
        } else if viewModel.storeApps.isEmpty {
            EmptyStateView(
                icon: "bag",
                message: translations.get("appsListEmptyTitle", fallback: "No apps found")
            )
            .searchable(
                text: $storeSearch,
                prompt: translations.get("appStoreSearchHint", fallback: "Search apps")
            )
            .onSubmit(of: .search) {
                viewModel.fetchStore(search: storeSearch)
            }
        } else {
            List {
                ForEach(viewModel.storeApps) { item in
                    NavigationLink(value: ServerRoute.appCatalog(key: item.key)) {
                        HStack(spacing: 14) {
                            AppIconView(
                                url: item.icon,
                                size: 40,
                                fallbackSymbol: "shippingbox.fill",
                                fallbackColor: .indigo
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                if !item.summary.isEmpty {
                                    Text(item.summary)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            Spacer()
                            if item.installed {
                                Text(translations.get("appStoreInstalled", fallback: "Installed"))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .tint(.primary)
                }
            }
            .listStyle(.insetGrouped)
            .refreshable {
                viewModel.fetchStore(search: storeSearch)
            }
            .searchable(
                text: $storeSearch,
                prompt: translations.get("appStoreSearchHint", fallback: "Search apps")
            )
            .onSubmit(of: .search) {
                viewModel.fetchStore(search: storeSearch)
            }
        }
    }

    private func refreshCurrentSection() {
        if section == "installed" {
            viewModel.fetchApps()
        } else {
            viewModel.fetchStore(search: storeSearch)
        }
    }

    /// 走查钩子：`ONEPANEL_APPS_SECTION=store` 切到商店；
    /// `ONEPANEL_OPEN_APP_DETAIL=<应用 key>` 进商店后打开详情页；
    /// `ONEPANEL_OPEN_INSTALL_DETAIL=<安装 id>` 进已安装列表后打开安装详情页。
    private func applyDetailHook() {
        guard !launchHookApplied else { return }
        let env = ProcessInfo.processInfo.environment
        if let key = env["ONEPANEL_OPEN_APP_DETAIL"], !key.isEmpty {
            launchHookApplied = true
            section = "store"
            viewModel.fetchStore()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                navigation.path.append(ServerRoute.appCatalog(key: key))
            }
            return
        }
        if let raw = env["ONEPANEL_OPEN_INSTALL_DETAIL"], let id = Int(raw) {
            launchHookApplied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                navigation.path.append(ServerRoute.appInstall(id: id))
            }
        }
    }

    private func update(installId: Int) {
        viewModel.updateApp(installId: installId) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchApps()
        }
    }

    private func restart(installId: Int) {
        viewModel.operateApp(installId: installId, operate: "restartApp") { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchApps()
        }
    }

    private func operate(installId: Int, running: Bool) {
        viewModel.operateApp(
            installId: installId,
            operate: running ? "stopApp" : "startApp"
        ) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchApps()
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
