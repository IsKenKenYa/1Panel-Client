import AppleSharedUI
import SwiftUI

/// macOS 日志中心：操作、登录、任务与系统四类日志。
struct LogsModuleView: View {
    @EnvironmentObject private var translations: TranslationsManager

    @State private var tab = ProcessInfo.processInfo.environment["ONEPANEL_LOGS_TAB"] ?? "operation"

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $tab) {
                Text(translations.get("logsOperationTabLabel", fallback: "Operation")).tag("operation")
                Text(translations.get("logsLoginTabLabel", fallback: "Login")).tag("login")
                Text(translations.get("logsCenterTabTask", fallback: "Tasks")).tag("task")
                Text(translations.get("logsSystemTabLabel", fallback: "System")).tag("system")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "login":
                LoginLogsSection()
            case "task":
                TaskLogsSection()
            case "system":
                SystemLogsSection()
            default:
                OperationLogsSection()
            }
        }
        .navigationTitle(translations.get("operationsLogsTitle", fallback: "Logs"))
    }
}

struct OperationLogRow: Identifiable {
    let logId: Int
    let source: String
    let ip: String
    let path: String
    let method: String
    let status: String

    var id: Int { logId }

    init?(payload: [String: Any]) {
        guard let id = payload["id"] as? Int else { return nil }
        logId = id
        source = payload["source"] as? String ?? ""
        ip = payload["ip"] as? String ?? ""
        path = payload["path"] as? String ?? ""
        method = payload["method"] as? String ?? ""
        status = payload["status"] as? String ?? ""
    }
}

