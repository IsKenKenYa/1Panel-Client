import AppleSharedUI
import SwiftUI

/// macOS 网站代理缓存分区：开关、容量、共享容量与过期时间。
struct WebsiteProxyCacheSection: View {
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
                        Picker("", selection: $cacheLimitUnit) {
                            ForEach(Self.sizeUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                    HStack {
                        TextField(translations.get("websitesCacheShareLabel",
                                                   fallback: "Shared cache"),
                                  text: $shareCache)
                        Picker("", selection: $shareCacheUnit) {
                            ForEach(Self.sizeUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                    HStack {
                        TextField(translations.get("websitesCacheExpireLabel",
                                                   fallback: "Cache expiry"),
                                  text: $cacheExpire)
                        Picker("", selection: $cacheExpireUnit) {
                            ForEach(Self.timeUnits, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 90)
                    }
                } footer: {
                    Text(translations.get("websitesCacheLimitHint",
                                          fallback: "Limits apply to the proxy cache on the panel server."))
                        .font(.footnote)
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
        }
        .formStyle(.grouped)
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
        .overlay(alignment: .bottom) {
            statusNotice
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

    @ViewBuilder
    private var statusNotice: some View {
        if let statusMessage {
            Text(statusMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding(20)
        }
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
        guard let limit = Int(cacheLimit.trimmingCharacters(in: .whitespaces)),
              let share = Int(shareCache.trimmingCharacters(in: .whitespaces)),
              let expire = Int(cacheExpire.trimmingCharacters(in: .whitespaces)),
              (0...9999).contains(limit),
              (0...9999).contains(share),
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

/// macOS 网站真实 IP 分区：来源网段、请求头与自定义头名称。
struct WebsiteRealIPSection: View {
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
                        ForEach(Self.headers, id: \.self) { header in
                            Text(header).tag(header)
                        }
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
                        .font(.footnote)
                }
            }
            Section {
                saveButton
            }
        }
        .formStyle(.grouped)
        .overlay(alignment: .bottom) {
            statusNotice
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

    @ViewBuilder
    private var statusNotice: some View {
        if let statusMessage {
            Text(statusMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding(20)
        }
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
        guard !open || ipHeader != "other" || !ipOther.trimmingCharacters(in: .whitespaces).isEmpty else {
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

struct WebsiteStreamServer: Identifiable, Equatable {
    let server: String
    let weight: Int?
    let flag: String?

    var id: String { "\(server)-\(weight ?? 0)-\(flag ?? "")" }

    var summary: String {
        var parts = [server]
        if let weight, weight > 0 { parts.append("weight \(weight)") }
        if let flag, !flag.isEmpty { parts.append(flag) }
        return parts.joined(separator: " · ")
    }
}

/// macOS 网站 TCP/UDP 转发分区：端口、UDP 标记与上游服务器。
struct WebsiteStreamSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    let websiteId: Int

    @State private var streamPorts = ""
    @State private var udp = false
    @State private var name = ""
    @State private var algorithm = ""
    @State private var servers: [WebsiteStreamServer] = []
    @State private var rawServers: [[String: Any]] = []
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
                Toggle(translations.get("websitesStreamUdpLabel", fallback: "UDP"),
                       isOn: $udp)
            } footer: {
                Text(translations.get("websitesStreamHelper",
                                      fallback: "Separate multiple ports with commas."))
                    .font(.footnote)
            }
            Section(translations.get("websitesStreamServersLabel",
                                     fallback: "Upstream servers")) {
                if servers.isEmpty {
                    Text(translations.get("websitesStreamServersEmpty",
                                          fallback: "No upstream servers; configure load balance first."))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(servers) { server in
                        Text(server.summary)
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
        }
        .formStyle(.grouped)
        .overlay(alignment: .bottom) {
            statusNotice
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

    @ViewBuilder
    private var statusNotice: some View {
        if let statusMessage {
            Text(statusMessage)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
                .padding(20)
        }
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
            rawServers = (dict["servers"] as? [[String: Any]] ?? [])
            servers = rawServers.compactMap { item in
                let server = item["server"] as? String ?? ""
                guard !server.isEmpty else { return nil }
                return WebsiteStreamServer(
                    server: server,
                    weight: item["weight"] as? Int,
                    flag: item["flag"] as? String
                )
            }
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
                    "servers": rawServers,
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