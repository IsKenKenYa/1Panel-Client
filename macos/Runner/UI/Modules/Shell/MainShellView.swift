import AppKit
import AppleSharedUI
import FlutterMacOS
import SwiftUI

final class MainShellNavigation: ObservableObject {
    @Published var selectedModule: String? = "dashboard"
}

struct MainShellView: View {
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var translations = TranslationsManager.shared
    @StateObject private var settings = SettingsViewModel()
    @ObservedObject var navigation: MainShellNavigation
    @ObservedObject var appLock: MacOSAppLockController

    let flutterViewController: FlutterViewController

    var body: some View {
        gatedContent
            .environmentObject(theme)
            .environmentObject(translations)
            .environment(\.translationsProvider, translations)
            .frame(minWidth: 600, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
            .onAppear {
                translations.load {}
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                appLock.applicationResignedActive()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                appLock.applicationBecameActive()
            }
    }

    @ViewBuilder
    private var gatedContent: some View {
        if appLock.isLocked {
            AppLockGateView(appLock: appLock)
        } else {
            splitView
        }
    }

    private var splitView: some View {
        NavigationSplitView {
            SidebarView(selectedModule: $navigation.selectedModule)
                .navigationTitle(translations.get("appName", fallback: "Open1Panel"))
                .navigationSplitViewColumnWidth(min: 180, ideal: 216, max: 300)
        } detail: {
            detailContent
        }
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if let module = navigation.selectedModule, appLock.requiresUnlock(for: module) {
            AppLockGateView(appLock: appLock, moduleId: module)
        } else if let module = navigation.selectedModule {
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
            case "virtualMachines":
                VirtualMachinesView()
            case "alerts":
                AlertModuleView()
            case "modelDownloader":
                ModelDownloaderView()
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
                SettingsView(viewModel: settings, appLock: appLock) {
                    navigation.selectedModule = "servers"
                }
            default:
                FlutterContentView(flutterViewController: flutterViewController)
            }
        } else {
            Text(translations.get("serverModulesTitle", fallback: "Modules"))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
