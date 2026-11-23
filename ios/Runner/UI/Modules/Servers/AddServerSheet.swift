import SwiftUI

/// 服务器表单：新增（addServer 通道）与编辑（updateServer 通道）共用。
struct AddServerSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ServersViewModel

    /// 非空表示编辑模式（预填并走 updateServer）。
    var editingServer: ServerModel?

    @State private var name = ""
    @State private var url = ""
    @State private var apiKey = ""
    @State private var tokenValidity = "0"
    @State private var allowInsecureTls = false
    @State private var isSaving = false
    @State private var errorText: String?
    @State private var didPrefill = false

    private var isEditing: Bool { editingServer != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !url.trimmingCharacters(in: .whitespaces).isEmpty &&
            (editingServer?.url == url.trimmingCharacters(in: .whitespaces) ||
             !apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("serverFormName", fallback: "Name"), text: $name)
                    TextField(translations.get("serverFormUrl", fallback: "URL (https://host:port)"), text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(translations.get("serverFormApiKey", fallback: "API Key"), text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if isEditing, editingServer?.url == url.trimmingCharacters(in: .whitespaces) {
                        Text(translations.get("serverFormApiKeyKeepHint",
                                              fallback: "Leave empty to keep the saved key."))
                    }
                }
                Section {
                    TextField(
                        translations.get("serverTokenValidity",
                                         fallback: "Token validity (minutes)"),
                        text: $tokenValidity
                    )
                    .keyboardType(.numberPad)
                    Toggle(
                        translations.get("serverFormAllowInsecureTls",
                                         fallback: "Ignore TLS certificate validation"),
                        isOn: $allowInsecureTls
                    )
                } footer: {
                    Text(translations.get("serverTokenValidityHint",
                                          fallback: "Set to 0 to skip timestamp validation"))
                }
                if let errorText {
                    Section {
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(isEditing
                ? translations.get("commonEdit", fallback: "Edit")
                : translations.get("addServer", fallback: "Add Server"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(translations.get("commonSave", fallback: "Save")) {
                            save()
                        }
                        .disabled(!canSave)
                    }
                }
            }
            .onAppear {
                guard !didPrefill, let server = editingServer else { return }
                didPrefill = true
                name = server.name
                url = server.url
                tokenValidity = String(server.tokenValidity)
                allowInsecureTls = server.allowInsecureTls
            }
        }
    }

    private func save() {
        errorText = nil
        isSaving = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedUrl = url.trimmingCharacters(in: .whitespaces)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)
        let validity = Int(tokenValidity.trimmingCharacters(in: .whitespaces)) ?? 0
        let insecureTls = allowInsecureTls

        let finish: (Bool, String?) -> Void = { success, error in
            isSaving = false
            if success {
                viewModel.fetchServers()
                dismiss()
            } else {
                let template = translations.get(
                    "serverFormSaveFailed",
                    fallback: "Failed to save server: {error}"
                )
                errorText = template.replacingOccurrences(of: "{error}", with: error ?? "")
            }
        }

        if let server = editingServer {
            viewModel.updateServer(
                server: server,
                name: trimmedName,
                url: trimmedUrl,
                apiKey: trimmedKey,
                tokenValidity: validity,
                allowInsecureTls: insecureTls,
                completion: finish
            )
        } else {
            viewModel.addServer(
                name: trimmedName,
                url: trimmedUrl,
                apiKey: trimmedKey,
                tokenValidity: validity,
                allowInsecureTls: insecureTls,
                completion: finish
            )
        }
    }
}
