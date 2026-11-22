import AppleSharedUI
import SwiftUI

struct StoreAppRow: Identifiable, Hashable {
    let appId: Int
    let name: String
    let key: String
    let type: String
    let versions: [String]
    let installed: Bool
    let description: String

    var id: Int { appId }

    init(payload: [String: Any]) {
        appId = payload["id"] as? Int ?? 0
        name = payload["name"] as? String ?? ""
        key = payload["key"] as? String ?? ""
        type = payload["type"] as? String ?? "app"
        versions = payload["versions"] as? [String] ?? []
        installed = payload["installed"] as? Bool ?? false
        description = payload["description"] as? String ?? ""
    }
}

struct AppInstallOption: Identifiable, Hashable {
    let value: String
    let label: String

    var id: String { value }

    init(payload: [String: Any]) {
        value = payload["value"] as? String ?? ""
        label = payload["label"] as? String ?? value
    }
}

struct AppInstallField: Identifiable {
    let envKey: String
    let key: String
    let labelZh: String
    let labelEn: String
    let type: String
    let required: Bool
    let defaultValue: String
    let values: [AppInstallOption]

    var id: String { envKey }

    init(payload: [String: Any]) {
        envKey = payload["envKey"] as? String ?? ""
        key = payload["key"] as? String ?? ""
        labelZh = payload["labelZh"] as? String ?? ""
        labelEn = payload["labelEn"] as? String ?? ""
        type = payload["type"] as? String ?? ""
        required = payload["required"] as? Bool ?? false
        defaultValue = payload["defaultValue"] as? String ?? ""
        values = (payload["values"] as? [[String: Any]] ?? []).map(AppInstallOption.init)
    }

    func label() -> String {
        let chinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
        let text = chinese ? labelZh : labelEn
        return text.isEmpty ? envKey : text
    }
}

struct AppInstallForm {
    let appDetailId: Int
    let fields: [AppInstallField]

    init(payload: [String: Any]) {
        appDetailId = payload["appDetailId"] as? Int ?? 0
        fields = (payload["fields"] as? [[String: Any]] ?? []).map(AppInstallField.init)
    }
}

