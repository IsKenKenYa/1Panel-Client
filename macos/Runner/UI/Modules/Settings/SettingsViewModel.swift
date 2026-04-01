import Foundation

class SettingsViewModel: ObservableObject {
    @Published var renderMode: String = "native"
    @Published var showRestartHint: Bool = false
    
    init() {
        self.renderMode = UserDefaults.standard.string(forKey: "flutter.app_ui_render_mode") ?? "native"
    }
    
    func updateRenderMode(_ mode: String) {
        self.renderMode = mode
        UserDefaults.standard.set(mode, forKey: "flutter.app_ui_render_mode")
        UserDefaults.standard.synchronize()
        self.showRestartHint = true
    }
}
