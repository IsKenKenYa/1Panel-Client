import SwiftUI
import FlutterMacOS

struct MainShellView: View {
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var translations = TranslationsManager.shared
    @State private var selectedModule: String? = "dashboard"
    
    let flutterViewController: FlutterViewController
    
    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                NavigationSplitView {
                    SidebarView(selectedModule: $selectedModule)
                        .environmentObject(theme)
                        .environmentObject(translations)
                        .navigationTitle(translations.get("app_name", fallback: "Open1Panel"))
                } detail: {
                    detailContent
                        .environmentObject(theme)
                        .environmentObject(translations)
                }
            } else {
                NavigationView {
                    SidebarView(selectedModule: $selectedModule)
                        .environmentObject(theme)
                        .environmentObject(translations)
                    
                    detailContent
                        .environmentObject(theme)
                        .environmentObject(translations)
                }
            }
        }
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
        .background(VisualEffectView(material: .contentBackground, blendingMode: .behindWindow))
        .onAppear {
            translations.load {
                // Done
            }
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if let module = selectedModule {
            switch module {
            case "dashboard":
                DashboardView()
            case "servers":
                ServersView()
            case "websites":
                WebsitesView()
            case "databases":
                DatabasesView()
            case "containers":
                ContainersView()
            case "apps":
                AppsView()
            case "files":
                FilesView()
            case "monitoring":
                MonitoringView()
            case "firewall":
                FirewallView()
            case "cronjobs":
                CronJobsView()
            case "backups":
                BackupsView()
            case "ai":
                AIView()
            case "settings":
                SettingsView()
            default:
                FlutterContentView(flutterViewController: flutterViewController)
            }
        } else {
            Text("Select a module")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
