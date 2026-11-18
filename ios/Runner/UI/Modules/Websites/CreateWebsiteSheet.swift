import SwiftUI

/// 创建网站表单：别名 / 类型 / 主域名 / 分组 / 备注，
/// 运行时追加运行环境与站点目录，反向代理追加代理类型、地址与端口，子站点追加父站点。
struct CreateWebsiteSheet: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WebsitesViewModel

    @State private var alias = ""
    @State private var type = "static"
    @State private var domain = ""
    @State private var groupId: Int?
    @State private var remark = ""
    @State private var runtimeId: Int?
    @State private var siteDir = ""
    @State private var proxyType = "http"
    @State private var proxy = ""
    @State private var port = ""
    @State private var parentWebsiteId: Int?
    @State private var isSaving = false
    @State private var validationText: String?

    private var canSave: Bool {
        !alias.trimmingCharacters(in: .whitespaces).isEmpty
            && !domain.trimmingCharacters(in: .whitespaces).isEmpty
            && groupId != nil
            && (type != "runtime" || runtimeId != nil)
            && (type != "proxy" || !proxy.trimmingCharacters(in: .whitespaces).isEmpty)
            && (type != "subsite" || parentWebsiteId != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("websitesAliasLabel", fallback: "Alias"), text: $alias)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker(translations.get("websitesLifecycleTypeLabel", fallback: "Website type"), selection: $type) {
                        Text(translations.get("websitesLifecycleTypeRuntime", fallback: "Runtime")).tag("runtime")
                        Text(translations.get("websitesLifecycleTypeProxy", fallback: "Proxy")).tag("proxy")
                        Text(translations.get("websitesLifecycleTypeSubsite", fallback: "Subsite")).tag("subsite")
                        Text(translations.get("websitesLifecycleTypeStatic", fallback: "Static")).tag("static")
                    }
                    TextField(translations.get("websitesPrimaryDomainLabel", fallback: "Primary Domain"), text: $domain)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker(translations.get("websitesGroupLabel", fallback: "Group"), selection: $groupId) {
                        ForEach(viewModel.createGroups) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }
                    TextField(translations.get("websitesRemarkLabel", fallback: "Remark"), text: $remark)
                }

                if type == "runtime" {
                    Section {
                        Picker(translations.get("websitesRuntimeLabel", fallback: "Runtime"), selection: $runtimeId) {
                            ForEach(viewModel.createRuntimes) { runtime in
                                Text(runtime.name).tag(Optional(runtime.id))
                            }
                        }
                        TextField(translations.get("websitesSiteDirLabel", fallback: "Site directory"), text: $siteDir)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }

                if type == "proxy" {
                    Section {
                        Picker(translations.get("websitesProxyTypeLabel", fallback: "Proxy type"), selection: $proxyType) {
                            Text("http").tag("http")
                            Text("tcp").tag("tcp")
                        }
                        TextField(translations.get("websitesProxyAddressLabel", fallback: "Proxy Address"), text: $proxy)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField(translations.get("websitesDomainPortLabel", fallback: "Port"), text: $port)
                            .keyboardType(.numberPad)
                    }
                }

                if type == "subsite" {
                    Section {
                        Picker(translations.get("websitesParentWebsiteLabel", fallback: "Parent website"), selection: $parentWebsiteId) {
                            ForEach(viewModel.createParents) { parent in
                                Text(parent.name).tag(Optional(parent.id))
                            }
                        }
                    }
                }

                if let validationText {
                    Section {
                        Text(validationText)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(translations.get("websitesLifecycleCreateTitle", fallback: "Create Website"))
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
                viewModel.fetchCreateOptions()
                if groupId == nil { groupId = viewModel.createGroups.first?.id }
                if runtimeId == nil { runtimeId = viewModel.createRuntimes.first?.id }
            }
            .onChange(of: viewModel.createGroups) { groups in
                if groupId == nil { groupId = groups.first?.id }
            }
            .onChange(of: viewModel.createRuntimes) { runtimes in
                if runtimeId == nil { runtimeId = runtimes.first?.id }
            }
        }
    }

    private func save() {
        validationText = nil
        if alias.trimmingCharacters(in: .whitespaces).isEmpty {
            validationText = translations.get("websitesValidationAliasRequired", fallback: "Alias is required.")
            return
        }
        if domain.trimmingCharacters(in: .whitespaces).isEmpty {
            validationText = translations.get("websitesValidationPrimaryDomainRequired", fallback: "Primary domain is required.")
            return
        }
        guard let groupId else {
            validationText = translations.get("websitesValidationGroupRequired", fallback: "Select a website group.")
            return
        }
        if type == "runtime" && runtimeId == nil {
            validationText = translations.get("websitesValidationRuntimeRequired", fallback: "Select a runtime.")
            return
        }
        if type == "proxy" && proxy.trimmingCharacters(in: .whitespaces).isEmpty {
            validationText = translations.get("websitesValidationProxyRequired", fallback: "Proxy address is required.")
            return
        }
        if type == "subsite" && parentWebsiteId == nil {
            validationText = translations.get("websitesValidationParentRequired", fallback: "Select a parent website.")
            return
        }

        isSaving = true
        viewModel.createWebsite(
            alias: alias.trimmingCharacters(in: .whitespaces),
            type: type,
            primaryDomain: domain.trimmingCharacters(in: .whitespaces),
            groupId: groupId,
            remark: remark.trimmingCharacters(in: .whitespaces),
            runtimeId: type == "runtime" ? runtimeId : nil,
            siteDir: siteDir.trimmingCharacters(in: .whitespaces),
            proxyType: proxyType,
            proxy: proxy.trimmingCharacters(in: .whitespaces),
            port: port.trimmingCharacters(in: .whitespaces),
            parentWebsiteId: type == "subsite" ? parentWebsiteId : nil
        ) { success, error in
            isSaving = false
            if success {
                viewModel.fetchWebsites()
                dismiss()
            } else {
                let template = translations.get(
                    "serverFormSaveFailed",
                    fallback: "Failed to save server: {error}"
                )
                validationText = template.replacingOccurrences(of: "{error}", with: error ?? "")
            }
        }
    }
}
