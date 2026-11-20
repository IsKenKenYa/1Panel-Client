import SwiftUI
import AppleSharedUI

/// AI 模块：本地模型 / 账号 / MCP / 智能体 / GPU 五个页签。
struct AIModuleView: View {
    @EnvironmentObject var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_AI_TAB=accounts|mcp|agents|gpu` 直接进入子页签。
    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_AI_TAB"] ?? "models"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text(translations.get("hostAiTabModels", fallback: "Local Models")).tag("models")
                Text(translations.get("hostAiTabAccounts", fallback: "Accounts")).tag("accounts")
                Text(translations.get("hostAiTabMcp", fallback: "MCP")).tag("mcp")
                Text(translations.get("hostAiTabAgents", fallback: "Agents")).tag("agents")
                Text(translations.get("hostAiTabGpu", fallback: "GPU")).tag("gpu")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "accounts":
                AIAccountsView()
            case "mcp":
                AIMcpServersView()
            case "agents":
                AIAgentsView()
            case "gpu":
                AIGpuView()
            default:
                AIModelsView()
            }
        }
        .navigationTitle(translations.get("serverModuleAi", fallback: "AI"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .ai)
            }
        }
    }
}

// MARK: - 渠道账号

struct AIAccountRow: Identifiable {
    let id: Int
    let name: String
    let providerName: String
    let apiType: String
    let baseUrl: String
    let verified: Bool
}

struct AIAccountsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var accounts: [AIAccountRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: AIAccountRow?
    @State private var showCreateSheet = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && accounts.isEmpty {
                LoadingView()
            } else if accounts.isEmpty {
                EmptyStateView(
                    icon: "person.badge.key",
                    message: translations.get("hostAiAccountsEmpty", fallback: "No accounts")
                )
            } else {
                List {
                    ForEach(accounts) { account in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(account.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                StatusBadge(
                                    text: account.verified
                                        ? translations.get("systemSettingsEnabled", fallback: "Enabled")
                                        : translations.get("systemSettingsDisabled", fallback: "Disabled"),
                                    color: account.verified ? .green : .gray
                                )
                            }
                            HStack(spacing: 12) {
                                if !account.providerName.isEmpty {
                                    Label(account.providerName, systemImage: "building.2")
                                }
                                if !account.apiType.isEmpty {
                                    Label(account.apiType, systemImage: "chevron.left.forwardslash.chevron.right")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            if !account.baseUrl.isEmpty {
                                Text(account.baseUrl)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = account
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("aiAgentsCreate", fallback: "Create"),
                          systemImage: "plus")
                }
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            AIAccountCreateSheet(onCreated: { fetch() })
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteAccount()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if accounts.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getAgentAccounts",
            arguments: ["page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      let items = dict["items"] as? [[String: Any]] else { return }
                accounts = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return AIAccountRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        providerName: item["providerName"] as? String ?? "",
                        apiType: item["apiType"] as? String ?? "",
                        baseUrl: item["baseUrl"] as? String ?? "",
                        verified: item["verified"] as? Bool ?? false
                    )
                }
            }
        }
    }

    private func deleteAccount() {
        guard let account = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteAgentAccountNative",
            arguments: ["id": account.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}

// MARK: - MCP 服务器

struct AIMcpRow: Identifiable {
    let id: Int
    let name: String
    let type: String
    let status: String
    let port: Int
    let baseUrl: String
}

struct AIMcpServersView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var servers: [AIMcpRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: AIMcpRow?
    @State private var pendingOperate: (row: AIMcpRow, operate: String)?
    @State private var showCreateSheet = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && servers.isEmpty {
                LoadingView()
            } else if servers.isEmpty {
                EmptyStateView(
                    icon: "server.rack",
                    message: translations.get("hostAiMcpLoadFailed", fallback: "No MCP servers")
                )
            } else {
                List {
                    ForEach(servers) { server in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(server.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if !server.status.isEmpty {
                                    StatusBadge(
                                        text: server.status,
                                        color: StatusPalette.appStatus(server.status)
                                    )
                                }
                            }
                            HStack(spacing: 12) {
                                if !server.type.isEmpty {
                                    Label(server.type, systemImage: "shippingbox")
                                }
                                if server.port > 0 {
                                    Label(String(server.port), systemImage: "network")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            if !server.baseUrl.isEmpty {
                                Text(server.baseUrl)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                        .padding(.vertical, 2)
                        .contextMenu {
                            Button {
                                pendingOperate = (server, "start")
                            } label: {
                                Label(translations.get("commonStart", fallback: "Start"),
                                      systemImage: "play.fill")
                            }
                            Button {
                                pendingOperate = (server, "stop")
                            } label: {
                                Label(translations.get("commonStop", fallback: "Stop"),
                                      systemImage: "stop.fill")
                            }
                            Button {
                                pendingOperate = (server, "restart")
                            } label: {
                                Label(translations.get("commonRestart", fallback: "Restart"),
                                      systemImage: "arrow.clockwise")
                            }
                            Button {
                                testConnection(server)
                            } label: {
                                Label(translations.get("hostAiMcpTestConnection", fallback: "Test connection"),
                                      systemImage: "antenna.radiowaves.left.and.right")
                            }
                            Button(role: .destructive) {
                                pendingDelete = server
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = server
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("aiMcpDialogCreateTitle", fallback: "Create"),
                          systemImage: "plus")
                }
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            AIMcpCreateSheet(onCreated: { fetch() })
        }
        .confirmationDialog(
            operateConfirmTitle,
            isPresented: Binding(
                get: { pendingOperate != nil },
                set: { if !$0 { pendingOperate = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(operateLabel(pendingOperate?.operate) ?? "") {
                performOperate()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingOperate = nil
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteServer()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if servers.isEmpty {
                fetch()
            }
        }
    }

    private var operateConfirmTitle: String {
        let label = operateLabel(pendingOperate?.operate) ?? ""
        let name = pendingOperate?.row.name ?? ""
        // 上游文案使用 {0}/{1} 位置占位符（{0}=操作、{1}=名称）。
        let template = translations.get("hostAiMcpOperateConfirm",
                                        fallback: "Perform {0} on MCP server '{1}'?")
        return template
            .replacingOccurrences(of: "{0}", with: label)
            .replacingOccurrences(of: "{1}", with: name)
            .replacingOccurrences(of: "{operation}", with: label)
            .replacingOccurrences(of: "{name}", with: name)
    }

    private func operateLabel(_ operate: String?) -> String? {
        switch operate {
        case "start":
            return translations.get("commonStart", fallback: "Start")
        case "stop":
            return translations.get("commonStop", fallback: "Stop")
        case "restart":
            return translations.get("commonRestart", fallback: "Restart")
        default:
            return nil
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getMcpServers",
            arguments: ["page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      let items = dict["items"] as? [[String: Any]] else { return }
                servers = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return AIMcpRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        type: item["type"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        port: item["port"] as? Int ?? 0,
                        baseUrl: item["baseUrl"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func performOperate() {
        guard let pending = pendingOperate else { return }
        pendingOperate = nil
        ChannelManager.shared.invokeDataMethod(
            "operateMcpServerNative",
            arguments: ["id": pending.row.id, "operate": pending.operate]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("hostAiMcpOperationSuccess", fallback: "Operation succeeded")
                    : (dict?["error"] as? String
                        ?? translations.get("hostAiMcpOperationFailed", fallback: "Operation failed")))
                fetch()
            }
        }
    }

    private func testConnection(_ server: AIMcpRow) {
        ChannelManager.shared.invokeDataMethod(
            "testMcpConnection",
            arguments: ["id": server.id]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                let success = dict?["success"] as? Bool ?? false
                if success {
                    showToast(translations.get("hostAiMcpTestSuccess", fallback: "Connection test succeeded"))
                } else {
                    let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                    showToast(template.replacingOccurrences(
                        of: "{error}",
                        with: dict?["error"] as? String
                            ?? translations.get("hostAiMcpTestFailed", fallback: "Connection test failed")
                    ))
                }
            }
        }
    }

    private func deleteServer() {
        guard let server = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteMcpServerNative",
            arguments: ["id": server.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("hostAiMcpDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}

// MARK: - 智能体

struct AIAgentRow: Identifiable {
    let id: Int
    let name: String
    let agentType: String
    let providerName: String
    let model: String
    let status: String
}

struct AIAgentsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var agents: [AIAgentRow] = []
    @State private var isLoading = false
    @State private var pendingDelete: AIAgentRow?
    @State private var showCreateSheet = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && agents.isEmpty {
                LoadingView()
            } else if agents.isEmpty {
                EmptyStateView(
                    icon: "person.crop.circle.badge.questionmark",
                    message: translations.get("hostAiAgentLoadFailed", fallback: "No agents")
                )
            } else {
                List {
                    ForEach(agents) { agent in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(agent.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if !agent.status.isEmpty {
                                    StatusBadge(
                                        text: agent.status,
                                        color: StatusPalette.appStatus(agent.status)
                                    )
                                }
                            }
                            HStack(spacing: 12) {
                                if !agent.agentType.isEmpty {
                                    Label(agent.agentType, systemImage: "cpu")
                                }
                                if !agent.providerName.isEmpty {
                                    Label(agent.providerName, systemImage: "building.2")
                                }
                                if !agent.model.isEmpty {
                                    Label(agent.model, systemImage: "brain")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = agent
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("aiAgentsCreate", fallback: "Create"),
                          systemImage: "plus")
                }
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            AIAgentCreateSheet(onCreated: { fetch() })
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                deleteAgent()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            if agents.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "pageAgentsNative",
            arguments: ["page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      let items = dict["items"] as? [[String: Any]] else { return }
                agents = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return AIAgentRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        agentType: item["agentType"] as? String ?? "",
                        providerName: item["providerName"] as? String ?? "",
                        model: item["model"] as? String ?? "",
                        status: item["status"] as? String ?? ""
                    )
                }
            }
        }
    }

    private func deleteAgent() {
        guard let agent = pendingDelete else { return }
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "deleteAgentNative",
            arguments: ["id": agent.id]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("hostAiAgentDeleteFailed", fallback: "Delete failed"))
                fetch()
            }
        }
    }

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}

// MARK: - GPU

struct AIGpuRow: Identifiable {
    let index: Int
    let productName: String
    let gpuUtil: String
    let memoryUsage: String
    let temperature: String
    let fanSpeed: String

    var id: Int { index }
}

struct AIGpuView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var gpus: [AIGpuRow] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading && gpus.isEmpty {
                LoadingView()
            } else if gpus.isEmpty {
                EmptyStateView(
                    icon: "cpu",
                    message: translations.get("hostAiGpuEmpty", fallback: "No GPU detected")
                )
            } else {
                List {
                    ForEach(gpus) { gpu in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(gpu.productName.isEmpty
                                ? translations.get("hostAiGpuUnknownDevice", fallback: "Unknown device")
                                : gpu.productName)
                                .font(.subheadline.weight(.medium))
                            VStack(spacing: 4) {
                                if !gpu.gpuUtil.isEmpty {
                                    InfoLine(label: translations.get("hostAiGpuUtilization", fallback: "GPU utilization"),
                                             value: gpu.gpuUtil)
                                }
                                if !gpu.memoryUsage.isEmpty {
                                    InfoLine(label: translations.get("hostAiGpuMemoryUsage", fallback: "Memory"),
                                             value: gpu.memoryUsage)
                                }
                                if !gpu.temperature.isEmpty {
                                    InfoLine(label: translations.get("hostAiGpuTemperature", fallback: "Temperature"),
                                             value: gpu.temperature)
                                }
                                if !gpu.fanSpeed.isEmpty {
                                    InfoLine(label: translations.get("hostAiGpuFanSpeed", fallback: "Fan speed"),
                                             value: gpu.fanSpeed)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    fetch()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .onAppear {
            if gpus.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getGpuLoad") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                gpus = items.enumerated().compactMap { offset, item in
                    AIGpuRow(
                        index: item["index"] as? Int ?? offset,
                        productName: item["productName"] as? String ?? "",
                        gpuUtil: item["gpuUtil"] as? String ?? "",
                        memoryUsage: item["memoryUsage"] as? String ?? "",
                        temperature: item["temperature"] as? String ?? "",
                        fanSpeed: item["fanSpeed"] as? String ?? ""
                    )
                }
            }
        }
    }
}
