import SwiftUI

enum ServerRoute: Hashable {
    case server(ServerModel)
    case module(ModuleRoute)
    case container(name: String)
    case website(id: Int)
    case appInstall(id: Int)
    case appCatalog(key: String)
    case database(DatabaseRef)
    case vmInstance(name: String)
}

/// 数据库详情路由载荷：列表行已持有全部字段，详情页无需再次搜索。
struct DatabaseRef: Hashable {
    let scope: String
    let id: Int?
    let name: String
    let lookupName: String
    let source: String
    let engine: String
    let version: String
    let status: String
    let description: String
}

@MainActor
final class ServerNavigation: ObservableObject {
    @Published var path: [ServerRoute] = []
    @Published private(set) var activeServerID: String?

    func openServer(_ server: ServerModel, module: ModuleRoute?) {
        activeServerID = server.id
        path = [.server(server)]
        if let module {
            path.append(.module(module))
        }
    }

    /// 切换模块：把模块层替换为目标模块，模块内的详情页随模块一起退出，
    /// 服务器首页仍留在层级根部，返回语义与底部导航一致。
    func switchModule(to route: ModuleRoute) {
        let moduleIndex = path.firstIndex { element in
            if case .module = element { return true }
            return false
        }
        guard let moduleIndex else { return }
        path = Array(path.prefix(moduleIndex)) + [.module(route)]
    }
}

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
    case logs
    case virtualMachines
    case alerts

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
        case .logs:
            return translations.get("operationsLogsTitle", fallback: "Logs")
        case .virtualMachines:
            return translations.get("serverModuleVm", fallback: "Virtual Machines")
        case .alerts:
            return translations.get("alertPageTitle", fallback: "Alert Center")
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
        case .logs: return "doc.text.magnifyingglass"
        case .virtualMachines: return "desktopcomputer"
        case .alerts: return "bell.badge"
        }
    }

    @ViewBuilder
    var content: some View {
        switch self {
        case .containers: ContainersModuleView()
        case .websites: WebsitesModuleView()
        case .apps: AppsView()
        case .monitoring: MonitoringView()
        case .databases: DatabasesView()
        case .cronjobs: CronjobsView()
        case .firewall: FirewallView()
        case .backups: BackupsView()
        case .ai: AIModuleView()
        case .logs: LogsModuleView()
        case .virtualMachines: VirtualMachinesModuleView()
        case .alerts: AlertModuleView()
        }
    }
}

/// 设置子页路由：关于与法律文件。
enum SettingsPageRoute: String, Hashable, CaseIterable {
    case about
    case legal
}

/// 模块切换菜单：在模块任一页面右上角提供全部模块入口与回服务器首页，
/// 切换任意模块时详情页随之退出，服务器首页保持为层级根。
struct ModuleSwitcherMenu: View {
    @EnvironmentObject private var translations: TranslationsManager
    @EnvironmentObject private var navigation: ServerNavigation
    let current: ModuleRoute

    var body: some View {
        Menu {
            Section {
                if let server = serverRoute {
                    Button {
                        navigation.path = [server]
                    } label: {
                        Label(translations.get("serverHomeTitle", fallback: "Server Home"),
                              systemImage: "house")
                    }
                }
            }
            Section(translations.get("serverModulesTitle", fallback: "Modules")) {
                ForEach(ModuleRoute.allCases) { route in
                    Button {
                        navigation.switchModule(to: route)
                    } label: {
                        if route == current {
                            Label(route.title(translations), systemImage: "checkmark")
                        } else {
                            Label(route.title(translations), systemImage: route.icon)
                        }
                    }
                }
            }
        } label: {
            Label(translations.get("serverModulesTitle", fallback: "Modules"), systemImage: "square.grid.2x2")
        }
        .accessibilityIdentifier("server-switch-module")
    }

    private var serverRoute: ServerRoute? {
        navigation.path.first { element in
            if case .server = element { return true }
            return false
        }
    }
}
