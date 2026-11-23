import AppleSharedUI
import SwiftUI

/// iOS 网站代理缓存分区。
struct WebsiteProxyCacheView: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var open = false
    @State private var cacheLimit = "1"
    @State private var cacheLimitUnit = "g"
    @State private var shareCache = "5"
    @State private var shareCacheUnit = "m"
    @State private var cacheExpire = "24"
    @State private var cacheExpireUnit = "h"
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var isClearing = false
    @State private var showClearConfirm = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    private static let sizeUnits = ["b", "k", "m", "g"]
    private static let timeUnits = ["s", "m", "h", "d", "w", "M", "y"]

    var body: some View {
        Form {
            Section {
                Toggle(translations.get("websitesCacheEnableLabel", fallback: "Enable cache"),
                       isOn: $open)
            }
            if open {
                Section {
                    HStack {
                        TextField(translations.get("websitesCacheLimitLabel",
                                                   fallback: "Cache limit"),
                                  text: $cacheLimit)
                            .keyboardType(.numberPad)
                        Picker("", selection: $cacheLimitUnit) {
                            ForEach(Self.sizeUnits, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                    HStack {
                        TextField(translations.get("websitesCacheShareLabel",
                                                   fallback: "Shared cache"),
                                  text: $shareCache)
                            .keyboardType(.numberPad)
                        Picker("", selection: $shareCacheUnit) {
                            ForEach(Self.sizeUnits, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                    HStack {
                        TextField(translations.get("websitesCacheExpireLabel",
                                                   fallback: "Cache expiry"),
                                  text: $cacheExpire)
                            .keyboardType(.numberPad)
                        Picker("", selection: $cacheExpireUnit) {
                            ForEach(Self.timeUnits, id: \.self) { Text($0).tag($0) }
                        }
                        .labelsHidden()
                    }
                } footer: {
                    Text(translations.get("websitesCacheLimitHint",
                                          fallback: "Limits apply to the proxy cache on the panel server."))
                }
            }
            Section {
                saveButton
                Button {
                    showClearConfirm = true
                } label: {
                    if isClearing {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(translations.get("websitesCacheClearAction",
                                              fallback: "Clear proxy cache"))
                    }
                }
                .disabled(isLoading || isSaving || isClearing || !open)
            }
            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(translations.get("websitesCacheTitle", fallback: "Proxy Cache"))
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            translations.get("websitesCacheClearConfirm",
                             fallback: "Clear proxy cache?"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("websitesCacheClearAction",
                                    fallback: "Clear proxy cache"),
                   role: .destructive) {
                Task { await clearCache() }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"),
                   role: .cancel) {}
        } message: {
            Text(translations.get("websitesCacheClearMessage",
                                  fallback: "Cached responses for this website will be removed from the panel server."))
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

    private var saveButton: some View {
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

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteProxyCache",
                arguments: ["id": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            open = dict["open"] as? Bool ?? false
            cacheLimit = "\(dict["cacheLimit"] as? Int ?? 1)"
            cacheLimitUnit = dict["cacheLimitUnit"] as? String ?? "g"
            shareCache = "\(dict["shareCache"] as? Int ?? 5)"
            shareCacheUnit = dict["shareCacheUnit"] as? String ?? "m"
            cacheExpire = "\(dict["cacheExpire"] as? Int ?? 24)"
            cacheExpireUnit = dict["cacheExpireUnit"] as? String ?? "h"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func clearCache() async {
        isClearing = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "clearWebsiteProxyCache",
                arguments: ["id": websiteId]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                statusMessage = translations.get("websitesCacheClearSuccess",
                                                 fallback: "Proxy cache cleared")
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isClearing = false
    }

    private func save() async {
        guard let limit = Int(cacheLimit), let share = Int(shareCache),
              let expire = Int(cacheExpire),
              (0...9999).contains(limit), (0...9999).contains(share),
              (0...9999).contains(expire) else {
            errorMessage = translations.get("websitesCacheNumberHint",
                                            fallback: "Enter a number between 0 and 9999.")
            return
        }
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteProxyCache",
                arguments: [
                    "websiteID": websiteId,
                    "open": open,
                    "cacheLimit": limit,
                    "cacheLimitUnit": cacheLimitUnit,
                    "shareCache": share,
                    "shareCacheUnit": shareCacheUnit,
                    "cacheExpire": expire,
                    "cacheExpireUnit": cacheExpireUnit,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                statusMessage = translations.get("commonOperationSuccess",
                                                 fallback: "Operation succeeded")
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

/// iOS 网站真实 IP 分区。
struct WebsiteRealIPView: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var open = false
    @State private var ipFrom = "127.0.0.1"
    @State private var ipHeader = "X-Real-IP"
    @State private var ipOther = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    private static let headers = ["X-Forwarded-For", "X-Real-IP", "CF-Connecting-IP", "other"]

    var body: some View {
        Form {
            Section {
                Toggle(translations.get("websitesRealIpEnableLabel",
                                        fallback: "Enable real IP"),
                       isOn: $open)
            }
            if open {
                Section {
                    TextEditor(text: $ipFrom)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 120)
                    Picker(translations.get("websitesRealIpHeaderLabel",
                                            fallback: "IP header"),
                           selection: $ipHeader) {
                        ForEach(Self.headers, id: \.self) { Text($0).tag($0) }
                    }
                    if ipHeader == "other" {
                        TextField(translations.get("websitesRealIpOtherLabel",
                                                   fallback: "Custom header"),
                                  text: $ipOther)
                    }
                } header: {
                    Text(translations.get("websitesRealIpFromLabel",
                                          fallback: "Trusted source addresses"))
                } footer: {
                    Text(translations.get("websitesRealIpFromHint",
                                          fallback: "One CIDR or address per line."))
                }
            }
            Section {
                saveButton
            }
            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(translations.get("websitesRealIpTitle", fallback: "Real IP"))
        .navigationBarTitleDisplayMode(.inline)
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

    private var saveButton: some View {
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

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteRealIP",
                arguments: ["id": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            open = dict["open"] as? Bool ?? false
            let from = dict["ipFrom"] as? String ?? ""
            if !from.isEmpty { ipFrom = from }
            let header = dict["ipHeader"] as? String ?? ""
            if !header.isEmpty { ipHeader = header }
            ipOther = dict["ipOther"] as? String ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        let from = ipFrom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !open || !from.isEmpty else {
            errorMessage = translations.get("websitesRealIpFromRequired",
                                            fallback: "Enter the trusted source addresses.")
            return
        }
        guard !open || ipHeader != "other"
                || !ipOther.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = translations.get("websitesRealIpOtherRequired",
                                            fallback: "Enter the custom header name.")
            return
        }
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteRealIP",
                arguments: [
                    "websiteID": websiteId,
                    "open": open,
                    "ipFrom": from,
                    "ipHeader": ipHeader,
                    "ipOther": ipOther.trimmingCharacters(in: .whitespaces),
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                statusMessage = translations.get("commonOperationSuccess",
                                                 fallback: "Operation succeeded")
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

/// iOS 网站 TCP/UDP 转发分区。
struct WebsiteStreamView: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var streamPorts = ""
    @State private var udp = false
    @State private var name = ""
    @State private var algorithm = ""
    @State private var servers: [[String: Any]] = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                TextField(translations.get("websitesStreamPortsLabel",
                                           fallback: "Forwarding ports"),
                          text: $streamPorts)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Toggle(translations.get("websitesStreamUdpLabel", fallback: "UDP"),
                       isOn: $udp)
            } footer: {
                Text(translations.get("websitesStreamHelper",
                                      fallback: "Separate multiple ports with commas."))
            }
            Section(translations.get("websitesStreamServersLabel",
                                     fallback: "Upstream servers")) {
                if servers.isEmpty {
                    Text(translations.get("websitesStreamServersEmpty",
                                          fallback: "No upstream servers; configure load balance first."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(servers.enumerated()), id: \.offset) { _, server in
                        Text(serverSummary(server))
                            .font(.subheadline)
                    }
                    if !algorithm.isEmpty {
                        Text("\(translations.get("websitesStreamAlgorithmLabel", fallback: "Algorithm")): \(algorithm)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section {
                saveButton
            }
            if let statusMessage {
                Section {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(translations.get("websitesStreamTitle", fallback: "TCP/UDP Forwarding"))
        .navigationBarTitleDisplayMode(.inline)
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

    private var saveButton: some View {
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

    private func serverSummary(_ server: [String: Any]) -> String {
        var parts: [String] = [server["server"] as? String ?? ""]
        if let weight = server["weight"] as? Int, weight > 0 {
            parts.append("weight \(weight)")
        }
        if let flag = server["flag"] as? String, !flag.isEmpty {
            parts.append(flag)
        }
        return parts.joined(separator: " · ")
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getWebsiteStream",
                arguments: ["id": websiteId]
            )
            let dict = raw as? [String: Any] ?? [:]
            streamPorts = dict["streamPorts"] as? String ?? ""
            udp = dict["udp"] as? Bool ?? false
            name = dict["name"] as? String ?? ""
            algorithm = dict["algorithm"] as? String ?? ""
            servers = dict["servers"] as? [[String: Any]] ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        let ports = streamPorts.trimmingCharacters(in: .whitespaces)
        guard !ports.isEmpty else {
            errorMessage = translations.get("websitesStreamPortsRequired",
                                            fallback: "Enter at least one forwarding port.")
            return
        }
        isSaving = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "updateWebsiteStream",
                arguments: [
                    "websiteID": websiteId,
                    "streamPorts": ports,
                    "udp": udp,
                    "name": name,
                    "algorithm": algorithm,
                    "servers": servers,
                ]
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true {
                statusMessage = translations.get("commonOperationSuccess",
                                                 fallback: "Operation succeeded")
            } else {
                errorMessage = payload["error"] as? String
                    ?? translations.get("commonOperationFailed", fallback: "Operation failed")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}