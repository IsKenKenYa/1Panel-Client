import SwiftUI

/// 网站列表：行级操作——启动/停止、删除（二次确认）。
struct WebsitesView: View {
    @StateObject private var viewModel = WebsitesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var websiteToDelete: WebsiteModel?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.websites.isEmpty {
                LoadingView()
            } else if viewModel.websites.isEmpty {
                EmptyStateView(
                    icon: "globe",
                    message: translations.get("websitesListEmptyTitle", fallback: "No websites found")
                )
            } else {
                List {
                    ForEach(viewModel.websites) { website in
                        WebsiteListRow(
                            website: website,
                            onDelete: {
                                websiteToDelete = website
                                showDeleteConfirm = true
                            },
                            onToggle: { id, isRunning in
                                toggle(website, id: id, running: isRunning)
                            }
                        )
                    }
                }
                .listStyle(.insetGrouped)
                .navigationDestination(for: WebsiteModel.self) { website in
                    WebsiteDetailView(websiteId: Int(website.originalId) ?? 0)
                }
                .refreshable {
                    viewModel.fetchWebsites()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleWebsites", fallback: "Websites"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .websites)
                Button {
                    showCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                Button {
                    viewModel.fetchWebsites()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateWebsiteSheet(viewModel: viewModel)
                .environmentObject(translations)
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let website = websiteToDelete, let id = Int(website.originalId) else { return }
                websiteToDelete = nil
                viewModel.deleteWebsite(id: id) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetchWebsites()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                websiteToDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
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
            viewModel.fetchWebsites()
            if ProcessInfo.processInfo.environment["ONEPANEL_OPEN_ADD_WEBSITE"] == "1" {
                showCreateSheet = true
            }
        }
    }

    private func toggle(_ website: WebsiteModel, id: Int, running: Bool) {
        viewModel.toggleStatus(id: id, currentStatus: website.status) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetchWebsites()
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

/// 网站行内容：主域名、状态徽标与备注。
private struct WebsiteRow: View {
    let website: WebsiteModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(website.primaryDomain)
                    .font(.headline)
                Spacer()
                StatusBadge(
                    text: website.status,
                    color: StatusPalette.websiteStatus(website.status)
                )
            }
            if !website.remark.isEmpty {
                Text(website.remark)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// 列表行：进入详情 + 滑动删除 + 滑动启停。
private struct WebsiteListRow: View {
    let website: WebsiteModel
    let onDelete: () -> Void
    let onToggle: (Int, Bool) -> Void
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        NavigationLink(value: website) {
            WebsiteRow(website: website)
        }
        .tint(.primary)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            leadingActions
        }
    }

    @ViewBuilder
    private var leadingActions: some View {
        let isRunning = website.status.lowercased() == "running"
        if let id = Int(website.originalId) {
            Button {
                onToggle(id, isRunning)
            } label: {
                Label(
                    translations.get(isRunning ? "commonStop" : "commonStart",
                                     fallback: isRunning ? "Stop" : "Start"),
                    systemImage: isRunning ? "stop.fill" : "play.fill"
                )
            }
            .tint(isRunning ? .orange : .green)
        }
    }
}
