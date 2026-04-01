import SwiftUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(TranslationsManager.shared.get("navServer", fallback: "Servers"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.servers.isEmpty {
                Text("No servers found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.servers) { server in
                            MDCard {
                                MDListItem(
                                    title: server.name,
                                    subtitle: server.url,
                                    icon: "server.rack"
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchServers()
        }
    }
}
