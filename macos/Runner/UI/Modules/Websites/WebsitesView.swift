import SwiftUI

struct WebsitesView: View {
    @StateObject private var viewModel = WebsitesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
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
                            .padding(.vertical, 4)
                            .background(isRunning ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                            .foregroundColor(isRunning ? .green : .red)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
            }
        }
        .navigationTitle(translations.get("serverModuleWebsites", fallback: "Websites"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchWebsites()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchWebsites()
        }
    }
}
