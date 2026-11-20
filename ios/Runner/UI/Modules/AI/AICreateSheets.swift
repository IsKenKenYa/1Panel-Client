import SwiftUI

struct AIProviderRow: Identifiable {
    let provider: String
    let displayName: String
    let baseUrl: String
    let defaultApiType: String
    let apiTypes: [String]

    var id: String { provider }
}

/// 创建渠道账号。
struct AIAccountCreateSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var providers: [AIProviderRow] = []
    @State private var provider = ""
    @State private var name = ""
    @State private var apiKey = ""
    @State private var baseUrl = ""
    @State private var apiType = "openai-completions"
    @State private var remark = ""
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(translations.get("aiAgentsProvider", fallback: "Provider"),
                           selection: $provider) {
                        ForEach(providers) { item in
                            Text(item.displayName.isEmpty ? item.provider : item.displayName)
                                .tag(item.provider)
                        }
                    }
                    .onChange(of: provider) { value in
                        guard let info = providers.first(where: { $0.provider == value }) else {
                            return
                        }
                        if !info.baseUrl.isEmpty { baseUrl = info.baseUrl }
                        if !info.defaultApiType.isEmpty { apiType = info.defaultApiType }
                    }
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField(translations.get("aiAgentsApiKey", fallback: "API Key"),
                                text: $apiKey)
                    TextField(translations.get("aiAgentsBaseUrl", fallback: "Base URL"),
                              text: $baseUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    if selectedApiTypes.isEmpty {
                        TextField(translations.get("aiAgentsApiType", fallback: "API Type"),
                                  text: $apiType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        Picker(translations.get("aiAgentsApiType", fallback: "API Type"),
                               selection: $apiType) {
                            ForEach(selectedApiTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                    }
                    TextField(translations.get("commonDescription", fallback: "Description"),
                              text: $remark, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(translations.get("aiAgentsCreate", fallback: "Create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        submit()
                    }
                    .disabled(!canSubmit || submitting)
                }
            }
            .onAppear {
                fetchProviders()
            }
        }
    }

    private var canSubmit: Bool {
        !provider.isEmpty
            && !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
            && !baseUrl.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiType.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var selectedApiTypes: [String] {
        providers.first(where: { $0.provider == provider })?.apiTypes ?? []
    }

    private func fetchProviders() {
        guard providers.isEmpty else { return }
        ChannelManager.shared.invokeDataMethod("getAgentProviders") { result in
            DispatchQueue.main.async {
                guard let items = result as? [[String: Any]] else { return }
                providers = items.compactMap { item in
                    guard let provider = item["provider"] as? String, !provider.isEmpty else {
                        return nil
                    }
                    return AIProviderRow(
                        provider: provider,
                        displayName: item["displayName"] as? String ?? "",
                        baseUrl: item["baseUrl"] as? String ?? "",
                        defaultApiType: item["defaultApiType"] as? String ?? "",
                        apiTypes: (item["apiTypes"] as? [Any])?.compactMap { $0 as? String } ?? []
                    )
                }
                if provider.isEmpty, let first = providers.first {
                    provider = first.provider
                    baseUrl = first.baseUrl
                    if !first.defaultApiType.isEmpty {
                        apiType = first.defaultApiType
                    }
                }
            }
        }
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        ChannelManager.shared.invokeDataMethod(
            "createAgentAccountNative",
            arguments: [
                "provider": provider,
                "name": name.trimmingCharacters(in: .whitespaces),
                "apiKey": apiKey.trimmingCharacters(in: .whitespaces),
                "baseURL": baseUrl.trimmingCharacters(in: .whitespaces),
                "apiType": apiType.trimmingCharacters(in: .whitespaces),
                "remark": remark,
            ]
        ) { result in
            DispatchQueue.main.async {
                submitting = false
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    onCreated()
                    dismiss()
                }
            }
        }
    }
}

/// 创建 MCP 服务器。
struct AIMcpCreateSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var name = ""
    @State private var type = "stdio"
    @State private var command = ""
    @State private var outputTransport = "streamable_http"
    @State private var url = ""
    @State private var containerName = ""
    @State private var port = "8000"
    @State private var ssePath = ""
    @State private var streamableHttpPath = ""
    @State private var hostIP = ""
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiMcpTypeLabel", fallback: "Type"), text: $type)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiMcpCommandLabel", fallback: "Command"),
                              text: $command)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiMcpTransportLabel", fallback: "Transport"),
                              text: $outputTransport)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    TextField(translations.get("aiMcpBaseUrlLabel", fallback: "Base URL"),
                              text: $url)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    TextField(translations.get("aiMcpContainerLabel", fallback: "Container"),
                              text: $containerName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiMcpPortLabel", fallback: "Port"), text: $port)
                        .keyboardType(.numberPad)
                    TextField(translations.get("aiMcpHostIpLabel", fallback: "Host IP"),
                              text: $hostIP)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    TextField(translations.get("aiMcpSsePathLabel", fallback: "SSE path"),
                              text: $ssePath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiMcpStreamablePathLabel",
                                               fallback: "Streamable HTTP path"),
                              text: $streamableHttpPath)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle(translations.get("aiMcpDialogCreateTitle", fallback: "Create MCP server"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        submit()
                    }
                    .disabled(!canSubmit || submitting)
                }
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !command.trimmingCharacters(in: .whitespaces).isEmpty
            && !type.trimmingCharacters(in: .whitespaces).isEmpty
            && !outputTransport.trimmingCharacters(in: .whitespaces).isEmpty
            && !url.trimmingCharacters(in: .whitespaces).isEmpty
            && !containerName.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(port.trimmingCharacters(in: .whitespaces)) != nil
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        ChannelManager.shared.invokeDataMethod(
            "createMcpServerNative",
            arguments: [
                "name": name.trimmingCharacters(in: .whitespaces),
                "type": type.trimmingCharacters(in: .whitespaces),
                "command": command.trimmingCharacters(in: .whitespaces),
                "outputTransport": outputTransport.trimmingCharacters(in: .whitespaces),
                "url": url.trimmingCharacters(in: .whitespaces),
                "containerName": containerName.trimmingCharacters(in: .whitespaces),
                "port": Int(port.trimmingCharacters(in: .whitespaces)) ?? 0,
                "ssePath": ssePath,
                "streamableHttpPath": streamableHttpPath,
                "hostIP": hostIP,
            ]
        ) { result in
            DispatchQueue.main.async {
                submitting = false
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    onCreated()
                    dismiss()
                }
            }
        }
    }
}

