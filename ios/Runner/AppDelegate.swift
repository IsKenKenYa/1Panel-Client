import Flutter
import UIKit
import SwiftUI

@main
struct RunnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var uiRenderMode: String = "native"
    @State private var modeLoaded: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !modeLoaded {
                Color.white.ignoresSafeArea().onAppear {
                    loadRenderMode()
                }
            } else if uiRenderMode == "md3" {
                FlutterViewControllerRepresentable(engine: appDelegate.flutterEngine)
                    .ignoresSafeArea()
            } else {
                ContentView(engine: appDelegate.flutterEngine)
            }
        }
    }

    private func loadRenderMode() {
        let channel = FlutterMethodChannel(name: "com.onepanel.client/method", binaryMessenger: appDelegate.flutterEngine.binaryMessenger)
        channel.invokeMethod("getUIRenderMode", arguments: nil) { result in
            let mode = result as? String ?? "native"
            DispatchQueue.main.async {
                self.uiRenderMode = mode
                self.modeLoaded = true
            }
        }
    }
}

struct ContentView: View {
    let engine: FlutterEngine
    @State private var servers: [[String: Any]] = []
    @State private var files: [[String: Any]] = []
    @State private var apps: [[String: Any]] = []
    @State private var websites: [[String: Any]] = []
    @State private var containers: [[String: Any]] = []
    @State private var channel: FlutterMethodChannel?
    @State private var monitoring: [String: Any] = [:]
    @State private var translations: [String: String] = [:]

    var body: some View {
        TabView {
            ServersView(servers: servers, loadServers: loadServers, translations: translations)
                .tabItem {
                    Label(translations["nav_servers"] ?? "Servers", systemImage: "server.rack")
                }
            
            FilesView(files: files, loadFiles: loadFiles, translations: translations)
                .tabItem {
                    Label(translations["nav_files"] ?? "Files", systemImage: "folder")
                }
            
            ContainersView(containers: containers, loadContainers: loadContainers, translations: translations)
                .tabItem {
                    Label(translations["nav_containers"] ?? "Containers", systemImage: "cube.box")
                }
                
            AppsView(apps: apps, loadApps: loadApps, translations: translations)
                .tabItem {
                    Label(translations["nav_apps"] ?? "Apps", systemImage: "app.badge")
                }
                
            WebsitesView(websites: websites, loadWebsites: loadWebsites, translations: translations)
                .tabItem {
                    Label(translations["nav_websites"] ?? "Websites", systemImage: "globe")
                }
                
            MonitoringView(metrics: monitoring, loadMonitoring: loadMonitoring, translations: translations)
                .tabItem {
                    Label(translations["nav_monitoring"] ?? "Monitoring", systemImage: "chart.xyaxis.line")
                }

            ZStack {
                Color.white.ignoresSafeArea()
                FlutterViewControllerRepresentable(engine: engine)
                    .ignoresSafeArea()
            }
            .tabItem {
                Label("Flutter", systemImage: "ellipsis.circle")
            }
            
            NativeSettingsView(translations: translations)
                .tabItem {
                    Label(translations["nav_settings"] ?? "Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            setupChannel()
            loadTranslations()
        }
    }
    
    private func setupChannel() {
        if channel == nil {
            channel = FlutterMethodChannel(name: "com.onepanel.client/method", binaryMessenger: engine.binaryMessenger)
        }
    }
    
    private func loadTranslations() {
        channel?.invokeMethod("getTranslations", arguments: nil) { result in
            if let result = result as? [String: String] {
                DispatchQueue.main.async {
                    self.translations = result
                }
            }
        }
    }
    
    private func loadServers() {
        channel?.invokeMethod("getServers", arguments: nil) { result in
            if let result = result as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.servers = result
                }
            }
        }
    }
    
