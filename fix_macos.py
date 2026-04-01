import re

with open('macos/Runner/MainShellViewController.swift', 'r') as f:
    content = f.read()

# remove everything starting from the FIRST class MacosServersViewController
content = re.sub(r'class MacosServersViewController:.*', '', content, flags=re.DOTALL)

new_content = content + '''
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
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = "Name"
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("URL"))
        col2.title = "URL"
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
        let col1 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        col1.title = "Name"
        let col2 = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Type"))
        col2.title = "Type"
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
            text.stringValue = isDir ? "Folder" : "File"
        }
        return text
    }
}
'''

with open('macos/Runner/MainShellViewController.swift', 'w') as f:
    f.write(new_content)
