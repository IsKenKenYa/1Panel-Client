import re

with open('macos/Runner/MacosSidebarViewController.swift', 'r') as f:
    content = f.read()

content = content.replace('titleKey: "nav_servers"', 'titleKey: "navServer"')
content = content.replace('titleKey: "nav_files"', 'titleKey: "navFiles"')
content = content.replace('titleKey: "nav_apps"', 'titleKey: "serverModuleApps"')
content = content.replace('titleKey: "nav_websites"', 'titleKey: "serverModuleWebsites"')
content = content.replace('titleKey: "nav_monitoring"', 'titleKey: "serverModuleMonitoring"')
content = content.replace('titleKey: "nav_containers"', 'titleKey: "serverModuleContainers"')
content = content.replace('titleKey: "nav_settings"', 'titleKey: "navSettings"')

with open('macos/Runner/MacosSidebarViewController.swift', 'w') as f:
    f.write(content)