    private func loadFiles() {
        channel?.invokeMethod("getFiles", arguments: ["path": "/"]) { result in
            if let result = result as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.files = result
                }
            }
        }
    }
    
    private func loadContainers() {
        channel?.invokeMethod("getContainers", arguments: nil) { result in
            if let result = result as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.containers = result
                }
            }
        }
    }
    
    private func loadApps() {
        channel?.invokeMethod("getApps", arguments: nil) { result in
            if let result = result as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.apps = result
                }
            }
        }
    }
    
    private func loadWebsites() {
        channel?.invokeMethod("getWebsites", arguments: nil) { result in
            if let result = result as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.websites = result
                }
            }
        }
    }
    
    private func loadMonitoring() {
        channel?.invokeMethod("getMonitoring", arguments: nil) { result in
            if let result = result as? [String: Any] {
                DispatchQueue.main.async {
                    self.monitoring = result
                }
            }
        }
    }
}

struct ServersView: View {
    let servers: [[String: Any]]
    let loadServers: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(servers.indices, id: \.self) { index in
                    let server = servers[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(server["name"] as? String ?? "Unknown")
                                .font(.headline)
                            Spacer()
                            if server["isCurrent"] as? Bool == true {
                                Text(translations["server_status_online"] ?? "Current")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(8)
                            }
                        }
                        Text(server["url"] as? String ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "cpu")
                                    .foregroundColor(.blue)
                                Text(String(format: "%.1f%%", server["cpu"] as? Double ?? 0))
                                    .font(.caption)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "memorychip")
                                    .foregroundColor(.purple)
                                Text(String(format: "%.1f%%", server["memory"] as? Double ?? 0))
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_servers"] ?? "Servers")
            .onAppear(perform: loadServers)
        }
    }
}

