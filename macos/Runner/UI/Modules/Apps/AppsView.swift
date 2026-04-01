import SwiftUI

struct AppsView: View {
    @StateObject private var viewModel = AppsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(translations.get("serverModuleApps", fallback: "Apps"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.apps.isEmpty {
                Text("No apps found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.apps) {
                    TableColumn(translations.get("server_name", fallback: "Name")) { app in
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.blue)
                            Text(app.name)
                        }
                    }
                    TableColumn(translations.get("app_version", fallback: "Version")) { app in
                        Text(app.version)
                            .foregroundColor(.secondary)
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { app in
                        Text(app.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchApps()
        }
    }
}
