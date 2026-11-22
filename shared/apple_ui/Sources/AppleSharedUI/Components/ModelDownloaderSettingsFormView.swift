import SwiftUI

/// 模型下载设置表单，两端共用。
public struct ModelDownloaderSettingsFormView: View {
    @ObservedObject private var store: ModelDownloaderStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.translationsProvider) private var translations

    @State private var modelDir = ""
    @State private var hfEndpoint = ""
    @State private var hfToken = ""
    @State private var modelScopeEndpoint = ""
    @State private var modelScopeToken = ""
    @State private var featuredSync = true
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    public init(store: ModelDownloaderStore) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(t("modelDownloaderSettingsModelDirLabel", "Model directory"),
                              text: $modelDir)
                    Toggle(t("modelDownloaderSettingsFeaturedSyncLabel",
                             "Sync featured models automatically"),
                           isOn: $featuredSync)
                }
                Section(t("modelDownloaderSearchSourceHf", "Hugging Face")) {
                    TextField(t("modelDownloaderSettingsHfEndpointLabel", "Endpoint"),
                              text: $hfEndpoint)
                    SecureField(t("modelDownloaderSettingsHfTokenLabel", "Token"),
                                text: $hfToken)
                }
                Section(t("modelDownloaderSearchSourceModelScope", "ModelScope")) {
                    TextField(t("modelDownloaderSettingsModelScopeEndpointLabel", "Endpoint"),
                              text: $modelScopeEndpoint)
                    SecureField(t("modelDownloaderSettingsModelScopeTokenLabel", "Token"),
                                text: $modelScopeToken)
                }
            }
            .navigationTitle(t("modelDownloaderSettingsTitle", "Download Settings"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonCancel", "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(t("commonSave", "Save")) {
                        Task { await save() }
                    }
                    .disabled(isSaving || isLoading || modelDir.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .task {
                await load()
            }
            .alert(
                t("commonError", "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(t("commonOk", "OK"), role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 520, minHeight: 560)
            #endif
        }
    }

    private func load() async {
        isLoading = true
        await store.loadSettings()
        if let error = store.settingsError {
            errorMessage = error
        } else {
            let settings = store.settings
            modelDir = settings.modelDir
            hfEndpoint = settings.hfEndpoint
            hfToken = settings.hfToken
            modelScopeEndpoint = settings.modelScopeEndpoint
            modelScopeToken = settings.modelScopeToken
            featuredSync = settings.featuredSyncEnabled
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        let error = await store.saveSettings([
            "modelDir": modelDir.trimmingCharacters(in: .whitespacesAndNewlines),
            "featuredSync": featuredSync,
            "hfEndpoint": hfEndpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            "hfToken": hfToken.trimmingCharacters(in: .whitespacesAndNewlines),
            "modelScopeEndpoint": modelScopeEndpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            "modelScopeToken": modelScopeToken.trimmingCharacters(in: .whitespacesAndNewlines),
        ])
        isSaving = false
        if let error {
            errorMessage = error
        } else {
            dismiss()
        }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}