struct OperationLogsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var logs: [OperationLogRow] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(icon: "list.bullet.rectangle",
                               message: translations.get("logsOperationEmptyTitle",
                                                         fallback: "No operation logs"))
            } else {
                List {
                    Section(translations.get("logsOperationTabLabel", fallback: "Operation")) {
                        ForEach(logs) { log in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(log.path)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    if !log.status.isEmpty {
                                        StatusBadge(text: log.status, color: .gray)
                                    }
                                }
                                HStack(spacing: 12) {
                                    if !log.method.isEmpty { Label(log.method, systemImage: "arrow.left.arrow.right") }
                                    if !log.ip.isEmpty { Label(log.ip, systemImage: "network") }
                                    if !log.source.isEmpty { Label(log.source, systemImage: "person") }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                .help(translations.get("commonRefresh", fallback: "Refresh"))
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
                "getOperationLogs",
                arguments: ["page": 1, "pageSize": 100]
            )
            logs = (raw as? [[String: Any]] ?? []).compactMap(OperationLogRow.init)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct LoginLogRow: Identifiable {
    let loginId: Int
    let ip: String
    let address: String
    let status: String
    let createdAt: String

    var id: Int { loginId }

    init?(payload: [String: Any]) {
        guard let id = payload["id"] as? Int else { return nil }
        loginId = id
        ip = payload["ip"] as? String ?? ""
        address = payload["address"] as? String ?? ""
        status = payload["status"] as? String ?? ""
        createdAt = payload["createdAt"] as? String ?? ""
    }
}

struct LoginLogsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var logs: [LoginLogRow] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(icon: "person.badge.key",
                               message: translations.get("logsLoginEmptyTitle",
                                                         fallback: "No login logs"))
            } else {
                List {
                    Section(translations.get("logsLoginTabLabel", fallback: "Login")) {
                        ForEach(logs) { log in
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(log.ip).font(.subheadline.weight(.medium))
                                    Spacer()
                                    if !log.status.isEmpty {
                                        StatusBadge(text: log.status,
                                                    color: log.status.lowercased() == "success"
                                                        ? .green : .red)
                                    }
                                }
                                HStack(spacing: 12) {
                                    if !log.address.isEmpty {
                                        Label(log.address, systemImage: "mappin.and.ellipse")
                                    }
                                    if !log.createdAt.isEmpty {
                                        Label(log.createdAt, systemImage: "clock")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getLoginLogs",
                arguments: ["page": 1, "pageSize": 100]
            )
            logs = (raw as? [[String: Any]] ?? []).compactMap(LoginLogRow.init)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct TaskLogRow: Identifiable {
    let taskId: String
    let name: String
    let type: String
    let operate: String
    let status: String
    let createdAt: String
    let resourceId: Int

    var id: String { taskId }
}

struct TaskLogsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var logs: [TaskLogRow] = []
    @State private var isLoading = false
    @State private var statusFilter = ""
    @State private var selectedLog: TaskLogRow?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(icon: "gearshape.2",
                               message: translations.get("logsTaskEmptyTitle",
                                                         fallback: "No task logs"))
            } else {
                List {
                    Section(translations.get("logsCenterTabTask", fallback: "Tasks")) {
                        ForEach(logs) { log in
                            Button {
                                selectedLog = log
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(log.name.isEmpty ? log.taskId : log.name)
                                            .font(.subheadline.weight(.medium))
                                            .lineLimit(2)
                                        Spacer()
                                        StatusBadge(text: log.status,
                                                    color: log.status.lowercased() == "success"
                                                        ? .green : .gray)
                                    }
                                    HStack(spacing: 12) {
                                        if !log.type.isEmpty {
                                            Label(log.type, systemImage: "square.grid.2x2")
                                        }
                                        if !log.createdAt.isEmpty {
                                            Label(log.createdAt, systemImage: "clock")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await load()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(translations.get("logsStatusAll", fallback: "All")) {
                        statusFilter = ""
                        Task { await load() }
                    }
                    Button(translations.get("logsStatusSuccess", fallback: "Success")) {
                        statusFilter = "Success"
                        Task { await load() }
                    }
                    Button(translations.get("logsStatusFailed", fallback: "Failed")) {
                        statusFilter = "Failed"
                        Task { await load() }
                    }
                    Button(translations.get("logsStatusExecuting", fallback: "Executing")) {
                        statusFilter = "Executing"
                        Task { await load() }
                    }
                } label: {
                    Label(translations.get("logsTaskDetailStatusLabel", fallback: "Status"),
                          systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await load() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(item: $selectedLog) { log in
            TaskLogContentView(log: log)
                .frame(minWidth: 760, minHeight: 520)
        }
        .task {
            await load()
        }
    }

    private func load() async {
        isLoading = true
        var arguments: [String: Any] = ["page": 1, "pageSize": 100]
        if !statusFilter.isEmpty { arguments["status"] = statusFilter }
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getTaskLogs",
                arguments: arguments
            )
            let items = raw as? [[String: Any]] ?? []
            logs = items.compactMap { item in
                guard let taskId = item["id"] as? String, !taskId.isEmpty else { return nil }
                return TaskLogRow(
                    taskId: taskId,
                    name: item["name"] as? String ?? "",
                    type: item["type"] as? String ?? "",
                    operate: item["operate"] as? String ?? "",
                    status: item["status"] as? String ?? "",
                    createdAt: item["createdAt"] as? String ?? "",
                    resourceId: item["resourceId"] as? Int ?? 0
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct TaskLogContentView: View {
    @EnvironmentObject private var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let log: TaskLogRow

    @State private var lines: [String] = []
    @State private var taskStatus = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && lines.isEmpty {
                    LoadingView()
                } else if lines.isEmpty {
                    EmptyStateView(icon: "doc.text",
                                   message: translations.get("commonEmpty", fallback: "No data"))
                } else {
                    ScrollView {
                        Text(lines.joined(separator: "\n"))
                            .font(.system(.caption2, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                }
            }
            .navigationTitle(log.name.isEmpty ? log.taskId : log.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    if !taskStatus.isEmpty {
                        StatusBadge(text: taskStatus,
                                    color: taskStatus.lowercased() == "success" ? .green : .gray)
                    }
                    Button {
                        Task { await load() }
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"),
                              systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await load()
            }
        }
    }

    private func load() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getTaskLogContent",
                arguments: [
                    "taskId": log.taskId,
                    "taskType": log.type,
                    "taskOperate": log.operate,
                    "resourceId": log.resourceId,
                ]
            )
            let dict = raw as? [String: Any] ?? [:]
            taskStatus = dict["taskStatus"] as? String ?? ""
            lines = (dict["lines"] as? [Any] ?? []).compactMap { $0 as? String }
        } catch {
            lines = []
        }
        isLoading = false
    }
}

struct SystemLogsSection: View {
    @EnvironmentObject private var translations: TranslationsManager
    @State private var files: [String] = []
    @State private var selectedFile = ""
    @State private var lines: [String] = []
    @State private var useCoreLogs = false
    @State private var isLoadingFiles = false
    @State private var isLoadingContent = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Toggle(translations.get("hostLogsCoreToggle", fallback: "Core logs"),
                       isOn: Binding(
                        get: { useCoreLogs },
                        set: { value in
                            useCoreLogs = value
                            if !selectedFile.isEmpty {
                                Task { await loadContent(selectedFile) }
                            }
                        }
                       ))
                Spacer()
                Menu {
                    ForEach(files, id: \.self) { file in
                        Button(file) {
                            selectedFile = file
                            Task { await loadContent(file) }
                        }
                    }
                } label: {
                    Label(selectedFile.isEmpty
                          ? translations.get("logsSystemFilesLabel", fallback: "Log files")
                          : selectedFile,
                          systemImage: "doc.text.magnifyingglass")
                }
                .disabled(files.isEmpty)
                Button {
                    Task { await loadFiles() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoadingFiles)
            }
            .padding(16)

            if isLoadingFiles && files.isEmpty {
                LoadingView()
            } else if lines.isEmpty {
                EmptyStateView(icon: "doc.text",
                               message: translations.get("commonEmpty", fallback: "No data"))
            } else {
                ScrollView {
                    Text(lines.joined(separator: "\n"))
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .task {
            if files.isEmpty {
                await loadFiles()
            }
        }
    }

    private func loadFiles() async {
        isLoadingFiles = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync("getSystemLogFiles")
            files = (raw as? [Any] ?? []).compactMap { $0 as? String }
            if selectedFile.isEmpty {
                selectedFile = files.first ?? ""
                if !selectedFile.isEmpty {
                    await loadContent(selectedFile)
                }
            }
        } catch {
            files = []
        }
        isLoadingFiles = false
    }

    private func loadContent(_ fileName: String) async {
        isLoadingContent = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                "getSystemLogContent",
                arguments: ["fileName": fileName, "useCoreLogs": useCoreLogs]
            )
            let dict = raw as? [String: Any] ?? [:]
            lines = (dict["lines"] as? [Any] ?? []).compactMap { $0 as? String }
        } catch {
            lines = []
        }
        isLoadingContent = false
    }
}