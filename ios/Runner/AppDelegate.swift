import Flutter
import UIKit
import SwiftUI

@main
struct RunnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var uiRenderMode: String = "native"
    @State private var modeLoaded: Bool = false
    @State private var isUnlocked: Bool = false
    @StateObject private var security = SecurityViewModel()

    var body: some Scene {
        WindowGroup {
            if !modeLoaded {
                Color(UIColor.systemBackground).ignoresSafeArea().onAppear {
                    loadRenderMode()
                }
            } else if uiRenderMode == "md3" {
                FlutterViewControllerRepresentable(engine: appDelegate.flutterEngine)
                    .ignoresSafeArea()
            } else if security.appLockEnabled && !isUnlocked {
                AppLockGateView {
                    isUnlocked = true
                }
            } else {
                AppShellView(engine: appDelegate.flutterEngine)
            }
        }
    }

    private func loadRenderMode() {
        ChannelManager.shared.invokeDataMethod("getUIRenderMode") { result in
            let mode = result as? String ?? "native"
            DispatchQueue.main.async {
                self.uiRenderMode = mode
                self.modeLoaded = true
            }
        }
        // 启动门禁位于 AppShellView 之前，翻译字典需要提前加载。
        TranslationsManager.shared.load { }
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
        ChannelManager.shared.setup(binaryMessenger: flutterEngine.binaryMessenger)
        ChannelManager.shared.seedDebugConfigIfNeeded()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