/// macOS 应用商店：搜索应用并进入安装表单。
struct AppStoreSheet: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let onInstalled: () -> Void

    @State private var apps: [StoreAppRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    TextField(translations.get("appStoreSearchHint", fallback: "Search apps"),
                              text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await load() } }
                    Button {
                        Task { await load() }
                    } label: {
                        Label(translations.get("modelDownloaderSearchAction", fallback: "Search"),
                              systemImage: "magnifyingglass")
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Group {
                    if isLoading && apps.isEmpty {
                        LoadingView()
                    } else if let errorMessage, apps.isEmpty {
                        ErrorView(message: errorMessage) {
                            Task { await load() }
                        }
                    } else if apps.isEmpty {
                        EmptyStateView(
                            icon: "app.badge",
                            message: translations.get("appsListEmptyTitle", fallback: "No apps found")
                        )
                    } else {
                        List {
                            Section(translations.get("serverModuleApps", fallback: "Apps")) {
                                ForEach(apps) { app in
                                    NavigationLink(value: app) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(app.name).font(.subheadline.weight(.medium))
                                                if app.installed {
                                                    Text(translations.get("appStoreInstalledBadge",
                                                                          fallback: "Installed"))
                                                        .font(.caption2)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 1)
                                                        .background(Color.accentColor.opacity(0.15))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                            Text("\(app.key) · \(app.type)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if !app.description.isEmpty {
                                                Text(app.description)
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(2)
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }
                        .listStyle(.inset)
                        .refreshable {
                            await load()
                        }
                    }
                }
            }
            .navigationTitle(translations.get("appStoreTitle", fallback: "App Store"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
            }
            .navigationDestination(for: StoreAppRow.self) { app in
                AppInstallView(app: app, onInstalled: onInstalled)
            }
            .task {
                if apps.isEmpty {
                    await load()
                }
            }
        }
        .frame(minWidth: 760, minHeight: 600)
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getAppStore",
                arguments: ["search": searchText.trimmingCharacters(in: .whitespacesAndNewlines)]
            )
            apps = (raw as? [[String: Any]] ?? []).map(StoreAppRow.init)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// 应用安装表单：名称、版本、动态参数、高级选项与端口环境变量。
struct AppInstallView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let app: StoreAppRow
    let onInstalled: () -> Void

    @State private var name: String
    @State private var version: String
    @State private var versions: [String] = []
    @State private var form: AppInstallForm?
    @State private var fieldValues: [String: String] = [:]
    @State private var isLoadingForm = false
    @State private var showAdvanced = false
    @State private var containerName: String
    @State private var cpuQuota = ""
    @State private var memoryLimit = ""
    @State private var serviceRows: [AppKeyValueRow] = []
    @State private var paramRows: [AppKeyValueRow] = []
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(app: StoreAppRow, onInstalled: @escaping () -> Void) {
        self.app = app
        self.onInstalled = onInstalled
        _name = State(initialValue: app.name)
        _version = State(initialValue: app.versions.first ?? "")
        _containerName = State(initialValue: app.name)
    }

    var body: some View {
        Form {
            Section {
                TextField(translations.get("appInfoName", fallback: "Name"), text: $name)
                if !versions.isEmpty {
                    Picker(translations.get("appInfoVersion", fallback: "Version"),
                           selection: $version) {
                        ForEach(versions, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    .onChange(of: version) { value in
                        Task { await loadForm(version: value) }
                    }
                }
            }

            if isLoadingForm {
                Section {
                    ProgressView().controlSize(.small)
                }
            } else if let form, !form.fields.isEmpty {
                Section {
                    ForEach(form.fields) { field in
                        fieldView(field)
                    }
                }
            }

            Section {
                Toggle(translations.get("panelSettingsAdvanced", fallback: "Advanced"),
                       isOn: $showAdvanced)
                if showAdvanced {
                    TextField(translations.get("appInstallContainerName", fallback: "Container Name"),
                              text: $containerName)
                    TextField(translations.get("appInstallCpuLimit", fallback: "CPU Limit"),
                              text: $cpuQuota)
                    TextField(translations.get("appInstallMemoryLimit", fallback: "Memory Limit"),
                              text: $memoryLimit)
                }
            }

            if showAdvanced {
                Section(translations.get("appInstallPorts", fallback: "Ports")) {
                    keyValueRows($serviceRows,
                                 keyPlaceholder: translations.get("appInstallPortService",
                                                                  fallback: "Service Port"))
                    Button {
                        serviceRows.append(AppKeyValueRow())
                    } label: {
                        Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                    }
                }
                Section(translations.get("appInstallEnv", fallback: "Environment Variables")) {
                    keyValueRows($paramRows,
                                 keyPlaceholder: translations.get("appInstallEnvKey", fallback: "Key"))
                    Button {
                        paramRows.append(AppKeyValueRow())
                    } label: {
                        Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                    }
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("\(translations.get("appStoreInstall", fallback: "Install")) \(app.name)")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(translations.get("commonCancel", fallback: "Cancel")) {
                    dismiss()
                }
                .disabled(isSaving)
            }
            ToolbarItem(placement: .automatic) {
                if isSaving {
                    ProgressView().controlSize(.small)
                } else {
                    Button(translations.get("appStoreInstall", fallback: "Install")) {
                        Task { await install() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || form == nil
                              || isLoadingForm)
                }
            }
        }
        .task {
            await bootstrap()
        }
    }

    @ViewBuilder
    private func fieldView(_ field: AppInstallField) -> some View {
        let label = field.label()
        if (field.type == "select" || field.type == "apps" || field.type == "service"),
           !field.values.isEmpty {
            Picker(label, selection: binding(for: field)) {
                ForEach(field.values) { option in
                    Text(option.label).tag(option.value)
                }
            }
        } else {
            HStack {
                Text(label)
                Spacer(minLength: 12)
                TextField("", text: binding(for: field))
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    @ViewBuilder
    private func keyValueRows(_ rows: Binding<[AppKeyValueRow]>, keyPlaceholder: String) -> some View {
        ForEach(rows) { $row in
            HStack {
                TextField(keyPlaceholder, text: $row.key)
                TextField(translations.get("appInstallEnvValue", fallback: "Value"),
                          text: $row.value)
            }
        }
        .onDelete { indexSet in
            rows.wrappedValue.remove(atOffsets: indexSet)
        }
    }

    private func binding(for field: AppInstallField) -> Binding<String> {
        Binding(
            get: {
                fieldValues[field.envKey]
                    ?? field.defaultValue
                    ?? (field.values.first?.value ?? "")
            },
            set: { fieldValues[field.envKey] = $0 }
        )
    }

    private func bootstrap() async {
        errorMessage = nil
        if !app.versions.isEmpty {
            versions = app.versions
            if version.isEmpty { version = app.versions[0] }
            await loadForm(version: version)
            return
        }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getAppVersions",
                arguments: ["key": app.key]
            )
            let payload = raw as? [String: Any] ?? [:]
            versions = payload["versions"] as? [String] ?? []
            if let first = versions.first {
                version = first
                await loadForm(version: first)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadForm(version: String) async {
        isLoadingForm = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getAppInstallForm",
                arguments: ["appId": app.appId, "version": version, "type": app.type]
            )
            form = AppInstallForm(payload: raw as? [String: Any] ?? [:])
            fieldValues = [:]
            for field in form?.fields ?? [] {
                let initial = field.defaultValue.isEmpty
                    ? (field.values.first?.value ?? "")
                    : field.defaultValue
                if !initial.isEmpty {
                    fieldValues[field.envKey] = initial
                }
            }
            errorMessage = nil
        } catch {
            form = nil
            errorMessage = error.localizedDescription
        }
        isLoadingForm = false
    }

    private func install() async {
        guard let form else { return }
        isSaving = true
        var params: [String: String] = [:]
        for field in form.fields {
            if let value = fieldValues[field.envKey], !value.isEmpty {
                params[field.envKey] = value
            }
        }
        for row in paramRows where !row.key.isEmpty {
            params[row.key] = row.value
        }
        var services: [String: String] = [:]
        for row in serviceRows where !row.key.isEmpty {
            services[row.key] = row.value
        }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "installApp",
                arguments: [
                    "appDetailId": form.appDetailId,
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "type": app.type,
                    "params": params,
                    "advanced": showAdvanced,
                    "containerName": containerName,
                    "cpuQuota": cpuQuota,
                    "memoryLimit": memoryLimit,
                    "services": services,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                onInstalled()
                dismiss()
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("appOperateFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct AppKeyValueRow: Identifiable {
    let id = UUID()
    var key = ""
    var value = ""
}