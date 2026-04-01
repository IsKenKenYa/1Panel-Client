import Cocoa
import FlutterMacOS

final class MainShellViewController: NSSplitViewController, NSToolbarDelegate {
  private let flutterViewController: FlutterViewController
  private let sidebarViewController: MacosSidebarViewController
  private var shellChannel: FlutterMethodChannel?
  private lazy var toolbar: NSToolbar = {
    let toolbar = NSToolbar(identifier: NSToolbar.Identifier("MainToolbar"))
    toolbar.delegate = self
    toolbar.displayMode = .iconOnly
    return toolbar
  }()

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    self.sidebarViewController = MacosSidebarViewController()
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupSplitView()
    setupShellChannel()

    sidebarViewController.onSelectModule = { [weak self] moduleId in
      self?.shellChannel?.invokeMethod("selectModule", arguments: ["moduleId": moduleId])
    }
  }

  private func setupSplitView() {
    splitView.isVertical = true
    splitView.dividerStyle = .thin

    let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
    sidebarItem.minimumThickness = 240
    sidebarItem.maximumThickness = 360

    let contentHost = MacosFlutterContentHostViewController(flutterViewController: flutterViewController)
    let contentItem = NSSplitViewItem(viewController: contentHost)

    addSplitViewItem(sidebarItem)
    addSplitViewItem(contentItem)
  }

  override func viewWillAppear() {
    super.viewWillAppear()
    if let window = view.window {
      window.toolbar = toolbar
      window.titleVisibility = .hidden
      window.titlebarAppearsTransparent = true
    }
  }

  private func setupShellChannel() {
    shellChannel = FlutterMethodChannel(
      name: "onepanel/macos_shell",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    shellChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterError(code: "window_unavailable", message: "Main window unavailable", details: nil))
        return
      }
      switch call.method {
      case "setTitle":
        if let args = call.arguments as? [String: Any],
           let title = args["title"] as? String {
          self.view.window?.title = title
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - NSToolbarDelegate

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [
      .toggleSidebar,
      NSToolbarItem.Identifier("shell.search"),
      .flexibleSpace,
    ]
  }

  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    return [
      .toggleSidebar,
      .flexibleSpace,
      NSToolbarItem.Identifier("shell.search"),
    ]
  }

  func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
    switch itemIdentifier.rawValue {
    case "shell.search":
      if #available(macOS 11.0, *) {
        let item = NSSearchToolbarItem(itemIdentifier: itemIdentifier)
        item.searchField.placeholderString = NSLocalizedString("shell_search_placeholder", comment: "")
        item.searchField.sendsSearchStringImmediately = true
        item.searchField.target = self
        item.searchField.action = #selector(onSearchChanged(_:))
        return item
      }
      let item = NSToolbarItem(itemIdentifier: itemIdentifier)
      item.label = NSLocalizedString("common_search", comment: "")
      item.paletteLabel = item.label
      item.toolTip = item.label
      item.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: item.label)
      return item
    default:
      return nil
    }
  }

  @objc private func onSearchChanged(_ sender: NSSearchField) {
    // Phase 1: reserve for future wiring (channel -> Flutter search for current module).
    // Keep empty to avoid imposing search semantics prematurely.
  }
}

final class MacosFlutterContentHostViewController: NSViewController {
  private let flutterViewController: FlutterViewController

  init(flutterViewController: FlutterViewController) {
    self.flutterViewController = flutterViewController
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    // Liquid Glass background for the content pane (behind Flutter).
    let visualEffectView = NSVisualEffectView()
    visualEffectView.material = .contentBackground
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.translatesAutoresizingMaskIntoConstraints = false
    self.view = NSView()
    view.wantsLayer = true
    view.addSubview(visualEffectView)

    let flutterView = flutterViewController.view
    flutterView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(flutterView)

    NSLayoutConstraint.activate([
      visualEffectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      visualEffectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      visualEffectView.topAnchor.constraint(equalTo: view.topAnchor),
      visualEffectView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      flutterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      flutterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      flutterView.topAnchor.constraint(equalTo: view.topAnchor),
      flutterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }
}
