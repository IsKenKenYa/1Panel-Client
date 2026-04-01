import Cocoa

struct MacosSidebarItem {
  let id: String
  let titleKey: String
  let symbolName: String
}

final class MacosSidebarViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
  var onSelectModule: ((String) -> Void)?

  private let items: [MacosSidebarItem] = [
    MacosSidebarItem(id: "servers", titleKey: "nav_servers", symbolName: "server.rack"),
    MacosSidebarItem(id: "files", titleKey: "nav_files", symbolName: "folder"),
    MacosSidebarItem(id: "apps", titleKey: "nav_apps", symbolName: "app.badge"),
    MacosSidebarItem(id: "websites", titleKey: "nav_websites", symbolName: "globe"),
    MacosSidebarItem(id: "monitoring", titleKey: "nav_monitoring", symbolName: "chart.xyaxis.line"),
    MacosSidebarItem(id: "containers", titleKey: "nav_containers", symbolName: "square.stack.3d.up"),
    MacosSidebarItem(id: "settings", titleKey: "nav_settings", symbolName: "gearshape"),
  ]

  private let visualEffectView = NSVisualEffectView()
  private let scrollView = NSScrollView()
  private let tableView = NSTableView()

  override func loadView() {
    visualEffectView.material = .sidebar
    visualEffectView.blendingMode = .behindWindow
    visualEffectView.state = .active
    visualEffectView.translatesAutoresizingMaskIntoConstraints = false

    scrollView.hasVerticalScroller = true
    scrollView.drawsBackground = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
    column.resizingMask = .autoresizingMask
    tableView.addTableColumn(column)
    tableView.headerView = nil
    tableView.rowHeight = 36
    tableView.usesAlternatingRowBackgroundColors = false
    tableView.backgroundColor = .clear
    tableView.selectionHighlightStyle = .regular
    tableView.focusRingType = .default
    tableView.delegate = self
    tableView.dataSource = self

    scrollView.documentView = tableView

    let container = NSView()
    container.addSubview(visualEffectView)
    container.addSubview(scrollView)

    NSLayoutConstraint.activate([
      visualEffectView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      visualEffectView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      visualEffectView.topAnchor.constraint(equalTo: container.topAnchor),
      visualEffectView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
      scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      scrollView.topAnchor.constraint(equalTo: container.topAnchor),
      scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    self.view = container
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    if tableView.selectedRow < 0, !items.isEmpty {
      tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
      onSelectModule?(items[0].id)
    }
  }

  // MARK: - NSTableViewDataSource

  func numberOfRows(in tableView: NSTableView) -> Int {
    return items.count
  }

  // MARK: - NSTableViewDelegate

  func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    let item = items[row]
    let identifier = NSUserInterfaceItemIdentifier("cell")
    if let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
      configure(cell: cell, item: item)
      return cell
    }

    let cell = NSTableCellView()
    cell.identifier = identifier

    let imageView = NSImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)

    let textField = NSTextField(labelWithString: "")
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.lineBreakMode = .byTruncatingTail

    cell.addSubview(imageView)
    cell.addSubview(textField)
    cell.imageView = imageView
    cell.textField = textField

    NSLayoutConstraint.activate([
      imageView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 12),
      imageView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 16),
      imageView.heightAnchor.constraint(equalToConstant: 16),
      textField.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
      textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10),
      textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
    ])

    configure(cell: cell, item: item)
    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    let row = tableView.selectedRow
    guard row >= 0, row < items.count else { return }
    onSelectModule?(items[row].id)
  }

  private func configure(cell: NSTableCellView, item: MacosSidebarItem) {
    let title = NSLocalizedString(item.titleKey, comment: "")
    cell.textField?.stringValue = title
    if let image = NSImage(systemSymbolName: item.symbolName, accessibilityDescription: title) {
      cell.imageView?.image = image
    }
  }
}

