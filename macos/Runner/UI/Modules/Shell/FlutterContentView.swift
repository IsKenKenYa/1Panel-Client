import SwiftUI
import FlutterMacOS

struct FlutterContentView: NSViewControllerRepresentable {
    let flutterViewController: FlutterViewController
    
    func makeNSViewController(context: Context) -> NSViewController {
        let vc = NSViewController()
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = .contentBackground
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        vc.view = NSView()
        vc.view.wantsLayer = true
        vc.view.addSubview(visualEffectView)
        
        let flutterView = flutterViewController.view
        flutterView.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(flutterView)
        
        NSLayoutConstraint.activate([
            visualEffectView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            visualEffectView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
            flutterView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            flutterView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            flutterView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            flutterView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor),
        ])
        return vc
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}
