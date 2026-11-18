import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var appearanceChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let mode = MacOSRenderMode.stored
    let project = FlutterDartProject()
    let flutterEngine = FlutterEngine(name: "io.flutter", project: project)
    flutterEngine.run(withEntrypoint: nil)

    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    
    RegisterGeneratedPlugins(registry: flutterViewController)
    setupAppearanceChannel(with: flutterViewController)

    if mode.usesNativeShell {
      configureWindowForNativeShell()
      contentViewController = MainShellViewController(flutterViewController: flutterViewController)
    } else {
      configureWindowForFlutter()
      contentViewController = flutterViewController
    }
    setFrame(windowFrame, display: true)

    super.awakeFromNib()
  }

  private func configureWindowForFlutter() {
    titleVisibility = .hidden
    titlebarAppearsTransparent = false
    styleMask.remove(.fullSizeContentView)
    isOpaque = true
    backgroundColor = NSColor.windowBackgroundColor
  }

  private func configureWindowForNativeShell() {
    titleVisibility = .hidden
    toolbarStyle = .unified
    styleMask.insert(.fullSizeContentView)
    isOpaque = true
    backgroundColor = NSColor.windowBackgroundColor
    SettingsViewModel.applyTheme(UserDefaults.standard.string(forKey: "flutter.app_theme_mode"))
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
