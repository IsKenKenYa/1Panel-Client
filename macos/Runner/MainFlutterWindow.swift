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
        // Add a visual-effect overlay behind the traffic-light buttons so the
        // transparent titlebar area doesn't show raw wallpaper / desktop.
        self.addTitlebarVibrancyOverlay(to: flutterViewController.view)
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

  /// In md3 mode the Flutter content view covers the whole window including the
  /// transparent titlebar area.  We place a thin NSVisualEffectView behind the
  /// traffic-light buttons so the titlebar region has a consistent material
  /// background instead of showing raw desktop wallpaper.
  private func addTitlebarVibrancyOverlay(to contentView: NSView) {
    let titlebarHeight: CGFloat = 28
    let overlay = NSVisualEffectView()
    overlay.material = .titlebar
    overlay.blendingMode = .behindWindow
    overlay.state = .active
    overlay.wantsLayer = true
    overlay.translatesAutoresizingMaskIntoConstraints = false
    // Insert behind Flutter content so touches still reach Flutter
    contentView.addSubview(overlay, positioned: .below, relativeTo: nil)
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      overlay.topAnchor.constraint(equalTo: contentView.topAnchor),
      overlay.heightAnchor.constraint(equalToConstant: titlebarHeight),
    ])
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