/// 创建智能体实例。
struct AIAgentCreateSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss

    let onCreated: () -> Void

    @State private var agentType = "openclaw"
    @State private var name = "OpenClaw"
    @State private var appVersion = "latest"
    @State private var webUIPort = "18789"
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(translations.get("aiAgentsAgentType", fallback: "Agent type"),
                           selection: $agentType) {
                        Text(translations.get("aiAgentsOpenclaw", fallback: "OpenClaw"))
                            .tag("openclaw")
                        Text(translations.get("aiAgentsCopaw", fallback: "Copaw"))
                            .tag("copaw")
                    }
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiAgentsAppVersion", fallback: "Version"),
                              text: $appVersion)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("aiAgentsWebUiPort", fallback: "Web UI port"),
                              text: $webUIPort)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(translations.get("aiAgentsCreate", fallback: "Create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        submit()
                    }
                    .disabled(!canSubmit || submitting)
                }
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !appVersion.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(webUIPort.trimmingCharacters(in: .whitespaces)) != nil
    }

    private func submit() {
        guard canSubmit else { return }
        submitting = true
        ChannelManager.shared.invokeDataMethod(
            "createAgentNative",
            arguments: [
                "agentType": agentType,
                "name": name.trimmingCharacters(in: .whitespaces),
                "appVersion": appVersion.trimmingCharacters(in: .whitespaces),
                "webUIPort": Int(webUIPort.trimmingCharacters(in: .whitespaces)) ?? 0,
            ]
        ) { result in
            DispatchQueue.main.async {
                submitting = false
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                if success {
                    onCreated()
                    dismiss()
                }
            }
        }
    }
}