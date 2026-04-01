import SwiftUI

struct WebsitesView: View {
    @StateObject private var viewModel = WebsitesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var websiteToDelete: WebsiteModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.websites.isEmpty {
                Text("No websites found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.websites) {
                    TableColumn(translations.get("website_domain", fallback: "Domain")) { website in
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text(website.primaryDomain)
                        }
                        .contextMenu {
                            let isRunning = website.status.lowercased() == "running"
                            Button {
                                Task { await viewModel.toggleWebsiteStatus(id: website.originalId, currentStatus: website.status) }
                            } label: {
                                Label(
                                    isRunning ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"),
                                    systemImage: isRunning ? "stop.fill" : "play.fill"
                                )
                            }
                            Divider()
                            Button(role: .destructive) {
                                websiteToDelete = website
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("website_remark", fallback: "Remark")) { website in
                        Text(website.remark.isEmpty ? "-" : website.remark)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { website in
                        let isRunning = website.status.lowercased() == "running"
                        Text(website.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isRunning ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                            .foregroundColor(isRunning ? .green : .red)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
            }
        }
        .navigationTitle(translations.get("serverModuleWebsites", fallback: "Websites"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchWebsites() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(websiteToDelete?.primaryDomain ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let w = websiteToDelete { Task { await viewModel.deleteWebsite(id: w.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchWebsites() }
    }
}
