import Cocoa
import FlutterMacOS
import SwiftUI

final class MainShellViewController: NSViewController {
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
        self.view = NSView()
        self.view.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize ChannelManager with the Flutter engine's messenger
        ChannelManager.shared.setup(binaryMessenger: flutterViewController.engine.binaryMessenger)
        
        let renderMode = UserDefaults.standard.string(forKey: "flutter.app_ui_render_mode") ?? "native"
        
        if renderMode == "md3" {
            // Render MDUI3 using Dart code directly
            let flutterView = flutterViewController.view
            flutterView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(flutterView)
            
            NSLayoutConstraint.activate([
                flutterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                flutterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                flutterView.topAnchor.constraint(equalTo: view.topAnchor),
                flutterView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            // Render True Native UI
            let mainShellView = MainShellView(flutterViewController: flutterViewController)
            let hostingController = NSHostingController(rootView: mainShellView)
            
            addChild(hostingController)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        if let window = view.window {
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }
    }
}