struct FilesView: View {
    let files: [[String: Any]]
    let loadFiles: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(files.indices, id: \.self) { index in
                    let file = files[index]
                    HStack(spacing: 16) {
                        Image(systemName: (file["isDir"] as? Bool == true) ? "folder.fill" : "doc.fill")
                            .foregroundColor((file["isDir"] as? Bool == true) ? .blue : .gray)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(file["name"] as? String ?? "Unknown")
                                .font(.body)
                            
                            HStack {
                                if let size = file["size"] as? Int64, size > 0 {
                                    Text(formatSize(size))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let modTime = file["modTime"] as? Int64, modTime > 0 {
                                    Text(formatDate(modTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_files"] ?? "Files")
            .onAppear(perform: loadFiles)
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ timestamp: Int64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ContainersView: View {
    let containers: [[String: Any]]
    let loadContainers: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(containers.indices, id: \.self) { index in
                    let container = containers[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(container["name"] as? String ?? "Unknown")
                                .font(.headline)
                            Spacer()
                            Text(container["state"] as? String ?? "Unknown")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(stateColor(container["state"] as? String).opacity(0.2))
                                .foregroundColor(stateColor(container["state"] as? String))
                                .cornerRadius(8)
                        }
                        
                        Text(container["image"] as? String ?? "Unknown Image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            
                        HStack(spacing: 16) {
                            if let cpu = container["cpuUsage"] as? Double {
                                HStack(spacing: 4) {
                                    Image(systemName: "cpu")
                                        .foregroundColor(.blue)
                                    Text(String(format: "%.2f%%", cpu))
                                        .font(.caption)
                                }
                            }
                            if let mem = container["memoryUsage"] as? Double {
                                HStack(spacing: 4) {
                                    Image(systemName: "memorychip")
                                        .foregroundColor(.purple)
                                    Text(formatSize(Int64(mem)))
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_containers"] ?? "Containers")
            .onAppear(perform: loadContainers)
        }
    }
    
    private func stateColor(_ state: String?) -> Color {
        switch state?.lowercased() {
        case "running": return .green
        case "exited", "stopped": return .red
        case "paused": return .orange
        default: return .gray
        }
    }
    
    private func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

struct AppsView: View {
    let apps: [[String: Any]]
    let loadApps: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(apps.indices, id: \.self) { index in
                    let app = apps[index]
                    HStack(spacing: 16) {
                        Image(systemName: "app.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app["name"] as? String ?? "Unknown")
                                .font(.headline)
                            Text(app["version"] as? String ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(app["status"] as? String ?? "")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(app["status"] as? String).opacity(0.2))
                            .foregroundColor(statusColor(app["status"] as? String))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_apps"] ?? "Apps")
            .onAppear(perform: loadApps)
        }
    }
    
    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "installed", "running", "active": return .green
        case "error", "failed": return .red
        default: return .gray
        }
    }
}

struct WebsitesView: View {
    let websites: [[String: Any]]
    let loadWebsites: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(websites.indices, id: \.self) { index in
                    let website = websites[index]
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(website["primaryDomain"] as? String ?? "Unknown")
                                .font(.headline)
                            Spacer()
                            Text(website["status"] as? String ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(website["status"] as? String).opacity(0.2))
                                .foregroundColor(statusColor(website["status"] as? String))
                                .cornerRadius(8)
                        }
                        if let remark = website["remark"] as? String, !remark.isEmpty {
                            Text(remark)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_websites"] ?? "Websites")
            .onAppear(perform: loadWebsites)
        }
    }
    
    private func statusColor(_ status: String?) -> Color {
        switch status?.lowercased() {
        case "running", "active": return .green
        case "stopped": return .red
        default: return .gray
        }
    }
}

struct MonitoringView: View {
    let metrics: [String: Any]
    let loadMonitoring: () -> Void
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("System Usage")) {
                    MetricRow(
                        title: translations["dashboard_cpu_usage"] ?? "CPU",
                        value: String(format: "%.1f%%", metrics["cpu"] as? Double ?? 0),
                        icon: "cpu",
                        color: .blue
                    )
                    MetricRow(
                        title: translations["dashboard_memory_usage"] ?? "Memory",
                        value: String(format: "%.1f%%", metrics["memory"] as? Double ?? 0),
                        icon: "memorychip",
                        color: .purple
                    )
                    MetricRow(
                        title: translations["dashboard_disk_usage"] ?? "Disk",
                        value: String(format: "%.1f%%", metrics["disk"] as? Double ?? 0),
                        icon: "internaldrive",
                        color: .orange
                    )
                }
                
                Section(header: Text("Load Average")) {
                    MetricRow(
                        title: "1 Min",
                        value: String(format: "%.2f", metrics["load1"] as? Double ?? 0),
                        icon: "chart.xyaxis.line",
                        color: .green
                    )
                    MetricRow(
                        title: "5 Min",
                        value: String(format: "%.2f", metrics["load5"] as? Double ?? 0),
                        icon: "chart.xyaxis.line",
                        color: .green
                    )
                    MetricRow(
                        title: "15 Min",
                        value: String(format: "%.2f", metrics["load15"] as? Double ?? 0),
                        icon: "chart.xyaxis.line",
                        color: .green
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(translations["nav_monitoring"] ?? "Monitoring")
            .onAppear(perform: loadMonitoring)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            Text(title)
            Spacer()
            Text(value)
                .bold()
        }
        .padding(.vertical, 4)
    }
}

struct FlutterViewControllerRepresentable: UIViewControllerRepresentable {
    let engine: FlutterEngine
    
    func makeUIViewController(context: Context) -> FlutterViewController {
        let controller = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        controller.isViewOpaque = false
        controller.view.backgroundColor = .clear
        return controller
    }
    
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {
        // Handle updates if needed
    }
}

@objc class AppDelegate: FlutterAppDelegate {
  let flutterEngine = FlutterEngine(name: "my flutter engine")

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)
    
    // Set up method channel
    let channel = FlutterMethodChannel(name: "onepanel/ios_channel", binaryMessenger: flutterEngine.binaryMessenger)
    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "ping" {
            result("pong")
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

struct NativeSettingsView: View {
    @AppStorage("flutter.app_ui_render_mode") private var uiRenderMode: String = "native"
    @State private var showRestartHint = false
    let translations: [String: String]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(translations["settings_display"] ?? "Display")) {
                    Picker("UI Render Mode", selection: $uiRenderMode) {
                        Text("Native").tag("native")
                        Text("MDUI3").tag("md3")
                    }
                    .onChange(of: uiRenderMode) { _ in
                        showRestartHint = true
                    }
                    
                    if showRestartHint {
                        Text(translations["settings_restart_hint"] ?? "Please restart the app for the UI render mode changes to take effect.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(translations["nav_settings"] ?? "Settings")
        }
    }
}
