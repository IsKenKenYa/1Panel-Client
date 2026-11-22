import Foundation

/// 防火墙 V2 分区的共享数据模型。
///
/// Dart 通道已完成字段整理，原生层只负责展示与表单回填。

func firewallText(_ value: Any?) -> String {
    guard let value, !(value is NSNull) else { return "" }
    if let string = value as? String { return string }
    return "\(value)"
}

public struct FirewallInfoRow: Identifiable, Equatable {
    public let label: String
    public let value: String

    public var id: String { label }

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct FirewallForwardRule: Identifiable, Equatable {
    public let id: String
    public let num: String
    public let family: String
    public let chain: String
    public let protocolName: String
    public let port: String
    public let address: String
    public let targetIP: String
    public let targetPort: String
    public let interfaceName: String
    public let strategy: String
    public let description: String
    public let usedStatus: String
    public let syncStatus: String
    public let isDesired: Bool
    public let isRuntime: Bool

    public init?(payload: [String: Any]) {
        let id = firewallText(payload["id"])
        guard !id.isEmpty else { return nil }
        self.id = id
        num = firewallText(payload["num"])
        family = firewallText(payload["family"])
        chain = firewallText(payload["chain"])
        protocolName = firewallText(payload["protocol"])
        port = firewallText(payload["port"])
        address = firewallText(payload["address"])
        targetIP = firewallText(payload["targetIP"])
        targetPort = firewallText(payload["targetPort"])
        interfaceName = firewallText(payload["interface"])
        strategy = firewallText(payload["strategy"])
        description = firewallText(payload["description"])
        usedStatus = firewallText(payload["usedStatus"])
        syncStatus = firewallText(payload["syncStatus"])
        isDesired = payload["isDesired"] as? Bool ?? false
        isRuntime = payload["isRuntime"] as? Bool ?? false
    }

    public var sourceText: String {
        let endpoint = "\(port)/\(protocolName.isEmpty ? "--" : protocolName)"
        if !interfaceName.isEmpty {
            return "\(interfaceName):\(endpoint)"
        }
        if !address.isEmpty {
            return "\(address) → \(endpoint)"
        }
        return endpoint
    }

    public var targetText: String {
        if targetIP.isEmpty && targetPort.isEmpty { return "--" }
        if targetIP.isEmpty { return targetPort }
        return "\(targetIP):\(targetPort)"
    }
}

public struct FirewallDockerPolicy: Identifiable, Equatable {
    public let id: String
    public let hostIP: String
    public let hostPort: String
    public let family: String
    public let protocolName: String
    public let mode: String
    public let sources: [String]
    public let containerName: String
    public let containerState: String
    public let application: String
    public let compose: String
    public let trafficPath: String
    public let managementTarget: String
    public let effective: Bool

    public init?(payload: [String: Any]) {
        let id = firewallText(payload["id"])
        guard !id.isEmpty else { return nil }
        self.id = id
        hostIP = firewallText(payload["hostIP"])
        hostPort = firewallText(payload["hostPort"])
        family = firewallText(payload["family"])
        protocolName = firewallText(payload["protocol"])
        mode = firewallText(payload["mode"])
        sources = (payload["sources"] as? [Any] ?? []).map { firewallText($0) }
        containerName = firewallText(payload["containerName"])
        containerState = firewallText(payload["containerState"])
        application = firewallText(payload["application"])
        compose = firewallText(payload["compose"])
        trafficPath = firewallText(payload["trafficPath"])
        managementTarget = firewallText(payload["managementTarget"])
        effective = payload["effective"] as? Bool ?? false
    }

    public var hostText: String {
        let host = hostIP.isEmpty ? "*" : hostIP
        return "\(host):\(hostPort)/\(protocolName)"
    }
}

public struct FirewallPublishedPort: Identifiable, Equatable {
    public let id: String
    public let containerName: String
    public let containerState: String
    public let family: String
    public let hostIP: String
    public let hostPort: String
    public let containerPort: String
    public let protocolName: String
    public let mode: String
    public let effective: Bool

    public init?(payload: [String: Any]) {
        let id = firewallText(payload["id"])
        guard !id.isEmpty else { return nil }
        self.id = id
        containerName = firewallText(payload["containerName"])
        containerState = firewallText(payload["containerState"])
        family = firewallText(payload["family"])
        hostIP = firewallText(payload["hostIP"])
        hostPort = firewallText(payload["hostPort"])
        containerPort = firewallText(payload["containerPort"])
        protocolName = firewallText(payload["protocol"])
        mode = firewallText(payload["mode"])
        effective = payload["effective"] as? Bool ?? false
    }

    public var portText: String {
        let host = hostIP.isEmpty ? "*" : hostIP
        return "\(host):\(hostPort) → \(containerPort)/\(protocolName)"
    }
}

public struct FirewallWhitelistRule: Identifiable, Equatable {
    public let id: String
    public let port: String
    public let protocolName: String
    public let type: String
    public let sources: [String]

    public init?(
        id: String,
        port: String,
        protocolName: String,
        type: String,
        sources: [String]
    ) {
        guard !id.isEmpty else { return nil }
        self.id = id
        self.port = port
        self.protocolName = protocolName
        self.type = type
        self.sources = sources
    }

    public init?(payload: [String: Any]) {
        self.init(
            id: firewallText(payload["id"]),
            port: firewallText(payload["port"]),
            protocolName: firewallText(payload["protocol"]),
            type: firewallText(payload["type"]),
            sources: (payload["sources"] as? [Any] ?? []).map { firewallText($0) }
        )
    }

    public var sourcesText: String {
        sources.isEmpty ? "--" : sources.joined(separator: ", ")
    }
}

public struct FirewallBackendOption: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let installed: Bool
    public let active: Bool
    public let initialized: Bool
    public let bound: Bool
    public let supported: Bool
    public let message: String

    public init?(payload: [String: Any]) {
        let name = firewallText(payload["name"])
        guard !name.isEmpty else { return nil }
        id = name
        self.name = name
        installed = payload["installed"] as? Bool ?? false
        active = payload["active"] as? Bool ?? false
        initialized = payload["initialized"] as? Bool ?? false
        bound = payload["bound"] as? Bool ?? false
        supported = payload["supported"] as? Bool ?? false
        message = firewallText(payload["message"])
    }
}

public struct FirewallBackendGroup: Identifiable, Equatable {
    public let id: String
    public let subsystem: String
    public let selected: String
    public let current: String
    public let options: [FirewallBackendOption]

    public init?(payload: [String: Any]) {
        let subsystem = firewallText(payload["subsystem"])
        guard !subsystem.isEmpty else { return nil }
        id = subsystem
        self.subsystem = subsystem
        selected = firewallText(payload["selected"])
        current = firewallText(payload["current"])
        options = (payload["options"] as? [[String: Any]] ?? [])
            .compactMap(FirewallBackendOption.init(payload:))
    }
}

public struct WhitelistRuleEditor: Identifiable {
    public let id = UUID()
    public let rule: FirewallWhitelistRule?

    public init(rule: FirewallWhitelistRule? = nil) {
        self.rule = rule
    }
}

/// 通道写入失败信息，供平台层映射为本地化提示。
public enum FirewallV2ActionError: LocalizedError {
    case failed(String?)

    public var errorDescription: String? {
        switch self {
        case .failed(let message):
            return message
        }
    }
}