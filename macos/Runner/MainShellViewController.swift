import Cocoa
import FlutterMacOS
import SwiftUI

final class MainShellViewController: NSHostingController<MainShellView> {
    private let navigation: MainShellNavigation
    private let appLock: MacOSAppLockController

    var canShowSettings: Bool { !appLock.isLocked }

    init(flutterViewController: FlutterViewController) {
        let navigation = MainShellNavigation()
        let appLock = MacOSAppLockController()
        self.navigation = navigation
        self.appLock = appLock
        ChannelManager.shared.setup(binaryMessenger: flutterViewController.engine.binaryMessenger)
        TerminalSessionBridge.shared.setup(binaryMessenger: flutterViewController.engine.binaryMessenger)
        super.init(rootView: MainShellView(
            navigation: navigation,
            appLock: appLock,
            flutterViewController: flutterViewController
        ))
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showSettings() {
        guard canShowSettings else { return }
        navigation.selectedModule = "settings"
    }
}
