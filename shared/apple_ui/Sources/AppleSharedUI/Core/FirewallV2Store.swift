import Combine
import Foundation

/// 防火墙 V2 分区的共享状态对象。
///
/// iOS 与 macOS 共用加载、写操作与错误映射；平台层只注入各自的 `DataChannel`。
@MainActor
open class FirewallV2Store: ObservableObject {
    private let channel: any DataChannel

    @Published public private(set) var forwardInfo: [FirewallInfoRow] = []
    @Published public private(set) var forwardRules: [FirewallForwardRule] = []
    @Published public private(set) var dockerInfo: [FirewallInfoRow] = []
    @Published public private(set) var dockerPolicies: [FirewallDockerPolicy] = []
    @Published public private(set) var publishedPorts: [FirewallPublishedPort] = []
    @Published public private(set) var settingsInfo: [FirewallInfoRow] = []
    @Published public private(set) var whitelist: [FirewallWhitelistRule] = []
    @Published public private(set) var backendGroups: [FirewallBackendGroup] = []
    @Published public private(set) var ipv6Enabled = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var loadError: String?

    public init(channel: any DataChannel) {
        self.channel = channel
    }

    public func loadForward() async {
        isLoading = true
        do {
            let raw = try await channel.invoke("getFirewallV2Forward", arguments: nil)
            let payload = raw as? [String: Any] ?? [:]
            forwardInfo = Self.infoRows(
                from: payload,
                excluding: ["rules", "total"]
            )
            forwardRules = (payload["rules"] as? [[String: Any]] ?? [])
                .compactMap(FirewallForwardRule.init(payload:))
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    public func loadDocker() async {
        isLoading = true
        do {
            let raw = try await channel.invoke("getFirewallV2Docker", arguments: nil)
            let payload = raw as? [String: Any] ?? [:]
            dockerInfo = Self.infoRows(
                from: payload,
                excluding: ["policies", "publishedPorts"]
            )
            dockerPolicies = (payload["policies"] as? [[String: Any]] ?? [])
                .compactMap(FirewallDockerPolicy.init(payload:))
            publishedPorts = (payload["publishedPorts"] as? [[String: Any]] ?? [])
                .compactMap(FirewallPublishedPort.init(payload:))
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    public func loadSettings() async {
        isLoading = true
        do {
            let raw = try await channel.invoke("getFirewallV2Settings", arguments: nil)
            let payload = raw as? [String: Any] ?? [:]
            settingsInfo = Self.infoRows(
                from: payload,
                excluding: ["whitelist", "backends"]
            )
            ipv6Enabled = payload["ipv6Enabled"] as? Bool ?? false
            whitelist = (payload["whitelist"] as? [[String: Any]] ?? [])
                .compactMap(FirewallWhitelistRule.init(payload:))
            backendGroups = (payload["backends"] as? [[String: Any]] ?? [])
                .compactMap(FirewallBackendGroup.init(payload:))
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    public func addForwardRule(
        port: String,
        protocolName: String,
        targetIP: String,
        targetPort: String,
        interfaceName: String
    ) async throws {
        var rule: [String: Any] = [
            "operation": "add",
            "port": port,
            "protocol": protocolName,
            "targetPort": targetPort,
        ]
        if !targetIP.isEmpty { rule["targetIP"] = targetIP }
        if !interfaceName.isEmpty { rule["interface"] = interfaceName }
        try await perform(
            "operateFirewallForwardRules",
            arguments: ["rules": [rule]]
        )
        await loadForward()
    }

    public func removeForwardRule(_ rule: FirewallForwardRule) async throws {
        var payload: [String: Any] = [
            "operation": "remove",
            "port": rule.port,
            "protocol": rule.protocolName,
            "targetPort": rule.targetPort,
        ]
        if !rule.targetIP.isEmpty { payload["targetIP"] = rule.targetIP }
        if !rule.interfaceName.isEmpty { payload["interface"] = rule.interfaceName }
        if !rule.family.isEmpty { payload["family"] = rule.family }
        if !rule.num.isEmpty { payload["num"] = rule.num }
        try await perform(
            "operateFirewallForwardRules",
            arguments: ["rules": [payload]]
        )
        await loadForward()
    }

    public func updateForwardRule(
        _ rule: FirewallForwardRule,
        port: String,
        protocolName: String,
        targetIP: String,
        targetPort: String,
        interfaceName: String
    ) async throws {
        var remove: [String: Any] = [
            "operation": "remove",
            "port": rule.port,
            "protocol": rule.protocolName,
            "targetPort": rule.targetPort,
        ]
        if !rule.targetIP.isEmpty { remove["targetIP"] = rule.targetIP }
        if !rule.interfaceName.isEmpty { remove["interface"] = rule.interfaceName }
        if !rule.family.isEmpty { remove["family"] = rule.family }
        if !rule.num.isEmpty { remove["num"] = rule.num }
        var add: [String: Any] = [
            "operation": "add",
            "port": port,
            "protocol": protocolName,
            "targetPort": targetPort,
        ]
        if !targetIP.isEmpty { add["targetIP"] = targetIP }
        if !interfaceName.isEmpty { add["interface"] = interfaceName }
        if !rule.family.isEmpty { add["family"] = rule.family }
        try await perform(
            "operateFirewallForwardRules",
            arguments: ["rules": [remove, add]]
        )
        await loadForward()
    }

    public func addDockerPolicy(
        family: String,
        hostIP: String,
        hostPort: Int,
        mode: String,
        protocolName: String,
        sources: [String]
    ) async throws {
        let policy: [String: Any] = [
            "family": family,
            "hostIP": hostIP,
            "hostPort": hostPort,
            "mode": mode,
            "protocol": protocolName,
            "sources": sources,
        ]
        try await perform(
            "upsertFirewallDockerPolicies",
            arguments: ["policies": [policy]]
        )
        await loadDocker()
    }

    public func updateDockerPolicy(
        _ policy: FirewallDockerPolicy,
        mode: String,
        sources: [String]
    ) async throws {
        var payload = dockerPolicyPayload(policy)
        payload["mode"] = mode
        payload["sources"] = sources
        try await perform(
            "upsertFirewallDockerPolicies",
            arguments: ["policies": [payload]]
        )
        await loadDocker()
    }

    public func updateDockerPolicies(
        _ policies: [FirewallDockerPolicy],
        mode: String,
        sources: [String]
    ) async throws {
        guard !policies.isEmpty else {
            throw FirewallV2ActionError.failed("policies are required")
        }
        let payloads = policies.map { policy -> [String: Any] in
            var payload = dockerPolicyPayload(policy)
            payload["mode"] = mode
            payload["sources"] = sources
            return payload
        }
        try await perform(
            "upsertFirewallDockerPolicies",
            arguments: ["policies": payloads]
        )
        await loadDocker()
    }

    public func importDockerPolicies(_ policies: [[String: Any]]) async throws {
        guard !policies.isEmpty else {
            throw FirewallV2ActionError.failed("policies are required")
        }
        try await perform(
            "upsertFirewallDockerPolicies",
            arguments: ["import": true, "policies": policies]
        )
        await loadDocker()
    }

    public func deleteDockerPolicy(_ policy: FirewallDockerPolicy) async throws {
        try await perform(
            "deleteFirewallDockerPolicies",
            arguments: ["uuids": [policy.id]]
        )
        await loadDocker()
    }

    public func createWhitelist(
        port: String,
        protocolName: String,
        type: String,
        sources: [String]
    ) async throws {
        try await perform(
            "createFirewallWhitelist",
            arguments: ["rule": whitelistPayload(
                port: port,
                protocolName: protocolName,
                type: type,
                sources: sources
            )]
        )
        await loadSettings()
    }

    public func updateWhitelist(
        old: FirewallWhitelistRule,
        port: String,
        protocolName: String,
        type: String,
        sources: [String]
    ) async throws {
        try await perform(
            "updateFirewallWhitelist",
            arguments: [
                "oldRule": whitelistPayload(
                    port: old.port,
                    protocolName: old.protocolName,
                    type: old.type,
                    sources: old.sources
                ),
                "rule": whitelistPayload(
                    port: port,
                    protocolName: protocolName,
                    type: type,
                    sources: sources
                ),
            ]
        )
        await loadSettings()
    }

    public func deleteWhitelist(_ rule: FirewallWhitelistRule) async throws {
        try await perform(
            "deleteFirewallWhitelist",
            arguments: ["rule": whitelistPayload(
                port: rule.port,
                protocolName: rule.protocolName,
                type: rule.type,
                sources: rule.sources
            )]
        )
        await loadSettings()
    }

    public func selectBackend(subsystem: String, backend: String) async throws {
        try await operateBackend(
            subsystem: subsystem,
            backend: backend,
            operation: "select"
        )
    }

    public func operateBackend(
        subsystem: String,
        backend: String,
        operation: String
    ) async throws {
        guard ["select", "initialize", "cleanup"].contains(operation) else {
            throw FirewallV2ActionError.failed("Unsupported operation: \(operation)")
        }
        try await perform(
            "operateFirewallBackend",
            arguments: [
                "subsystem": subsystem,
                "backend": backend,
                "operation": operation,
            ]
        )
        await loadSettings()
    }

    private func dockerPolicyPayload(_ policy: FirewallDockerPolicy) -> [String: Any] {
        var payload: [String: Any] = [
            "family": policy.family,
            "hostIP": policy.hostIP,
            "hostPort": Int(policy.hostPort) ?? 0,
            "protocol": policy.protocolName,
            "mode": policy.mode,
            "sources": policy.sources,
        ]
        if payload["family"] as? String == "" { payload["family"] = "ipv4" }
        if payload["protocol"] as? String == "" { payload["protocol"] = "tcp" }
        return payload
    }

    private func whitelistPayload(
        port: String,
        protocolName: String,
        type: String,
        sources: [String]
    ) -> [String: Any] {
        var rule: [String: Any] = ["port": port, "protocol": protocolName]
        if !type.isEmpty { rule["type"] = type }
        if !sources.isEmpty { rule["sources"] = sources }
        return rule
    }

    private func perform(
        _ method: String,
        arguments: [String: Any]?
    ) async throws {
        let raw = try await channel.invoke(method, arguments: arguments)
        let payload = raw as? [String: Any] ?? [:]
        guard payload["success"] as? Bool == true else {
            throw FirewallV2ActionError.failed(payload["error"] as? String)
        }
    }

    private static func infoRows(
        from payload: [String: Any],
        excluding keys: Set<String>
    ) -> [FirewallInfoRow] {
        payload
            .filter { key, value in
                guard !keys.contains(key) else { return false }
                let text = firewallText(value)
                return !text.isEmpty
            }
            .map { FirewallInfoRow(label: $0.key, value: firewallText($0.value)) }
            .sorted { $0.label < $1.label }
    }
}