import SwiftUI

/// 应用模块：已安装列表（启停/更新/卸载）与应用商店（搜索/安装）两个分栏。
struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var section = "installed"
    @State private var storeSearch = ""
    @State private var appToUninstall: AppModel?
    @State private var showUninstallConfirm = false
    @State private var installTarget: StoreApp?
    @State private var toastText: String?

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
                    Image(systemName: "arrow.clockwise")
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
                guard let app = appToUninstall, let installId = app.installId else { return }
                appToUninstall = nil
                viewModel.uninstallApp(installId: installId) { success in
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
        .sheet(item: $installTarget) { app in
            InstallAppSheet(viewModel: viewModel, app: app)
                .environmentObject(translations)
        }
        .overlay(alignment: .bottom) {
            if let toastText {
                Text(toastText)
                    .font(.footnote)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            viewModel.fetchApps()
            if ProcessInfo.processInfo.environment["ONEPANEL_APPS_SECTION"] == "store" {
                section = "store"
                viewModel.fetchStore()
            }
        }
    }

    @ViewBuilder
    private var installedList: some View {
        if viewModel.isLoading && viewModel.apps.isEmpty {
            LoadingView()
        } else if viewModel.apps.isEmpty {
            EmptyStateView(
                icon: "app.badge",
                message: translations.get("appsListEmptyTitle", fallback: "No apps found")
            )
        } else {
            List {
                ForEach(viewModel.apps) { app in
                    HStack(spacing: 14) {
                        Image(systemName: "app.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
                        if let installId = app.installId {
                            Button {
                                operate(app, installId: installId, running: isRunning)
                            } label: {
                                Label(
                                    translations.get(isRunning ? "commonStop" : "commonStart",
                                                     fallback: isRunning ? "Stop" : "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            .tint(isRunning ? .orange : .green)
                            Button {
                                update(app, installId: installId)
                            } label: {
                                Label(translations.get("appUpdate", fallback: "Update"),
                                      systemImage: "arrow.triangle.2.circlepath")
                            }
                            .tint(.blue)
                        }
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
                    Button {
                        if !item.installed {
                            installTarget = item
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "shippingbox.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.indigo, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
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
                            } else {
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
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

    private func update(_ app: AppModel, installId: Int) {
        viewModel.updateApp(installId: installId) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchApps()
        }
    }

    private func operate(_ app: AppModel, installId: Int, running: Bool) {
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
