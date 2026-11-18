import SwiftUI

/// 服务器下的业务模块路由：从服务器首页进入，模块之间可通过切换菜单跳转。
enum ModuleRoute: String, CaseIterable, Identifiable {
    case containers
    case websites
    case apps
    case monitoring
    case databases
    case cronjobs
    case firewall
    case backups
    case ai

    var id: String { rawValue }

    static func fromEnvironment(_ value: String?) -> ModuleRoute? {
        guard let value else { return nil }
        return ModuleRoute(rawValue: value)
    }

    func title(_ translations: TranslationsManager) -> String {
        switch self {
        case .containers:
            return translations.get("serverModuleContainers", fallback: "Containers")
        case .websites:
            return translations.get("serverModuleWebsites", fallback: "Websites")
        case .apps:
            return translations.get("serverModuleApps", fallback: "Apps")
        case .monitoring:
            return translations.get("serverModuleMonitoring", fallback: "Monitoring")
        case .databases:
            return translations.get("serverModuleDatabases", fallback: "Databases")
        case .cronjobs:
            return translations.get("operationsCronjobsTitle", fallback: "Cronjobs")
        case .firewall:
            return translations.get("serverModuleFirewall", fallback: "Firewall")
        case .backups:
            return translations.get("operationsBackupsTitle", fallback: "Backups")
        case .ai:
            return translations.get("serverModuleAi", fallback: "AI")
        }
    }

    var icon: String {
        switch self {
        case .containers: return "square.stack.3d.up"
        case .websites: return "globe"
        case .apps: return "app.badge"
        case .monitoring: return "chart.xyaxis.line"
        case .databases: return "cylinder.split.1x2"
        case .cronjobs: return "clock.arrow.circlepath"
        case .firewall: return "shield.lefthalf.filled"
        case .backups: return "externaldrive"
        case .ai: return "brain"
        }
    }

    @ViewBuilder
    var content: some View {
        switch self {
        case .containers: ContainersView()
        case .websites: WebsitesView()
        case .apps: AppsView()
        case .monitoring: MonitoringView()
        case .databases: DatabasesView()
        case .cronjobs: CronjobsView()
        case .firewall: FirewallView()
        case .backups: BackupsView()
        case .ai: AIModelsView()
        }
    }
}

/// 设置子页路由：关于与法律文件。
enum SettingsPageRoute: String, Hashable, CaseIterable {
    case about
    case legal
}

/// 模块切换菜单：在模块页右上角提供其他模块的入口，保持服务器首页为层级根。
struct ModuleSwitcherMenu: View {
    @EnvironmentObject var translations: TranslationsManager
    let current: ModuleRoute

    var body: some View {
        Menu {
            ForEach(ModuleRoute.allCases) { route in
                if route != current {
                    NavigationLink(value: route) {
                        Label(route.title(translations), systemImage: route.icon)
                    }
                }
            }
        } label: {
            Image(systemName: "square.grid.2x2")
        }
    }
}
