import SwiftUI
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

/// 原生壳导航结构：4 个 tab，与 MDUI3 iPhone 壳底部导航语义一致
/// （服务器 / 文件 / 安全 / 设置），业务模块从服务器首页进入。
/// TabView + NavigationStack 在 iOS 26 自动获得 Liquid Glass 材质。
///
/// 支持启动参数 `ONEPANEL_INITIAL_TAB`（files/security/settings，默认 servers）
/// 选择初始 tab；`ONEPANEL_OPEN_MODULE`（containers/websites/apps/monitoring）
/// 在服务器 tab 内以入栈方式打开对应模块，保留返回层级；`files` 直接切到文件 tab。
struct AppShellView: View {
    let engine: FlutterEngine
    @StateObject private var theme = ThemeManager.shared
    @StateObject private var translations = TranslationsManager.shared
    @State private var selection = 0
    @State private var serversPath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    @State private var moduleOverrideApplied = false

    private var moduleOverride: String? {
        ProcessInfo.processInfo.environment["ONEPANEL_OPEN_MODULE"]
    }

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack(path: $serversPath) {
                ServersView(path: $serversPath)
                    .navigationDestination(for: ModuleRoute.self) { route in
                        route.content
                    }
            }
            .tabItem {
                Label(translations.get("navServer", fallback: "Servers"),
                      systemImage: "desktopcomputer")
            }
            .tag(0)

            NavigationStack {
                FilesView()
            }
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

            NavigationStack(path: $settingsPath) {
                SettingsView(path: $settingsPath)
                    .navigationDestination(for: SettingsPageRoute.self) { route in
                        switch route {
                        case .about: AboutView()
                        case .legal: LegalCenterView()
                        }
                    }
            }
            .tabItem {
                Label(translations.get("navSettings", fallback: "Settings"),
                      systemImage: "gearshape")
            }
            .tag(3)
        }
        .onAppear {
            switch ProcessInfo.processInfo.environment["ONEPANEL_INITIAL_TAB"] {
            case "files": selection = 1
            case "security": selection = 2
            case "settings": selection = 3
            default: break
            }
            applyModuleOverride()
        }
        .environmentObject(theme)
        .environmentObject(translations)
        .preferredColorScheme(theme.preferredColorScheme)
        .onAppear {
            translations.load { }
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
