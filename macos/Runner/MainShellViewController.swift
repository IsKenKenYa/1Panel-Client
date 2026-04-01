import Cocoa
import FlutterMacOS

final class MainShellViewController: NSSplitViewController, NSToolbarDelegate {
  private let flutterViewController: FlutterViewController
  private let sidebarViewController: MacosSidebarViewController
  private var shellChannel: FlutterMethodChannel?
  private var dataChannel: FlutterMethodChannel?
  private var currentModuleId: String?
  private var serversVC: MacosServersViewController?
  private var filesVC: MacosFilesViewController?
  private var appsVC: MacosAppsViewController?
  private var websitesVC: MacosWebsitesViewController?
  private var monitoringVC: MacosMonitoringViewController?
  private var containersVC: MacosContainersViewController?
  private var settingsVC: MacosSettingsViewController?
  private var contentHost: MacosFlutterContentHostViewController?
  private var contentItem: NSSplitViewItem?

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
    
    TranslationsManager.shared.load(methodChannel: dataChannel!) { [weak self] in
      DispatchQueue.main.async {
        self?.sidebarViewController.reloadData()
      }
    }

    sidebarViewController.onSelectModule = { [weak self] moduleId in
      self?.handleModuleSelection(moduleId: moduleId)
    }
  }

  private func handleModuleSelection(moduleId: String) {
    self.currentModuleId = moduleId
    if moduleId == "servers" {
      if serversVC == nil {
        serversVC = MacosServersViewController(methodChannel: dataChannel!)
      }
      switchToViewController(serversVC!)
    } else if moduleId == "files" {
      if filesVC == nil {
        filesVC = MacosFilesViewController(methodChannel: dataChannel!)
      }
      switchToViewController(filesVC!)
    } else if moduleId == "apps" {
      if appsVC == nil {
        appsVC = MacosAppsViewController(methodChannel: dataChannel!)
      }
      switchToViewController(appsVC!)
    } else if moduleId == "websites" {
      if websitesVC == nil {
        websitesVC = MacosWebsitesViewController(methodChannel: dataChannel!)
      }
      switchToViewController(websitesVC!)
    } else if moduleId == "monitoring" {
      if monitoringVC == nil {
        monitoringVC = MacosMonitoringViewController(methodChannel: dataChannel!)
      }
      switchToViewController(monitoringVC!)
    } else if moduleId == "containers" {
      if containersVC == nil {
        containersVC = MacosContainersViewController(methodChannel: dataChannel!)
      }
      switchToViewController(containersVC!)
    } else if moduleId == "settings" {
      if settingsVC == nil {
        settingsVC = MacosSettingsViewController()
      }
      switchToViewController(settingsVC!)
    } else {
      switchToViewController(contentHost!)
      self.shellChannel?.invokeMethod("selectModule", arguments: ["moduleId": moduleId])
    }
  }

  private func switchToViewController(_ vc: NSViewController) {
    guard let contentItem = contentItem else { return }
    if contentItem.viewController != vc {
      let newItem = NSSplitViewItem(viewController: vc)
      removeSplitViewItem(contentItem)
      addSplitViewItem(newItem)
      self.contentItem = newItem
    }
  }

  private func setupSplitView() {
    splitView.isVertical = true
    splitView.dividerStyle = .thin

    let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
    sidebarItem.minimumThickness = 240
    sidebarItem.maximumThickness = 360

    contentHost = MacosFlutterContentHostViewController(flutterViewController: flutterViewController)
    let contentItem = NSSplitViewItem(viewController: contentHost!)
    self.contentItem = contentItem

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
    dataChannel = FlutterMethodChannel(
      name: "com.onepanel.client/method",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
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



class MacosServersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let methodChannel: FlutterMethodChannel
    private var servers: [[String: Any]] = []
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        tableView.dataSource = self
        tableView.delegate = self
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = TranslationsManager.shared.get("server_name", fallback: "Name")
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("URL"))
        col2.title = TranslationsManager.shared.get("server_url", fallback: "URL")
        tableView.addTableColumn(col1)
        tableView.addTableColumn(col2)
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getServers", arguments: nil) { [weak self] result in
            if let servers = result as? [[String: Any]] {
                self?.servers = servers
                self?.tableView.reloadData()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return servers.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: "")
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        let server = servers[row]
        if tableColumn?.identifier.rawValue == "Name" {
            text.stringValue = server["name"] as? String ?? ""
        } else {
            text.stringValue = server["url"] as? String ?? ""
        }
        return text
    }
}

class MacosFilesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let methodChannel: FlutterMethodChannel
    private var files: [[String: Any]] = []
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        tableView.dataSource = self
        tableView.delegate = self
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask

        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = TranslationsManager.shared.get("server_name", fallback: "Name")
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Type"))
        col2.title = TranslationsManager.shared.get("file_type", fallback: "Type")
        tableView.addTableColumn(col1)
        tableView.addTableColumn(col2)
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getFiles", arguments: ["path": "/"]) { [weak self] result in
            if let files = result as? [[String: Any]] {
                self?.files = files
                self?.tableView.reloadData()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: "")
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        let file = files[row]
        if tableColumn?.identifier.rawValue == "Name" {
            text.stringValue = file["name"] as? String ?? ""
        } else {
            let isDir = file["isDir"] as? Bool ?? false
            text.stringValue = isDir ? TranslationsManager.shared.get("folder", fallback: "Folder") : TranslationsManager.shared.get("file", fallback: "File")
        }
        return text
    }
}

class MacosAppsViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let methodChannel: FlutterMethodChannel
    private var apps: [[String: Any]] = []
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        tableView.dataSource = self
        tableView.delegate = self
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask

        
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = TranslationsManager.shared.get("server_name", fallback: "Name")
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Status"))
        col2.title = TranslationsManager.shared.get("app_status", fallback: "Status")
        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Version"))
        col3.title = TranslationsManager.shared.get("app_version", fallback: "Version")
        
        tableView.addTableColumn(col1)
        tableView.addTableColumn(col2)
        tableView.addTableColumn(col3)
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getApps", arguments: nil) { [weak self] result in
            if let apps = result as? [[String: Any]] {
                self?.apps = apps
                self?.tableView.reloadData()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: "")
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        let app = apps[row]
        if tableColumn?.identifier.rawValue == "Name" {
            text.stringValue = app["name"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "Status" {
            text.stringValue = app["status"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "Version" {
            text.stringValue = app["version"] as? String ?? ""
        }
        return text
    }
}

class MacosWebsitesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let methodChannel: FlutterMethodChannel
    private var websites: [[String: Any]] = []
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        tableView.dataSource = self
        tableView.delegate = self
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask

        
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Domain"))
        col1.title = TranslationsManager.shared.get("website_domain", fallback: "Domain")
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Status"))
        col2.title = TranslationsManager.shared.get("app_status", fallback: "Status")
        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Remark"))
        col3.title = TranslationsManager.shared.get("website_remark", fallback: "Remark")
        
        tableView.addTableColumn(col1)
        tableView.addTableColumn(col2)
        tableView.addTableColumn(col3)
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getWebsites", arguments: nil) { [weak self] result in
            if let websites = result as? [[String: Any]] {
                self?.websites = websites
                self?.tableView.reloadData()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return websites.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: "")
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        let website = websites[row]
        if tableColumn?.identifier.rawValue == "Domain" {
            text.stringValue = website["primaryDomain"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "Status" {
            text.stringValue = website["status"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "Remark" {
            text.stringValue = website["remark"] as? String ?? ""
        }
        return text
    }
}
class MacosMonitoringViewController: NSViewController {
    private let methodChannel: FlutterMethodChannel
    private let scrollView = NSScrollView()
    private let stackView = NSStackView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        scrollView.documentView = stackView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentView.trailingAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getMonitoring", arguments: nil) { [weak self] result in
            if let metrics = result as? [String: Any] {
                self?.updateUI(with: metrics)
            }
        }
    }
    
    private func updateUI(with metrics: [String: Any]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let addMetric = { (title: String, value: Any) in
            let label = NSTextField(labelWithString: "\(title): \(value)")
            label.font = NSFont.systemFont(ofSize: 14)
            self.stackView.addArrangedSubview(label)
        }
        
        addMetric(TranslationsManager.shared.get("monitoring_cpu", fallback: "CPU"), "\(metrics["cpu"] ?? 0)%")
        addMetric(TranslationsManager.shared.get("monitoring_memory", fallback: "Memory"), "\(metrics["memory"] ?? 0)%")
        addMetric(TranslationsManager.shared.get("monitoring_disk", fallback: "Disk"), "\(metrics["disk"] ?? 0)%")
        addMetric(TranslationsManager.shared.get("monitoring_load1", fallback: "Load 1m"), metrics["load1"] ?? 0)
        addMetric(TranslationsManager.shared.get("monitoring_load5", fallback: "Load 5m"), metrics["load5"] ?? 0)
        addMetric(TranslationsManager.shared.get("monitoring_load15", fallback: "Load 15m"), metrics["load15"] ?? 0)
    }
}

class MacosSettingsViewController: NSViewController {
    private let titleLabel = NSTextField(labelWithString: TranslationsManager.shared.get("nav_settings", fallback: "Settings"))
    private let renderModeLabel = NSTextField(labelWithString: TranslationsManager.shared.get("settings_ui_mode", fallback: "UI Render Mode"))
    private let renderModePopUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let hintLabel = NSTextField(labelWithString: TranslationsManager.shared.get("settings_restart_hint", fallback: "Please restart the app for the UI render mode changes to take effect."))
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        
        renderModeLabel.translatesAutoresizingMaskIntoConstraints = false
        renderModeLabel.font = NSFont.systemFont(ofSize: 14)
        
        renderModePopUp.translatesAutoresizingMaskIntoConstraints = false
        renderModePopUp.addItems(withTitles: ["Native", "MDUI3"])
        
        // Load current setting
        let currentMode = UserDefaults.standard.string(forKey: "flutter.app_ui_render_mode") ?? "native"
        if currentMode == "md3" {
            renderModePopUp.selectItem(withTitle: "MDUI3")
        } else {
            renderModePopUp.selectItem(withTitle: "Native")
        }
        
        renderModePopUp.target = self
        renderModePopUp.action = #selector(modeChanged(_:))
        
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.font = NSFont.systemFont(ofSize: 12)
        hintLabel.textColor = NSColor.secondaryLabelColor
        hintLabel.isHidden = true
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(renderModeLabel)
        self.view.addSubview(renderModePopUp)
        self.view.addSubview(hintLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            
            renderModeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            renderModeLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 40),
            
            renderModePopUp.centerYAnchor.constraint(equalTo: renderModeLabel.centerYAnchor),
            renderModePopUp.leadingAnchor.constraint(equalTo: renderModeLabel.trailingAnchor, constant: 20),
            renderModePopUp.widthAnchor.constraint(equalToConstant: 120),
            
            hintLabel.topAnchor.constraint(equalTo: renderModePopUp.bottomAnchor, constant: 10),
            hintLabel.leadingAnchor.constraint(equalTo: renderModePopUp.leadingAnchor)
        ])
    }
    
    @objc private func modeChanged(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem else { return }
        let newValue = (title == "MDUI3") ? "md3" : "native"
        UserDefaults.standard.set(newValue, forKey: "flutter.app_ui_render_mode")
        UserDefaults.standard.synchronize()
        hintLabel.isHidden = false
    }
}

class MacosContainersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private let methodChannel: FlutterMethodChannel
    private var containers: [[String: Any]] = []
    private let scrollView = NSScrollView()
    private let tableView = NSTableView()
    
    init(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        self.view.addSubview(scrollView)
        
        tableView.dataSource = self
        tableView.delegate = self
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 44
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.gridStyleMask = .solidHorizontalGridLineMask
        
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = TranslationsManager.shared.get("container_name", fallback: "Name")
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Image"))
        col2.title = TranslationsManager.shared.get("container_image", fallback: "Image")
        let col3 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("State"))
        col3.title = TranslationsManager.shared.get("container_state", fallback: "State")
        
        tableView.addTableColumn(col1)
        tableView.addTableColumn(col2)
        tableView.addTableColumn(col3)
        
        scrollView.documentView = tableView
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        loadData()
    }
    
    private func loadData() {
        methodChannel.invokeMethod("getContainers", arguments: nil) { [weak self] result in
            if let containers = result as? [[String: Any]] {
                self?.containers = containers
                self?.tableView.reloadData()
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return containers.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let text = NSTextField(labelWithString: "")
        text.isEditable = false
        text.drawsBackground = false
        text.isBordered = false
        let container = containers[row]
        if tableColumn?.identifier.rawValue == "Name" {
            text.stringValue = container["name"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "Image" {
            text.stringValue = container["image"] as? String ?? ""
        } else if tableColumn?.identifier.rawValue == "State" {
            text.stringValue = container["state"] as? String ?? ""
        }
        return text
    }
}
