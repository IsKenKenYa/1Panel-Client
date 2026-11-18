import SwiftUI

/// 服务器列表：点击行连接并切换当前服务器，进入服务器首页。
/// 支持添加（工具栏 + 与空态按钮）、滑动删除（二次确认）。
struct ServersView: View {
    @Binding var path: NavigationPath
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
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
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(translations.get("serverListEmptyTitle", fallback: "No servers found"))
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text(translations.get("serverListEmptyDesc", fallback: "Add a 1Panel server to get started."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button {
                        showAddSheet = true
                    } label: {
                        Label(translations.get("addServer", fallback: "Add Server"),
                              systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.servers) { server in
                        ServerRow(server: server, viewModel: viewModel)
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
                .navigationDestination(for: ServerModel.self) { server in
                    ServerHomeView(server: server)
                }
                .refreshable {
                    viewModel.fetchServers()
                }
            }
        }
        .navigationTitle(translations.get("navServer", fallback: "Servers"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                Button {
                    viewModel.fetchServers()
                } label: {
                    Image(systemName: "arrow.clockwise")
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
            viewModel.fetchServers {
                applyLaunchHooks()
            }
            if ProcessInfo.processInfo.environment["ONEPANEL_OPEN_ADD_SERVER"] == "1" {
                showAddSheet = true
            }
        }
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
        path.append(server)
        if let module {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                path.append(module)
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
                showToast(String(format: translations.get("serverDeleteSuccess", fallback: "Deleted {name}"), server.name))
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
    @ObservedObject var viewModel: ServersViewModel
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        NavigationLink(value: server) {
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
            .padding(.vertical, 4)
        }
        .tint(.primary)
    }
}
