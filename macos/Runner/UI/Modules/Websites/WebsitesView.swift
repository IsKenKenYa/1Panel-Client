import SwiftUI

struct WebsitesView: View {
    @StateObject private var viewModel = WebsitesViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(TranslationsManager.shared.get("serverModuleWebsites", fallback: "Websites"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.websites.isEmpty {
                Text("No websites found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.websites) { website in
                            MDCard {
                                MDListItem(
                                    title: website.primaryDomain,
                                    subtitle: website.remark.isEmpty ? "No remark" : website.remark,
                                    icon: "globe"
                                ) {
                                    Text(website.status)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(website.status.lowercased() == "running" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                        .foregroundColor(website.status.lowercased() == "running" ? .green : .red)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchWebsites()
        }
    }
}
