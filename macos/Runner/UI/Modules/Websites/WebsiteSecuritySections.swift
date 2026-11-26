import AppleSharedUI
import SwiftUI

/// CORS 配置。
struct WebsiteCorsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var enabled = false
    @State private var allowOrigins = "*"
    @State private var allowMethods = "GET,POST,OPTIONS,PUT,DELETE"
    @State private var allowHeaders = ""
    @State private var allowCredentials = false
    @State private var preflight = true
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle(translations.get("hostCorsEnable", fallback: "Enable CORS"),
                       isOn: $enabled)
                TextField(translations.get("hostCorsAllowOrigins", fallback: "Allowed origins"),
                          text: $allowOrigins)
                TextField(translations.get("hostCorsAllowMethods", fallback: "Allowed methods"),
                          text: $allowMethods)
                TextField(translations.get("hostCorsAllowHeaders", fallback: "Allowed headers"),
                          text: $allowHeaders)
                Toggle(translations.get("hostCorsAllowCredentials", fallback: "Allow credentials"),
                       isOn: $allowCredentials)
                Toggle(translations.get("hostCorsPreflight", fallback: "Preflight response"),
                       isOn: $preflight)
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(translations.get("commonSave", fallback: "Save"))
                    }
                }
                .disabled(isLoading || isSaving)
            }
        }
        .formStyle(.grouped)
        .operationNotice(statusMessage)
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteCors",
                arguments: ["id": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            if !dict.isEmpty {
                enabled = dict["cors"] as? Bool ?? false
                let origins = dict["allowOrigins"] as? String ?? ""
                if !origins.isEmpty { allowOrigins = origins }
                let methods = dict["allowMethods"] as? String ?? ""
                if !methods.isEmpty { allowMethods = methods }
                allowHeaders = dict["allowHeaders"] as? String ?? ""
                allowCredentials = dict["allowCredentials"] as? Bool ?? false
                preflight = dict["preflight"] as? Bool ?? true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteCors",
                arguments: [
                    "websiteID": websiteId,
                    "cors": enabled,
                    "allowOrigins": allowOrigins,
                    "allowMethods": allowMethods,
                    "allowHeaders": allowHeaders,
                    "allowCredentials": allowCredentials,
                    "preflight": preflight,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                showStatus(translations.get("hostCorsSaved", fallback: "CORS saved"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostCorsSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }
}

/// 防盗链配置。
struct WebsiteLeechSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var enabled = false
    @State private var extendsValue = "js,css,png,jpg,jpeg,gif,webp,webm,avif,ico,bmp,swf,eot,svg,ttf,woff,woff2"
    @State private var domainsText = ""
    @State private var noneRef = true
    @State private var blocked = false
    @State private var returnCode = "404"
    @State private var cache = false
    @State private var cacheTime = "30"
    @State private var cacheUnit = "d"
    @State private var logEnable = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section(translations.get("hostLeechExtends", fallback: "File extensions")) {
                TextField("", text: $extendsValue, axis: .vertical)
                    .lineLimit(2...4)
            }
            Section(translations.get("hostLeechProtection", fallback: "Anti-leech")) {
                Toggle(translations.get("hostLeechEnable", fallback: "Enable"), isOn: $enabled)
                if enabled {
                    TextField(translations.get("hostLeechAccessDomains", fallback: "Allowed domains"),
                              text: $domainsText, axis: .vertical)
                        .lineLimit(3...6)
                    Toggle(translations.get("hostLeechNoneRef", fallback: "Allow empty Referer"),
                           isOn: $noneRef)
                    Toggle(translations.get("hostLeechBlockedRef",
                                            fallback: "Allow non-standard Referer"),
                           isOn: $blocked)
                    Picker(translations.get("hostLeechReturn", fallback: "Response code"),
                           selection: $returnCode) {
                        Text("400").tag("400")
                        Text("403").tag("403")
                        Text("404").tag("404")
                    }
                }
            }
            Section(translations.get("hostLeechCacheControl", fallback: "Cache control")) {
                Toggle(translations.get("hostLeechBrowserCache", fallback: "Browser cache"),
                       isOn: $cache)
                if cache {
                    HStack {
                        TextField(translations.get("hostLeechCacheTime", fallback: "Cache time"),
                                  text: $cacheTime)
                        Picker("", selection: $cacheUnit) {
                            Text("s").tag("s")
                            Text("m").tag("m")
                            Text("h").tag("h")
                            Text("d").tag("d")
                            Text("w").tag("w")
                        }
                        .labelsHidden()
                        .frame(width: 70)
                    }
                }
                if cache || enabled {
                    Toggle(translations.get("hostLeechLogEnable", fallback: "Log requests"),
                           isOn: $logEnable)
                }
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(translations.get("commonSave", fallback: "Save"))
                    }
                }
                .disabled(isLoading || isSaving)
            }
        }
        .formStyle(.grouped)
        .operationNotice(statusMessage)
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteLeech",
                arguments: ["websiteID": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            if !dict.isEmpty {
                enabled = dict["enable"] as? Bool ?? false
                cache = dict["cache"] as? Bool ?? false
                let time = dict["cacheTime"] as? Int ?? 0
                cacheTime = time > 0 ? "\(time)" : "30"
                let unit = dict["cacheUnit"] as? String ?? dict["cacheUint"] as? String ?? ""
                cacheUnit = unit.isEmpty ? "d" : unit
                let extensions = dict["extends"] as? String ?? ""
                if !extensions.isEmpty { extendsValue = extensions }
                let code = dict["return"] as? String ?? ""
                returnCode = code.isEmpty ? "404" : code
                logEnable = dict["logEnable"] as? Bool ?? false
                noneRef = dict["noneRef"] as? Bool ?? true
                blocked = dict["blocked"] as? Bool ?? false
                let names = (dict["serverNames"] as? [Any])?.compactMap { $0 as? String } ?? []
                domainsText = names.joined(separator: "\n")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        let names = domainsText
            .split(whereSeparator: { $0 == "\n" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if enabled && names.isEmpty {
            errorMessage = translations.get("hostLeechDomainsRequired",
                                            fallback: "Allowed domains are required.")
            return
        }
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteLeech",
                arguments: [
                    "websiteID": websiteId,
                    "enable": enabled,
                    "extends": extendsValue,
                    "serverNames": names,
                    "noneRef": noneRef,
                    "blocked": blocked,
                    "return_": returnCode,
                    "cache": cache,
                    "cacheTime": Int(cacheTime.trimmingCharacters(in: .whitespaces)) ?? 30,
                    "cacheUint": cacheUnit,
                    "logEnable": logEnable,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                showStatus(translations.get("hostLeechSaved", fallback: "Anti-leech saved"))
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("hostLeechSaveFailed", fallback: "Save failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func showStatus(_ text: String) {
        statusMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if statusMessage == text {
                statusMessage = nil
            }
        }
    }
}

/// 网站证书列表（只读）。
struct WebsiteCertificatesSection: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var certificates: [WebsiteCertificateRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && certificates.isEmpty {
                LoadingView()
            } else if certificates.isEmpty {
                EmptyStateView(icon: "checkmark.seal",
                               message: translations.get("websiteCertificatesEmpty",
                                                         fallback: "No certificates"))
            } else {
                List {
                    Section(translations.get("websiteCertificatesTitle", fallback: "Certificates")) {
                        ForEach(certificates) { certificate in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(certificate.primaryDomain)
                                        .font(.subheadline.weight(.medium))
                                    Text(certificate.expireDate)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusBadge(text: certificate.status, color: .green)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await load()
                }
            }
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteCertificates"
            )
            certificates = (raw as? [[String: Any]] ?? []).map(WebsiteCertificateRow.init)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}