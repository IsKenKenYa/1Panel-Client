import re

with open('macos/Runner/MacosSidebarViewController.swift', 'r') as f:
    content = f.read()

new_items = """    MacosSidebarItem(id: "servers", titleKey: "nav_servers", symbolName: "server.rack"),
    MacosSidebarItem(id: "files", titleKey: "nav_files", symbolName: "folder"),
    MacosSidebarItem(id: "apps", titleKey: "nav_apps", symbolName: "app.badge"),
    MacosSidebarItem(id: "websites", titleKey: "nav_websites", symbolName: "globe"),
    MacosSidebarItem(id: "monitoring", titleKey: "nav_monitoring", symbolName: "chart.xyaxis.line"),
    MacosSidebarItem(id: "containers", titleKey: "nav_containers", symbolName: "square.stack.3d.up"),
    MacosSidebarItem(id: "settings", titleKey: "nav_settings", symbolName: "gearshape"),"""

content = re.sub(r'    MacosSidebarItem\(id: "servers".*?    MacosSidebarItem\(id: "settings".*?\),', new_items, content, flags=re.DOTALL)

with open('macos/Runner/MacosSidebarViewController.swift', 'w') as f:
    f.write(content)
