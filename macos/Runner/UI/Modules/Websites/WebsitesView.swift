import AppleSharedUI
import SwiftUI

/// macOS 网站列表：列表行承载域名、备注与状态，行内直接暴露详情、启停与删除。
struct WebsitesView: View {
    @StateObject private var viewModel = WebsitesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var websiteToDelete: WebsiteModel?
    @State private var showDeleteConfirm = false
    @State private var detailWebsite: WebsiteModel?

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
                        row(website)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(translations.get("serverModuleWebsites", fallback: "Websites"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().controlSize(.small)
                } else {
                    Button {
                        viewModel.fetchWebsites()
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"),
                              systemImage: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let website = websiteToDelete else { return }
                websiteToDelete = nil
                Task { await viewModel.deleteWebsite(id: website.originalId) }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                websiteToDelete = nil
            }
        } message: {
            Text(websiteToDelete.map { "\($0.primaryDomain)\n" } ?? ""
                 + translations.get("deleteCannotUndoMessage",
                                    fallback: "This action cannot be undone."))
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchWebsites() }
        .sheet(item: $detailWebsite) { website in
            WebsiteDetailView(website: website)
                .frame(minWidth: 880, minHeight: 640)
                .id(website.id)
        }
    }

    private func row(_ website: WebsiteModel) -> some View {
        let isRunning = website.status.lowercased() == "running"
        return ModuleRow(
            icon: "globe",
            iconColor: .blue,
            title: website.primaryDomain,
            subtitle: website.remark,
            badge: (website.status.isEmpty ? "--" : website.status,
                    isRunning ? .green : .red),
            onOpen: { detailWebsite = website }
        ) {
            RowActionsMenu {
                Button {
                    detailWebsite = website
                } label: {
                    Label(translations.get("websitesDetailTitle", fallback: "Site details"),
                          systemImage: "info.circle")
                }
                Button {
                    Task {
                        await viewModel.toggleWebsiteStatus(
                            id: website.originalId,
                            currentStatus: website.status
                        )
                    }
                } label: {
                    Label(isRunning
                          ? translations.get("commonStop", fallback: "Stop")
                          : translations.get("commonStart", fallback: "Start"),
                          systemImage: isRunning ? "stop.fill" : "play.fill")
                }
                Divider()
                Button(role: .destructive) {
                    websiteToDelete = website
                    showDeleteConfirm = true
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .contextMenu {
            Button {
                detailWebsite = website
            } label: {
                Label(translations.get("websitesDetailTitle", fallback: "Site details"),
                      systemImage: "info.circle")
            }
            Button {
                Task {
                    await viewModel.toggleWebsiteStatus(
                        id: website.originalId,
                        currentStatus: website.status
                    )
                }
            } label: {
                Label(
                    isRunning
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: isRunning ? "stop.fill" : "play.fill"
                )
            }
            Divider()
            Button(role: .destructive) {
                websiteToDelete = website
                showDeleteConfirm = true
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
        }
    }
}