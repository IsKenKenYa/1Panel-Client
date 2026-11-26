import Flutter
import UIKit
import SwiftUI

@main
struct RunnerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let uiRenderMode = UIRenderMode.stored
    @State private var isUnlocked: Bool = false
    /// 种子写入完成前不放行原生界面，避免首帧读到空配置。
    @State private var configReady = false
    @StateObject private var security = SecurityViewModel()

    var body: some Scene {
        WindowGroup {
            if uiRenderMode != .native {
                FlutterViewControllerRepresentable(engine: appDelegate.flutterEngine)
                    .ignoresSafeArea()
            } else if !configReady {
                // 有种子配置时等写入完成；无种子时由 AppDelegate 立即放行。
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        appDelegate.waitForConfigReady {
                            configReady = true
                        }
                    }
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
    /// 配置就绪等待者：种子写入完成或确认无种子时放行。
    private var configReady = false
    private var configReadyCallbacks: [() -> Void] = []

    /// 配置就绪后回调；已就绪时立即执行。
    func waitForConfigReady(_ callback: @escaping () -> Void) {
        if configReady {
            callback()
            return
        }
        configReadyCallbacks.append(callback)
    }

    private func markConfigReady() {
        configReady = true
        let callbacks = configReadyCallbacks
        configReadyCallbacks = []
        callbacks.forEach { $0() }
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        flutterEngine.run()
        GeneratedPluginRegistrant.register(with: flutterEngine)
        ChannelManager.shared.setup(binaryMessenger: flutterEngine.binaryMessenger)
        TerminalSessionBridge.shared.setup(binaryMessenger: flutterEngine.binaryMessenger)
        ChannelManager.shared.seedDebugConfigIfNeeded { [weak self] in
            self?.markConfigReady()
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
