import SwiftUI

struct SidebarItem: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let symbolName: String
}

/// macOS 侧栏：按 HIG 惯例分组（系统 / 功能模块 / 自动化），设置置底。
/// List(selection:) 直接驱动 NavigationSplitView 详情列。
struct SidebarView: View {
    @Binding var selectedModule: String?
    @EnvironmentObject var translations: TranslationsManager

    private let systemItems: [SidebarItem] = [
        SidebarItem(id: "dashboard", titleKey: "serverModuleDashboard", symbolName: "gauge.with.dots.needle.bottom.100percent"),
        SidebarItem(id: "monitoring", titleKey: "serverModuleMonitoring", symbolName: "chart.xyaxis.line"),
    ]

    private let moduleItems: [SidebarItem] = [
        SidebarItem(id: "servers", titleKey: "navServer", symbolName: "server.rack"),
        SidebarItem(id: "websites", titleKey: "serverModuleWebsites", symbolName: "globe"),
        SidebarItem(id: "databases", titleKey: "serverModuleDatabases", symbolName: "externaldrive.connected.to.line.below"),
        SidebarItem(id: "containers", titleKey: "serverModuleContainers", symbolName: "square.stack.3d.up"),
        SidebarItem(id: "apps", titleKey: "serverModuleApps", symbolName: "app.badge"),
        SidebarItem(id: "files", titleKey: "navFiles", symbolName: "folder"),
    ]

    private let automationItems: [SidebarItem] = [
        SidebarItem(id: "firewall", titleKey: "serverModuleFirewall", symbolName: "network.badge.shield.half.filled"),
        SidebarItem(id: "cronjobs", titleKey: "operationsCronjobsTitle", symbolName: "timer"),
        SidebarItem(id: "backups", titleKey: "operationsBackupsTitle", symbolName: "archivebox"),
        SidebarItem(id: "ai", titleKey: "serverModuleAi", symbolName: "cpu.fill"),
    ]

    private let settingsItem = SidebarItem(id: "settings", titleKey: "navSettings", symbolName: "gearshape")

    var body: some View {
        List(selection: $selectedModule) {
            Section(translations.get("operationsCenterSystemSectionTitle", fallback: "System")) {
                ForEach(systemItems) { item in
                    sidebarRow(item)
                }
            }

            Section(translations.get("serverModulesTitle", fallback: "Modules")) {
                ForEach(moduleItems) { item in
                    sidebarRow(item)
                }
            }

            Section(translations.get("operationsCenterAutomationSectionTitle", fallback: "Automation")) {
                ForEach(automationItems) { item in
                    sidebarRow(item)
                }
            }

            Section {
                sidebarRow(settingsItem)
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
    }

    @ViewBuilder
    private func sidebarRow(_ item: SidebarItem) -> some View {
        Label {
            Text(translations.get(item.titleKey, fallback: item.titleKey))
        } icon: {
            Image(systemName: item.symbolName)
        }
        .padding(.vertical, 4)
        .tag(item.id)
    }
}
