import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(translations.get("navSettings", fallback: "Settings"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(translations.get("settings_ui_mode", fallback: "UI Render Mode"))
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
                    Text(translations.get("settings_restart_hint", fallback: "Please restart the app for the UI render mode changes to take effect."))
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
    }
}
