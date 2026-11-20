import SwiftUI
import AppleSharedUI

/// 服务器列表：点击行连接并切换当前服务器，进入服务器首页。
/// 支持添加（工具栏 + 与空态按钮）、滑动删除（二次确认）。
struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject private var navigation: ServerNavigation
    @EnvironmentObject var translations: TranslationsManager

    @State private var showAddSheet = false
    @State private var editingServer: ServerModel?
    @State private var serverToDelete: ServerModel?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?
    @State private var launchHookApplied = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.servers.isEmpty {
                LoadingView()
            } else if viewModel.servers.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.servers) { server in
                        Button {
                            openServer(server)
                        } label: {
                            ServerRow(server: server)
                        }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    serverToDelete = server
                                    showDeleteConfirm = true
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    editingServer = server
                                    showAddSheet = true
                                } label: {
                                    Label(translations.get("commonEdit", fallback: "Edit"),
                                          systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.insetGrouped)
                .disabled(viewModel.isProcessing)
                .refreshable {
                    viewModel.fetchServers()
                }
            }
        }
        .navigationTitle(translations.get("navServer", fallback: "Servers"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.servers.isEmpty {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label(translations.get("addServer", fallback: "Add Server"), systemImage: "plus")
                    }
                }
                Button {
                    viewModel.fetchServers()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            editingServer = nil
        }) {
            AddServerSheet(viewModel: viewModel, editingServer: editingServer)
                .environmentObject(translations)
        }
        .confirmationDialog(
            translations.get("serverDeleteConfirmTitle", fallback: "Delete Server"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteConfirmedServer()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(deleteConfirmMessage)
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetchServers {
                applyLaunchHooks()
            }
            if ProcessInfo.processInfo.environment["ONEPANEL_OPEN_ADD_SERVER"] == "1" {
                showAddSheet = true
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let title = translations.get("serverListEmptyTitle", fallback: "No servers found")
        let description = translations.get("serverListEmptyDesc", fallback: "Add a 1Panel server to get started.")
        if #available(iOS 17.0, *) {
            ContentUnavailableView {
                Label(title, systemImage: "server.rack")
            } description: {
                Text(description)
            } actions: {
                if #available(iOS 26.0, *) {
                    addServerButton.buttonStyle(.glassProminent)
                } else {
                    addServerButton.buttonStyle(.borderedProminent)
                }
            }
        } else {
            VStack(spacing: 12) {
                Label(title, systemImage: "server.rack").font(.headline)
                Text(description)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                addServerButton.buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private var addServerButton: some View {
        Button {
            showAddSheet = true
        } label: {
            Label(translations.get("addServer", fallback: "Add Server"), systemImage: "plus")
        }
        .controlSize(.large)
    }

    /// 走查钩子：按真实层级依次入栈服务器首页与模块页。
    /// `ONEPANEL_OPEN_SERVER_HOME=1` 打开服务器首页；
    /// `ONEPANEL_OPEN_MODULE=containers/websites/apps/monitoring` 打开首页后再进模块。
    private func applyLaunchHooks() {
        guard !launchHookApplied else { return }
        let env = ProcessInfo.processInfo.environment
        let module = ModuleRoute.fromEnvironment(env["ONEPANEL_OPEN_MODULE"])
        let wantsHome = env["ONEPANEL_OPEN_SERVER_HOME"] == "1" || module != nil
        guard wantsHome,
              let server = viewModel.servers.first(where: { $0.isCurrent })
                ?? viewModel.servers.first else { return }
        launchHookApplied = true
        openServer(server, module: module)
    }

    private func openServer(_ server: ServerModel, module: ModuleRoute? = nil) {
        viewModel.selectServer(id: server.id) { success in
            if success {
                navigation.openServer(server, module: module)
            } else {
                showToast(translations.get("serverTestFailed", fallback: "Connection failed"))
            }
        }
    }

    private var deleteConfirmMessage: String {
        let template = translations.get(
            "serverDeleteConfirmMessage",
            fallback: "Delete server {name}?"
        )
        return template.replacingOccurrences(of: "{name}", with: serverToDelete?.name ?? "")
    }

    private func deleteConfirmedServer() {
        guard let server = serverToDelete else { return }
        viewModel.deleteServer(id: server.originalId) { success, error in
            if success {
                viewModel.fetchServers()
                let template = translations.get("serverDeleteSuccess", fallback: "Deleted {name}")
                showToast(template.replacingOccurrences(of: "{name}", with: server.name))
            } else {
                let template = translations.get("serverDeleteFailed", fallback: "Failed to delete: {error}")
                showToast(template.replacingOccurrences(of: "{error}", with: error ?? ""))
            }
            serverToDelete = nil
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

private struct ServerRow: View {
    let server: ServerModel
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(server.name)
                        .font(.headline)
                    Spacer()
                    if server.isCurrent {
                        StatusBadge(
                            text: translations.get("serverCurrent", fallback: "Current"),
                            color: .green
                        )
                    }
                }
                Text(server.url)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(spacing: 16) {
                    Label(String(format: "%.1f%%", server.cpu), systemImage: "cpu")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Label(String(format: "%.1f%%", server.memory), systemImage: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.primary)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
