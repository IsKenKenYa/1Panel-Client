import SwiftUI

/// 上游服务器编辑区：端口转发与负载均衡共用同一套服务器参数。
///
/// 绑定集合使用 `ForEach($servers)`，删除时按元素标识匹配，避免索引漂移。
public struct WebsiteUpstreamServersEditor: View {
    @Binding private var servers: [WebsiteLoadBalancerServer]
    private let algorithm: String

    @Environment(\.translationsProvider) private var translations

    private static let timeUnits = ["s", "m", "h", "d", "w", "M", "y"]

    public init(
        servers: Binding<[WebsiteLoadBalancerServer]>,
        algorithm: String
    ) {
        _servers = servers
        self.algorithm = algorithm
    }

    public var body: some View {
        Section {
            if servers.isEmpty {
                Text(t("websitesUpstreamServersEmpty",
                      "No upstream servers."))
                    .foregroundStyle(.secondary)
            }
            ForEach($servers) { $server in
                serverFields($server)
            }
            Button {
                servers.append(WebsiteLoadBalancerServer(server: ""))
            } label: {
                Label(t("websitesLoadBalanceAddServer", "Add server"),
                      systemImage: "plus.circle")
            }
        } header: {
            Text(t("websitesStreamServersLabel", "Upstream servers"))
        } footer: {
            Text(t("websitesUpstreamServersHint",
                   "Addresses use host:port; weight and limits follow nginx upstream rules."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func serverFields(
        _ server: Binding<WebsiteLoadBalancerServer>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(t("websitesLoadBalanceServerLabel", "Server address"),
                          text: addressBinding(server))
                if servers.count > 1 {
                    Button(role: .destructive) {
                        removeServer(server.wrappedValue.id)
                    } label: {
                        Label(t("websitesLoadBalanceRemoveServer", "Remove server"),
                              systemImage: "minus.circle")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                TextField(t("websitesLoadBalanceWeightLabel", "Weight"),
                          text: intBinding(server, \.weight))
                Picker(t("websitesLoadBalanceFlagLabel", "Status strategy"),
                       selection: server.flag) {
                    ForEach(WebsiteLoadBalancerFlag.allCases) { flag in
                        Text(flag.title(translations)).tag(flag.rawValue as String)
                    }
                }
                .labelsHidden()
            }
            HStack {
                TextField(t("websitesLoadBalanceMaxFailsLabel", "Max fails"),
                          text: intBinding(server, \.maxFails))
                TextField(t("websitesLoadBalanceMaxConnsLabel", "Max connections"),
                          text: intBinding(server, \.maxConns))
            }
            HStack {
                TextField(t("websitesLoadBalanceFailTimeoutLabel", "Fail timeout"),
                          text: intBinding(server, \.failTimeout))
                Picker("", selection: server.failTimeoutUnit) {
                    ForEach(Self.timeUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .labelsHidden()
                .frame(width: 70)
            }
        }
    }

    /// 服务器地址直接绑定到模型字段；标识不随地址变化。
    private func addressBinding(
        _ server: Binding<WebsiteLoadBalancerServer>
    ) -> Binding<String> {
        Binding(
            get: { server.wrappedValue.server },
            set: { newValue in
                server.wrappedValue = WebsiteLoadBalancerServer(
                    id: server.wrappedValue.id,
                    server: newValue,
                    weight: server.wrappedValue.weight,
                    flag: server.wrappedValue.flag,
                    maxFails: server.wrappedValue.maxFails,
                    maxConns: server.wrappedValue.maxConns,
                    failTimeout: server.wrappedValue.failTimeout,
                    failTimeoutUnit: server.wrappedValue.failTimeoutUnit
                )
            }
        )
    }

    /// 数字字段空文本写回 nil，非法文本写回 nil 并由提交校验拦截。
    private func intBinding(
        _ server: Binding<WebsiteLoadBalancerServer>,
        _ keyPath: WritableKeyPath<WebsiteLoadBalancerServer, Int?>
    ) -> Binding<String> {
        Binding(
            get: { server.wrappedValue[keyPath: keyPath].map(String.init) ?? "" },
            set: { newValue in
                var value = server.wrappedValue
                value[keyPath: keyPath] = Int(
                    newValue.trimmingCharacters(in: .whitespaces)
                )
                server.wrappedValue = value
            }
        )
    }

    private func removeServer(_ id: UUID) {
        servers.removeAll { $0.id == id }
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations?.get(key, fallback: fallback) ?? fallback
    }
}