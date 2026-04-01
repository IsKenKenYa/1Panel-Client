import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Form {
            Section(header: Text(translations.get("settings_ui_mode", fallback: "UI Render Mode")).font(.headline)) {
                Picker(translations.get("settings_ui_mode", fallback: "UI Render Mode"), selection: Binding(
                    get: { viewModel.renderMode },
                    set: { viewModel.updateRenderMode($0) }
                )) {
                    Text("Native").tag("native")
                    Text("MDUI3").tag("md3")
                }
                .pickerStyle(RadioGroupPickerStyle())
                
                if viewModel.showRestartHint {
                    Text(translations.get("settings_restart_hint", fallback: "Please restart the app for the UI render mode changes to take effect."))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(translations.get("navSettings", fallback: "Settings"))
    }
}
