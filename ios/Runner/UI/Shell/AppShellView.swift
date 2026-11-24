import SwiftUI
import AppleSharedUI
import Flutter

struct FlutterViewControllerRepresentable: UIViewControllerRepresentable {
    let engine: FlutterEngine

    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        controller.isViewOpaque = false
        controller.view.backgroundColor = .clear
        return controller
    }

    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {
    }
}

/// 原生壳导航结构：4 个 tab（服务器 / 文件 / 安全 / 设置）。
/// 业务模块从服务器首页按 `ModuleRoute` 进入，容器、网站、应用与监控
/// 都在服务器 tab 内部以入栈方式打开。
/// MDUI3 iPhone 壳的底部导航为服务器 / 文件 / 容器 / 设置，第三项是
/// 可固定的业务模块；两套壳的 tab 集合因此不同，模块本身两端都可到达。
/// TabView + NavigationStack 在 iOS 26 自动获得 Liquid Glass 材质。
///
/// 支持启动参数 `ONEPANEL_INITIAL_TAB`（files/security/settings，默认 servers）
/// 选择初始 tab；`ONEPANEL_OPEN_MODULE`（containers/websites/apps/monitoring）
/// 在服务器 tab 内以入栈方式打开对应模块，保留返回层级；`files` 直接切到文件 tab。
struct AppShellView: View {
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var translations = TranslationsManager.shared
    @State private var selection = 0
    @StateObject private var serverNavigation = ServerNavigation()
    @State private var settingsPath = NavigationPath()
    @State private var moduleOverrideApplied = false

    private var moduleOverride: String? {
        ProcessInfo.processInfo.environment["ONEPANEL_OPEN_MODULE"]
    }

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $selection) {
                    Tab(translations.get("navServer", fallback: "Servers"),
                        systemImage: "server.rack", value: 0) {
                        serversTab
                    }
                    Tab(translations.get("navFiles", fallback: "Files"),
                        systemImage: "folder", value: 1) {
                        filesTab
                    }
                    Tab(translations.get("navSecurity", fallback: "Security"),
                        systemImage: "shield", value: 2) {
                        NavigationStack { SecurityView() }
                    }
                    Tab(translations.get("navSettings", fallback: "Settings"),
                        systemImage: "gearshape", value: 3) {
                        settingsTab
                    }
                }
                .tabViewStyle(.sidebarAdaptable)
            } else {
                legacyTabs
            }
        }
        .environmentObject(serverNavigation)
        .environmentObject(theme)
        .environmentObject(translations)
        .environment(\.translationsProvider, translations)
        .preferredColorScheme(theme.preferredColorScheme)
        .onAppear {
            switch ProcessInfo.processInfo.environment["ONEPANEL_INITIAL_TAB"] {
            case "files": selection = 1
            case "security": selection = 2
            case "settings": selection = 3
            default: break
            }
            applyModuleOverride()
            translations.load { }
        }
    }

    private var legacyTabs: some View {
        TabView(selection: $selection) {
            serversTab
            .tabItem {
                Label(translations.get("navServer", fallback: "Servers"),
                      systemImage: "server.rack")
            }
            .tag(0)

            filesTab
            .tabItem {
                Label(translations.get("navFiles", fallback: "Files"),
                      systemImage: "folder")
            }
            .tag(1)

            NavigationStack {
                SecurityView()
            }
            .tabItem {
                Label(translations.get("navSecurity", fallback: "Security"),
                      systemImage: "shield")
            }
            .tag(2)

            settingsTab
            .tabItem {
                Label(translations.get("navSettings", fallback: "Settings"),
                      systemImage: "gearshape")
            }
            .tag(3)
        }
    }

    private var serversTab: some View {
        NavigationStack(path: $serverNavigation.path) {
            ServersView()
                .navigationDestination(for: ServerRoute.self) { route in
                    switch route {
                    case .server(let server): ServerHomeView(server: server)
                    case .module(let module): module.content
                    case .container(let name): ContainerDetailView(containerName: name)
                    case .website(let id): WebsiteDetailView(websiteId: id)
                    case .appInstall(let id): AppInstallDetailView(installId: id)
                    case .appCatalog(let key): AppCatalogDetailView(appKey: key)
                    case .database(let ref): DatabaseDetailView(reference: ref)
                    case .vmInstance(let name): VMInstanceDetailView(instanceName: name)
                    }
                }
        }
    }

    private var filesTab: some View {
        NavigationStack { FilesView() }
            .id(serverNavigation.activeServerID)
    }

    private var settingsTab: some View {
        NavigationStack(path: $settingsPath) {
            SettingsView(path: $settingsPath)
                .navigationDestination(for: SettingsPageRoute.self) { route in
                    switch route {
                    case .about: AboutView()
                    case .legal: LegalCenterView()
                    }
                }
        }
    }

    private func applyModuleOverride() {
        guard !moduleOverrideApplied, let override = moduleOverride else { return }
        moduleOverrideApplied = true
        if override == "files" {
            selection = 1
        }
    }
}
