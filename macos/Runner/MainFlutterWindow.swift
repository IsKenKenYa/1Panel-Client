import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var appearanceChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let project = FlutterDartProject()
    let flutterEngine = FlutterEngine(name: "io.flutter", project: project)
    flutterEngine.run(withEntrypoint: nil)

    let flutterViewController = FlutterViewController(engine: flutterEngine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    
    // Apply base window config before mode is determined
    configureWindowBase()

    let methodChannel = FlutterMethodChannel(name: "com.onepanel.client/method", binaryMessenger: flutterViewController.engine.binaryMessenger)
    methodChannel.invokeMethod("getUIRenderMode", arguments: nil) { [weak self] result in
      guard let self = self else { return }
      let mode = result as? String ?? "native"
      if mode == "md3" {
        // md3: Flutter renders full window, make window transparent for liquid glass
        self.isOpaque = false
        self.backgroundColor = .clear
        self.contentViewController = flutterViewController
      } else {
        // native: keep system default opaque background so titlebar has material
        let shellViewController = MainShellViewController(flutterViewController: flutterViewController)
        self.contentViewController = shellViewController
      }
      self.setFrame(windowFrame, display: true)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    setupAppearanceChannel(with: flutterViewController)

    super.awakeFromNib()
  }

  /// Base window chrome config (applies to both native and md3 modes).
  private func configureWindowBase() {
    titlebarAppearsTransparent = true
    titleVisibility = .hidden
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
