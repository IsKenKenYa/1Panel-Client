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
    @State private var channel: FlutterMethodChannel?
    @State private var monitoring: [String: Any] = [:]

    var body: some View {
        TabView {
            ServersView(servers: servers, loadServers: loadServers)
                .tabItem {
                    Label("Servers", systemImage: "server.rack")
                }
            
            FilesView(files: files, loadFiles: loadFiles)
                .tabItem {
                    Label("Files", systemImage: "folder")
                }
                
            AppsView(apps: apps, loadApps: loadApps)
                .tabItem {
                    Label("Apps", systemImage: "app.badge")
                }
                
            WebsitesView(websites: websites, loadWebsites: loadWebsites)
                .tabItem {
                    Label("Websites", systemImage: "globe")
                }
                
            MonitoringView(metrics: monitoring, loadMonitoring: loadMonitoring)
                .tabItem {
                    Label("Monitoring", systemImage: "chart.xyaxis.line")
                }

            ZStack {
                Color.white.ignoresSafeArea()
                FlutterViewControllerRepresentable(engine: engine)
                    .ignoresSafeArea()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            
            NativeSettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            setupChannel()
        }
    }
    
    private func setupChannel() {
        if channel == nil {
            channel = FlutterMethodChannel(name: "com.onepanel.client/method", binaryMessenger: engine.binaryMessenger)
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
    
    var body: some View {
        NavigationView {
            List {
                ForEach(servers.indices, id: \.self) { index in
                    let server = servers[index]
                    VStack(alignment: .leading) {
                        Text(server["name"] as? String ?? "Unknown").font(.headline)
                        Text(server["url"] as? String ?? "").font(.subheadline).foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Servers")
            .onAppear(perform: loadServers)
        }
    }
}

struct FilesView: View {
    let files: [[String: Any]]
    let loadFiles: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(files.indices, id: \.self) { index in
                    let file = files[index]
                    HStack {
                        Image(systemName: (file["isDir"] as? Bool == true) ? "folder.fill" : "doc")
                        Text(file["name"] as? String ?? "Unknown")
                    }
                }
            }
            .navigationTitle("Files")
            .onAppear(perform: loadFiles)
        }
    }
}

struct AppsView: View {
    let apps: [[String: Any]]
    let loadApps: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(apps.indices, id: \.self) { index in
                    let app = apps[index]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(app["name"] as? String ?? "Unknown").font(.headline)
                            Text(app["version"] as? String ?? "").font(.subheadline).foregroundColor(.gray)
                        }
                        Spacer()
                        Text(app["status"] as? String ?? "").font(.subheadline)
                    }
                }
            }
            .navigationTitle("Apps")
            .onAppear(perform: loadApps)
        }
    }
}

struct WebsitesView: View {
    let websites: [[String: Any]]
    let loadWebsites: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(websites.indices, id: \.self) { index in
                    let website = websites[index]
                    HStack {
                        VStack(alignment: .leading) {
                            Text(website["primaryDomain"] as? String ?? "Unknown").font(.headline)
                            Text(website["remark"] as? String ?? "").font(.subheadline).foregroundColor(.gray)
                        }
                        Spacer()
                        Text(website["status"] as? String ?? "").font(.subheadline)
                    }
                }
            }
            .navigationTitle("Websites")
            .onAppear(perform: loadWebsites)
        }
    }
}

struct MonitoringView: View {
    let metrics: [String: Any]
    let loadMonitoring: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                HStack { Text("CPU"); Spacer(); Text("\(metrics["cpu"] as? Double ?? 0)%") }
                HStack { Text("Memory"); Spacer(); Text("\(metrics["memory"] as? Double ?? 0)%") }
                HStack { Text("Disk"); Spacer(); Text("\(metrics["disk"] as? Double ?? 0)%") }
                HStack { Text("Load 1m"); Spacer(); Text("\(metrics["load1"] as? Double ?? 0)") }
                HStack { Text("Load 5m"); Spacer(); Text("\(metrics["load5"] as? Double ?? 0)") }
                HStack { Text("Load 15m"); Spacer(); Text("\(metrics["load15"] as? Double ?? 0)") }
            }
            .navigationTitle("Monitoring")
            .onAppear(perform: loadMonitoring)
        }
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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("UI Render Mode")) {
                    Picker("Mode", selection: $uiRenderMode) {
                        Text("Native").tag("native")
                        Text("MDUI3").tag("md3")
                    }
                    .onChange(of: uiRenderMode) { _ in
                        showRestartHint = true
                    }
                    
                    if showRestartHint {
                        Text("Please restart the app for the UI render mode changes to take effect.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
