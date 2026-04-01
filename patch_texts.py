import re

with open('macos/Runner/MainShellViewController.swift', 'r') as f:
    content = f.read()

# MacosServersViewController
content = content.replace('col1.title = "Name"', 'col1.title = TranslationsManager.shared.get("server_name", fallback: "Name")')
content = content.replace('col2.title = "URL"', 'col2.title = TranslationsManager.shared.get("server_url", fallback: "URL")')

# MacosFilesViewController
content = content.replace('col2.title = "Type"', 'col2.title = TranslationsManager.shared.get("file_type", fallback: "Type")')
content = content.replace('isDir ? "Folder" : "File"', 'isDir ? TranslationsManager.shared.get("folder", fallback: "Folder") : TranslationsManager.shared.get("file", fallback: "File")')

# MacosAppsViewController
content = content.replace('col2.title = "Status"', 'col2.title = TranslationsManager.shared.get("app_status", fallback: "Status")')
content = content.replace('col3.title = "Version"', 'col3.title = TranslationsManager.shared.get("app_version", fallback: "Version")')

# MacosWebsitesViewController
content = content.replace('col1.title = "Domain"', 'col1.title = TranslationsManager.shared.get("website_domain", fallback: "Domain")')
content = content.replace('col3.title = "Remark"', 'col3.title = TranslationsManager.shared.get("website_remark", fallback: "Remark")')

# MacosMonitoringViewController
content = content.replace('addMetric("CPU",', 'addMetric(TranslationsManager.shared.get("monitoring_cpu", fallback: "CPU"),')
content = content.replace('addMetric("Memory",', 'addMetric(TranslationsManager.shared.get("monitoring_memory", fallback: "Memory"),')
content = content.replace('addMetric("Disk",', 'addMetric(TranslationsManager.shared.get("monitoring_disk", fallback: "Disk"),')
content = content.replace('addMetric("Load 1m",', 'addMetric(TranslationsManager.shared.get("monitoring_load1", fallback: "Load 1m"),')
content = content.replace('addMetric("Load 5m",', 'addMetric(TranslationsManager.shared.get("monitoring_load5", fallback: "Load 5m"),')
content = content.replace('addMetric("Load 15m",', 'addMetric(TranslationsManager.shared.get("monitoring_load15", fallback: "Load 15m"),')

# MacosSettingsViewController
content = content.replace('labelWithString: "Settings"', 'labelWithString: TranslationsManager.shared.get("nav_settings", fallback: "Settings")')
content = content.replace('labelWithString: "UI Render Mode"', 'labelWithString: TranslationsManager.shared.get("settings_ui_mode", fallback: "UI Render Mode")')
content = content.replace('labelWithString: "Please restart the app for the UI render mode changes to take effect."', 'labelWithString: TranslationsManager.shared.get("settings_restart_hint", fallback: "Please restart the app for the UI render mode changes to take effect.")')

with open('macos/Runner/MainShellViewController.swift', 'w') as f:
    f.write(content)
