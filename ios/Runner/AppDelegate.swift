import Flutter
import UIKit
import SwiftUI

@main
struct RunnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let uiRenderMode = UIRenderMode.stored
    @State private var isUnlocked: Bool = false
    @StateObject private var security = SecurityViewModel()

    var body: some Scene {
        WindowGroup {
            if uiRenderMode != .native {
                FlutterViewControllerRepresentable(engine: appDelegate.flutterEngine)
                    .ignoresSafeArea()
            } else if security.appLockEnabled && !isUnlocked {
                AppLockGateView {
                    isUnlocked = true
                }
                .environmentObject(TranslationsManager.shared)
                .onAppear { TranslationsManager.shared.load { } }
            } else {
                AppShellView()
            }
        }
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
        TerminalSessionBridge.shared.setup(binaryMessenger: flutterEngine.binaryMessenger)
        ChannelManager.shared.seedDebugConfigIfNeeded()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
