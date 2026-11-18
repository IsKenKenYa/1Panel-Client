import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate, NSMenuItemValidation {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  @IBAction private func showSettings(_ sender: NSMenuItem) {
    guard let window = mainFlutterWindow,
          let shell = window.contentViewController as? MainShellViewController,
          shell.canShowSettings else { return }
    shell.showSettings()
    window.makeKeyAndOrderFront(sender)
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(showSettings(_:)) {
      return (mainFlutterWindow?.contentViewController as? MainShellViewController)?.canShowSettings == true
    }
    return true
  }
}
