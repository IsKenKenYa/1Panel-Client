import SwiftUI

struct SidebarItem: Identifiable, Hashable {
    let id: String
    let titleKey: String
    let symbolName: String
}

struct SidebarView: View {
    @Binding var selectedModule: String?
    @EnvironmentObject var translations: TranslationsManager
    
    let items: [SidebarItem] = [
        SidebarItem(id: "dashboard", titleKey: "navDashboard", symbolName: "gauge.with.dots.needle.bottom.100percent"),
        SidebarItem(id: "servers", titleKey: "navServer", symbolName: "server.rack"),
        SidebarItem(id: "websites", titleKey: "serverModuleWebsites", symbolName: "globe"),
        SidebarItem(id: "databases", titleKey: "navDatabases", symbolName: "externaldrive.connected.to.line.below"),
        SidebarItem(id: "containers", titleKey: "serverModuleContainers", symbolName: "square.stack.3d.up"),
        SidebarItem(id: "apps", titleKey: "serverModuleApps", symbolName: "app.badge"),
        SidebarItem(id: "files", titleKey: "navFiles", symbolName: "folder"),
        SidebarItem(id: "monitoring", titleKey: "serverModuleMonitoring", symbolName: "chart.xyaxis.line"),
        SidebarItem(id: "firewall", titleKey: "navFirewall", symbolName: "network.badge.shield.half.filled"),
        SidebarItem(id: "cronjobs", titleKey: "navCronjob", symbolName: "timer"),
        SidebarItem(id: "backups", titleKey: "navBackup", symbolName: "archivebox"),
        SidebarItem(id: "ai", titleKey: "navAi", symbolName: "cpu.fill"),
        SidebarItem(id: "settings", titleKey: "navSettings", symbolName: "gearshape")
    ]
    
    var body: some View {
        List(selection: $selectedModule) {
            ForEach(items) { item in
                NavigationLink(value: item.id) {
                    Label {
                        Text(translations.get(item.titleKey, fallback: item.titleKey))
                    } icon: {
                        Image(systemName: item.symbolName)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
        // Using native sidebar material for true native look (Liquid Glass)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}
