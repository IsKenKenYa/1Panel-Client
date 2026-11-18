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
    @State private var isSaving = false
    @State private var errorText: String?
    @State private var didPrefill = false

    private var isEditing: Bool { editingServer != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !url.trimmingCharacters(in: .whitespaces).isEmpty &&
            // 编辑模式下 API Key 允许留空表示保持不变。
            (isEditing || !apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
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
                    if let errorText {
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
            }
        }
    }

    private func save() {
        errorText = nil
        isSaving = true
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedUrl = url.trimmingCharacters(in: .whitespaces)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespaces)

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
            // 编辑时 API Key 留空表示沿用原值。
            viewModel.updateServer(
                id: server.originalId,
                name: trimmedName,
                url: trimmedUrl,
                apiKey: trimmedKey.isEmpty ? "" : trimmedKey,
                completion: finish
            )
        } else {
            viewModel.addServer(
                name: trimmedName,
                url: trimmedUrl,
                apiKey: trimmedKey,
                completion: finish
            )
        }
    }
}
