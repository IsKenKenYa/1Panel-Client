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
        SidebarItem(id: "servers", titleKey: "navServer", symbolName: "server.rack"),
        SidebarItem(id: "files", titleKey: "navFiles", symbolName: "folder"),
        SidebarItem(id: "apps", titleKey: "serverModuleApps", symbolName: "app.badge"),
        SidebarItem(id: "websites", titleKey: "serverModuleWebsites", symbolName: "globe"),
        SidebarItem(id: "monitoring", titleKey: "serverModuleMonitoring", symbolName: "chart.xyaxis.line"),
        SidebarItem(id: "containers", titleKey: "serverModuleContainers", symbolName: "square.stack.3d.up"),
        SidebarItem(id: "settings", titleKey: "navSettings", symbolName: "gearshape")
    ]
    
    var body: some View {
        List(selection: $selectedModule) {
            ForEach(items) { item in
                NavigationLink(value: item.id) {
                    Label {
                        Text(TranslationsManager.shared.get(item.titleKey, fallback: item.titleKey))
                    } icon: {
                        Image(systemName: item.symbolName)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
    }
}
