import SwiftUI
import FlutterMacOS

struct MainShellView: View {
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var translations = TranslationsManager.shared
    @State private var selectedModule: String? = "servers"
    
    let flutterViewController: FlutterViewController
    
    var body: some View {
        NavigationView {
            SidebarView(selectedModule: $selectedModule)
                .environmentObject(theme)
                .environmentObject(translations)
            
            Group {
                if let module = selectedModule {
                    switch module {
                    case "servers":
                        ServersView()
                    case "files":
                        FilesView()
                    case "apps":
                        AppsView()
                    case "websites":
                        WebsitesView()
                    case "monitoring":
                        MonitoringView()
                    case "containers":
                        ContainersView()
                    case "settings":
                        SettingsView()
                    default:
                        FlutterContentView(flutterViewController: flutterViewController)
                    }
                } else {
                    Text("Select a module")
                        .foregroundColor(.secondary)
                }
            }
            .environmentObject(theme)
            .environmentObject(translations)
            .frame(minWidth: 400, maxWidth: .infinity, minHeight: 300, maxHeight: .infinity)
            // Use native transparent background for content
            .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
        }
        .onAppear {
            translations.load {
                // Done
            }
        }
    }
}
