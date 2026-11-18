import SwiftUI

/// 应用安装表单：名称、版本、动态参数，高级选项含容器名称、CPU/内存上限、端口映射与附加环境变量。
struct InstallAppSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AppsViewModel
    let app: StoreApp

    @State private var name: String
    @State private var version: String
    @State private var appVersions: [String] = []
    @State private var fieldValues: [String: String] = [:]
    @State private var showAdvanced = false
    @State private var containerName: String
    @State private var cpuQuota = ""
    @State private var memoryLimit = ""
    @State private var serviceRows: [KeyValueRow] = []
    @State private var paramRows: [KeyValueRow] = []
    @State private var isSaving = false
    @State private var errorText: String?

    init(viewModel: AppsViewModel, app: StoreApp) {
        self.viewModel = viewModel
        self.app = app
        _name = State(initialValue: app.name)
        _version = State(initialValue: app.versions.first ?? "")
        _containerName = State(initialValue: app.name)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && viewModel.installForm != nil
            && !viewModel.isFormLoading
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("appInfoName", fallback: "Name"), text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !appVersions.isEmpty {
                        Picker(translations.get("appInfoVersion", fallback: "Version"), selection: $version) {
                            ForEach(appVersions, id: \.self) { item in
                                Text(item).tag(item)
                            }
                        }
                        .onChange(of: version) { newValue in
                            loadForm(version: newValue)
                        }
                    }
                }

                if viewModel.isFormLoading {
                    Section {
                        ProgressView()
                    }
                } else if let form = viewModel.installForm, !form.fields.isEmpty {
                    Section {
                        ForEach(form.fields) { field in
                            fieldView(field)
                        }
                    }
                }

                Section {
                    Toggle(translations.get("panelSettingsAdvanced", fallback: "Advanced"), isOn: $showAdvanced)
                    if showAdvanced {
                        TextField(translations.get("appInstallContainerName", fallback: "Container Name"), text: $containerName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField(translations.get("appInstallCpuLimit", fallback: "CPU Limit"), text: $cpuQuota)
                            .keyboardType(.decimalPad)
                        TextField(translations.get("appInstallMemoryLimit", fallback: "Memory Limit"), text: $memoryLimit)
                            .keyboardType(.numberPad)
                    }
                }

                if showAdvanced {
                    Section(translations.get("appInstallPorts", fallback: "Ports")) {
                        keyValueRows(for: $serviceRows,
                                     keyPlaceholder: translations.get("appInstallPortService", fallback: "Service Port"))
                        Button {
                            serviceRows.append(KeyValueRow())
                        } label: {
                            Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                        }
                    }

                    Section(translations.get("appInstallEnv", fallback: "Environment Variables")) {
                        keyValueRows(for: $paramRows,
                                     keyPlaceholder: translations.get("appInstallEnvKey", fallback: "Key"))
                        Button {
                            paramRows.append(KeyValueRow())
                        } label: {
                            Label(translations.get("commonAdd", fallback: "Add"), systemImage: "plus")
                        }
                    }
                }

                if let errorText {
                    Section {
                        Text(errorText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(String(
                format: "%@ %@",
                translations.get("appStoreInstall", fallback: "Install"),
                app.name
            ))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(translations.get("appStoreInstall", fallback: "Install")) { save() }
                            .disabled(!canSave)
                    }
                }
            }
            .onAppear {
                bootstrap()
            }
        }
    }

    @ViewBuilder
    private func fieldView(_ field: AppInstallField) -> some View {
        let labelText = label(for: field)
        if field.type == "select", !field.values.isEmpty {
            Picker(labelText, selection: binding(for: field)) {
                ForEach(field.values, id: \.self) { value in
                    Text(value).tag(value)
                }
            }
        } else {
            TextField(labelText, text: binding(for: field))
                .keyboardType(field.type == "number" ? .decimalPad : .default)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    @ViewBuilder
    private func keyValueRows(for rows: Binding<[KeyValueRow]>, keyPlaceholder: String) -> some View {
        ForEach(rows) { $row in
            HStack {
                TextField(keyPlaceholder, text: $row.key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                TextField(translations.get("appInstallEnvValue", fallback: "Value"), text: $row.value)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .onDelete { indexSet in
            rows.wrappedValue.remove(atOffsets: indexSet)
        }
    }

    private func label(for field: AppInstallField) -> String {
        let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? false
        let text = isChinese ? field.labelZh : field.labelEn
        return text.isEmpty ? field.envKey : text
    }

    private func binding(for field: AppInstallField) -> Binding<String> {
        Binding(
            get: { fieldValues[field.envKey] ?? field.defaultValue ?? "" },
            set: { fieldValues[field.envKey] = $0 }
        )
    }

    private func bootstrap() {
        errorText = nil
        let provided = app.versions
        if !provided.isEmpty {
            appVersions = provided
            if version.isEmpty { version = provided[0] }
            loadForm(version: version)
            return
        }
        viewModel.fetchAppVersions(key: app.key) { versions in
            appVersions = versions
            if let first = versions.first {
                version = first
                loadForm(version: first)
            } else {
                errorText = translations.get("appOperateFailed", fallback: "Operation failed")
            }
        }
    }

    private func loadForm(version: String) {
        errorText = nil
        viewModel.fetchInstallForm(appId: app.id, version: version, type: app.type) { success in
            if !success {
                errorText = translations.get("appOperateFailed", fallback: "Operation failed")
            }
        }
    }

    private func save() {
        guard let form = viewModel.installForm else { return }
        errorText = nil
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
        viewModel.installApp(
            appDetailId: form.appDetailId,
            name: name.trimmingCharacters(in: .whitespaces),
            type: app.type,
            params: params,
            advanced: showAdvanced,
            containerName: containerName,
            cpuQuota: cpuQuota,
            memoryLimit: memoryLimit,
            services: services
        ) { success, error in
            isSaving = false
            if success {
                viewModel.fetchApps()
                dismiss()
            } else {
                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                errorText = template.replacingOccurrences(of: "{error}", with: error ?? "")
            }
        }
    }
}

/// 键值对行（端口映射与附加环境变量共用）。
struct KeyValueRow: Identifiable {
    let id = UUID()
    var key = ""
    var value = ""
}
