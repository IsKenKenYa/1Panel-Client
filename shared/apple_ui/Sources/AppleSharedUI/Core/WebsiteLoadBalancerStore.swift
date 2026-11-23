import Combine
import Foundation

public struct WebsiteLoadBalancerError: LocalizedError {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    public var errorDescription: String? { message }
}

/// 网站负载均衡列表与写入，iOS 与 macOS 共用，平台层注入 `DataChannel`。
@MainActor
public final class WebsiteLoadBalancerStore: ObservableObject {
    private let channel: any DataChannel
    private let websiteID: Int

    @Published public private(set) var items: [WebsiteLoadBalancer] = []
    @Published public private(set) var isLoading = false
    @Published public private(set) var loadError: String?

    public init(channel: any DataChannel, websiteID: Int) {
        self.channel = channel
        self.websiteID = websiteID
    }

    public func load() async {
        isLoading = true
        do {
            let raw = try await channel.invoke(
                "getWebsiteLoadBalancers",
                arguments: ["id": websiteID]
            )
            items = (raw as? [[String: Any]] ?? [])
                .compactMap(WebsiteLoadBalancer.init(payload:))
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
        isLoading = false
    }

    public func create(_ balancer: WebsiteLoadBalancer) async throws {
        try await submit("createWebsiteLoadBalancer", balancer: balancer)
        await load()
    }

    public func update(_ balancer: WebsiteLoadBalancer) async throws {
        try await submit("updateWebsiteLoadBalancer", balancer: balancer)
        await load()
    }

    public func delete(name: String) async throws {
        let raw = try await channel.invoke(
            "deleteWebsiteLoadBalancer",
            arguments: ["websiteID": websiteID, "name": name]
        )
        try Self.throwIfFailure(raw)
        await load()
    }

    private func submit(
        _ method: String,
        balancer: WebsiteLoadBalancer
    ) async throws {
        var arguments = balancer.payload
        arguments["websiteID"] = websiteID
        let raw = try await channel.invoke(method, arguments: arguments)
        try Self.throwIfFailure(raw)
    }

    private static func throwIfFailure(_ raw: Any?) throws {
        let payload = raw as? [String: Any] ?? [:]
        if payload["success"] as? Bool == true { return }
        throw WebsiteLoadBalancerError(
            payload["error"] as? String ?? "Operation failed"
        )
    }
}