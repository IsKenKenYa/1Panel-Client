import Foundation

/// 负载均衡算法，对应上游 nginx upstream 负载策略。
public enum WebsiteLoadBalancerAlgorithm: String, CaseIterable, Identifiable {
    case standard = "default"
    case ipHash = "ip_hash"
    case leastConn = "least_conn"

    public var id: String { rawValue }
}

/// 上游服务器状态策略。
public enum WebsiteLoadBalancerFlag: String, CaseIterable, Identifiable {
    case none = ""
    case down = "down"
    case backup = "backup"

    public var id: String { rawValue }
}

/// 负载均衡中的单个上游服务器与权重参数。
public struct WebsiteLoadBalancerServer: Identifiable, Equatable {
    public let id: UUID
    public var server: String
    public var weight: Int?
    public var flag: String
    public var maxFails: Int?
    public var maxConns: Int?
    public var failTimeout: Int?
    public var failTimeoutUnit: String

    public init(
        server: String,
        weight: Int? = nil,
        flag: String = "",
        maxFails: Int? = nil,
        maxConns: Int? = nil,
        failTimeout: Int? = nil,
        failTimeoutUnit: String = "s"
    ) {
        self.id = UUID()
        self.server = server
        self.weight = weight
        self.flag = flag
        self.maxFails = maxFails
        self.maxConns = maxConns
        self.failTimeout = failTimeout
        self.failTimeoutUnit = failTimeoutUnit
    }

    /// 保留标识的初始化，供表单就地修改字段使用。
    public init(
        id: UUID,
        server: String,
        weight: Int?,
        flag: String,
        maxFails: Int?,
        maxConns: Int?,
        failTimeout: Int?,
        failTimeoutUnit: String
    ) {
        self.id = id
        self.server = server
        self.weight = weight
        self.flag = flag
        self.maxFails = maxFails
        self.maxConns = maxConns
        self.failTimeout = failTimeout
        self.failTimeoutUnit = failTimeoutUnit
    }

    public init?(payload: [String: Any]) {
        let server = (payload["server"] as? String ?? "")
            .trimmingCharacters(in: .whitespaces)
        guard !server.isEmpty else { return nil }
        self.id = UUID()
        self.server = server
        self.weight = Self.nonZero(payload["weight"])
        self.flag = payload["flag"] as? String ?? ""
        self.maxFails = Self.nonZero(payload["maxFails"])
        self.maxConns = Self.nonZero(payload["maxConns"])
        self.failTimeout = Self.nonZero(payload["failTimeout"])
        self.failTimeoutUnit = payload["failTimeoutUnit"] as? String ?? "s"
    }

    public var payload: [String: Any] {
        [
            "server": server,
            "weight": weight ?? 0,
            "flag": flag,
            "maxFails": maxFails ?? 0,
            "maxConns": maxConns ?? 0,
            "failTimeout": failTimeout ?? 0,
            "failTimeoutUnit": failTimeoutUnit,
        ]
    }

    public var summary: String {
        var parts = [server]
        if let weight, weight > 0 { parts.append("weight \(weight)") }
        if !flag.isEmpty { parts.append(flag) }
        if let maxFails { parts.append("max_fails \(maxFails)") }
        if let maxConns { parts.append("max_conns \(maxConns)") }
        if let failTimeout { parts.append("fail_timeout \(failTimeout)\(failTimeoutUnit)") }
        return parts.joined(separator: " · ")
    }

    public static func == (
        lhs: WebsiteLoadBalancerServer,
        rhs: WebsiteLoadBalancerServer
    ) -> Bool {
        lhs.server == rhs.server && lhs.weight == rhs.weight &&
            lhs.flag == rhs.flag && lhs.maxFails == rhs.maxFails &&
            lhs.maxConns == rhs.maxConns && lhs.failTimeout == rhs.failTimeout &&
            lhs.failTimeoutUnit == rhs.failTimeoutUnit
    }

    private static func nonZero(_ value: Any?) -> Int? {
        let parsed = Int("\(value ?? "")") ?? 0
        return parsed == 0 ? nil : parsed
    }
}

/// 一个命名的负载均衡上游。
public struct WebsiteLoadBalancer: Identifiable, Equatable {
    public var name: String
    public var algorithm: String
    public var servers: [WebsiteLoadBalancerServer]
    public var content: String

    public var id: String { name }

    public init(
        name: String,
        algorithm: String,
        servers: [WebsiteLoadBalancerServer],
        content: String = ""
    ) {
        self.name = name
        self.algorithm = algorithm
        self.servers = servers
        self.content = content
    }

    public init?(payload: [String: Any]) {
        let name = (payload["name"] as? String ?? "")
            .trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        self.name = name
        self.algorithm = payload["algorithm"] as? String ?? "default"
        self.servers = (payload["servers"] as? [[String: Any]] ?? [])
            .compactMap(WebsiteLoadBalancerServer.init(payload:))
        self.content = payload["content"] as? String ?? ""
    }

    public var payload: [String: Any] {
        [
            "name": name,
            "algorithm": algorithm,
            "servers": servers.map(\.payload),
        ]
    }
}

public enum WebsiteLoadBalancerValidationIssue: Equatable {
    case nameRequired
    case algorithmRequired
    case serversRequired
    case serverRequired
    case duplicateServer
    case invalidWeight
    case invalidMaxFails
    case invalidMaxConns
    case invalidFailTimeout
    case ipHashBackup
}

public enum WebsiteLoadBalancerValidator {
    public static let weightRange = 0...100
    public static let maxFailsRange = 0...1000
    public static let maxConnsRange = 0...10_000
    public static let failTimeoutRange = 0...300

    public static func validate(
        name: String,
        algorithm: String,
        servers: [WebsiteLoadBalancerServer]
    ) -> WebsiteLoadBalancerValidationIssue? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return .nameRequired
        }
        if !WebsiteLoadBalancerAlgorithm.allCases
            .map(\.rawValue)
            .contains(algorithm) {
            return .algorithmRequired
        }
        if servers.isEmpty {
            return .serversRequired
        }
        var seen = Set<String>()
        for server in servers {
            if server.server.trimmingCharacters(in: .whitespaces).isEmpty {
                return .serverRequired
            }
            if !seen.insert(server.server).inserted {
                return .duplicateServer
            }
            if let weight = server.weight, !weightRange.contains(weight) {
                return .invalidWeight
            }
            if let maxFails = server.maxFails,
               !maxFailsRange.contains(maxFails) {
                return .invalidMaxFails
            }
            if let maxConns = server.maxConns,
               !maxConnsRange.contains(maxConns) {
                return .invalidMaxConns
            }
            if let failTimeout = server.failTimeout,
               !failTimeoutRange.contains(failTimeout) {
                return .invalidFailTimeout
            }
            if algorithm == "ip_hash" && server.flag == "backup" {
                return .ipHashBackup
            }
        }
        return nil
    }
}