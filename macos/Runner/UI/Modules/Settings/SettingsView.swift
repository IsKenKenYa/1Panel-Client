import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(TranslationsManager.shared.get("navSettings", fallback: "Settings"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            MDCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(TranslationsManager.shared.get("settings_ui_mode", fallback: "UI Render Mode"))
                            .font(.headline)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { viewModel.renderMode },
                            set: { viewModel.updateRenderMode($0) }
                        )) {
                            Text("Native").tag("native")
                            Text("MDUI3").tag("md3")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 120)
                    }
                    
                    if viewModel.showRestartHint {
                        Text(TranslationsManager.shared.get("settings_restart_hint", fallback: "Please restart the app for the UI render mode changes to take effect."))
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
    }
}
