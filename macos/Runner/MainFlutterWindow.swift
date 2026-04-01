import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var appearanceChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    configureVisualEffectWindow()
    setupAppearanceChannel(with: flutterViewController)

    super.awakeFromNib()
  }

  private func configureVisualEffectWindow() {
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
    isOpaque = false
    backgroundColor = .clear
  }

  private func setupAppearanceChannel(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "onepanel/macos_appearance",
      binaryMessenger: controller.engine.binaryMessenger
    )
    appearanceChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "window_unavailable", message: "Main window unavailable", details: nil))
        return
      }
      if call.method == "getAppearanceContext" {
        result(self.makeAppearancePayload())
        return
      }
      result(FlutterMethodNotImplemented)
    }
  }

  private func makeAppearancePayload() -> [String: Any] {
    let isDarkMode = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    let accessibility = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
    let reduceTransparency = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
    let scaleFactor = screen?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1.0

    return [
      "isDarkMode": isDarkMode,
      "isHighContrast": accessibility,
      "reduceTransparencyEnabled": reduceTransparency,
      "windowOpaque": isOpaque,
      "titlebarTransparent": titlebarAppearsTransparent,
      "backingScaleFactor": scaleFactor,
      "preferredGlassBlurSigma": reduceTransparency ? 0.0 : 18.0,
      "preferredSidebarAlpha": reduceTransparency ? 1.0 : 0.62,
      "preferredContentAlpha": reduceTransparency ? 1.0 : 0.86
    ]
  }
}
