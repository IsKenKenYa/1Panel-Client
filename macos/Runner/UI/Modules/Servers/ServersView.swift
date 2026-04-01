import SwiftUI

struct ServersView: View {
    @StateObject private var viewModel = ServersViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(translations.get("navServer", fallback: "Servers"))
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
                Table(viewModel.servers) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { server in
                        Text(server.name)
                    }
                    TableColumn(translations.get("server_url", fallback: "URL")) { server in
                        Text(server.url)
                    }
                }
                .tableStyle(.inset)
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchServers()
        }
    }
}
