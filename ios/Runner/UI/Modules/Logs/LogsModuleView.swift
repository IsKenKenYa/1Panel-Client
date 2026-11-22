import SwiftUI
import AppleSharedUI

/// 日志模块：操作日志 / 登录日志 / 任务日志 / 系统日志四个子页签。
struct LogsModuleView: View {
    @EnvironmentObject var translations: TranslationsManager

    /// 走查钩子：`ONEPANEL_LOGS_TAB=operation|login|task|system` 直接进入子页签。
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            switch tab {
            case "login":
                LoginLogsView()
            case "task":
                TaskLogsView()
            case "system":
                SystemLogsView()
            default:
                OperationLogsView()
            }
        }
        .navigationTitle(translations.get("operationsLogsTitle", fallback: "Logs"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .logs)
            }
        }
    }
}

struct OperationLogRow: Identifiable {
    let id: Int
    let source: String
    let ip: String
    let path: String
    let method: String
    let status: String
    let message: String
}

struct OperationLogsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var logs: [OperationLogRow] = []
    @State private var isLoading = false
    @State private var selectedLog: OperationLogRow?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.rectangle",
                    message: translations.get("logsOperationEmptyTitle", fallback: "No operation logs")
                )
            } else {
                List {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
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
                                if !log.method.isEmpty {
                                    Label(log.method, systemImage: "arrow.left.arrow.right")
                                }
                                if !log.ip.isEmpty {
                                    Label(log.ip, systemImage: "network")
                                }
                                if !log.source.isEmpty {
                                    Label(log.source, systemImage: "person")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLog = log
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(item: $selectedLog) { log in
            OperationLogDetailView(log: log)
                .environmentObject(translations)
        }
        .onAppear {
            if logs.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getOperationLogs",
            arguments: ["page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                logs = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return OperationLogRow(
                        id: id,
                        source: item["source"] as? String ?? "",
                        ip: item["ip"] as? String ?? "",
                        path: item["path"] as? String ?? "",
                        method: item["method"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        message: item["message"] as? String ?? ""
                    )
                }
            }
        }
    }
}

struct LoginLogRow: Identifiable {
    let id: Int
    let ip: String
    let address: String
    let status: String
    let createdAt: String
    let message: String
}

struct LoginLogsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var logs: [LoginLogRow] = []
    @State private var isLoading = false
    @State private var selectedLoginLog: LoginLogRow?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(
                    icon: "person.badge.key",
                    message: translations.get("logsLoginEmptyTitle", fallback: "No login logs")
                )
            } else {
                List {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(log.ip.isEmpty ? "--" : log.ip)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                if !log.status.isEmpty {
                                    StatusBadge(
                                        text: log.status,
                                        color: StatusPalette.cronjobStatus(log.status)
                                    )
                                }
                            }
                            HStack(spacing: 12) {
                                if !log.address.isEmpty {
                                    Label(log.address, systemImage: "mappin.and.ellipse")
                                }
                                if !log.createdAt.isEmpty {
                                    Label(TimestampFormat.display(log.createdAt), systemImage: "clock")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedLoginLog = log
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(item: $selectedLoginLog) { log in
            LoginLogDetailView(log: log)
                .environmentObject(translations)
        }
        .onAppear {
            if logs.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getLoginLogs",
            arguments: ["page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                logs = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return LoginLogRow(
                        id: id,
                        ip: item["ip"] as? String ?? "",
                        address: item["address"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        createdAt: item["createdAt"] as? String ?? "",
                        message: item["message"] as? String ?? ""
                    )
                }
            }
        }
    }
}

struct TaskLogRow: Identifiable {
    let id: String
    let name: String
    let type: String
    let operate: String
    let status: String
    let createdAt: String
    let resourceId: Int
}

/// 任务日志：后台任务列表，点击查看任务日志内容。
struct TaskLogsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var logs: [TaskLogRow] = []
    @State private var isLoading = false
    @State private var statusFilter = ""
    @State private var selectedLog: TaskLogRow?

    var body: some View {
        Group {
            if isLoading && logs.isEmpty {
                LoadingView()
            } else if logs.isEmpty {
                EmptyStateView(
                    icon: "gearshape.2",
                    message: translations.get("logsTaskEmptyTitle", fallback: "No task logs")
                )
            } else {
                List {
                    ForEach(logs) { log in
                        Button {
                            selectedLog = log
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(log.name.isEmpty ? log.id : log.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(2)
                                    Spacer()
                                    StatusBadge(
                                        text: statusText(log.status),
                                        color: StatusPalette.cronjobStatus(log.status)
                                    )
                                }
                                HStack(spacing: 12) {
                                    if !log.type.isEmpty {
                                        Label(log.type, systemImage: "square.grid.2x2")
                                    }
                                    if !log.createdAt.isEmpty {
                                        Label(TimestampFormat.display(log.createdAt),
                                              systemImage: "clock")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button {
                                selectedLog = log
                            } label: {
                                Label(translations.get("logsTaskOpenDetailAction",
                                                       fallback: "View log"),
                                      systemImage: "doc.text.magnifyingglass")
                            }
                            .tint(.blue)
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
                Menu {
                    Button(translations.get("logsStatusAll", fallback: "All")) {
                        statusFilter = ""
                        fetch()
                    }
                    Button(translations.get("logsStatusSuccess", fallback: "Success")) {
                        statusFilter = "Success"
                        fetch()
                    }
                    Button(translations.get("logsStatusFailed", fallback: "Failed")) {
                        statusFilter = "Failed"
                        fetch()
                    }
                    Button(translations.get("logsStatusExecuting", fallback: "Executing")) {
                        statusFilter = "Executing"
                        fetch()
                    }
                } label: {
                    Label(translations.get("logsTaskDetailStatusLabel", fallback: "Status"),
                          systemImage: "line.3.horizontal.decrease.circle")
                }
                Button {
                    fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .sheet(item: $selectedLog) { log in
            TaskLogContentView(log: log)
        }
        .onAppear {
            if logs.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        var arguments: [String: Any] = ["page": 1, "pageSize": 50]
        if !statusFilter.isEmpty {
            arguments["status"] = statusFilter
        }
        ChannelManager.shared.invokeDataMethod("getTaskLogs", arguments: arguments) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                logs = items.compactMap { item in
                    guard let id = item["id"] as? String, !id.isEmpty else { return nil }
                    return TaskLogRow(
                        id: id,
                        name: item["name"] as? String ?? "",
                        type: item["type"] as? String ?? "",
                        operate: item["operate"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        createdAt: item["createdAt"] as? String ?? "",
                        resourceId: item["resourceId"] as? Int ?? 0
                    )
                }
            }
        }
    }

    private func statusText(_ status: String) -> String {
        switch status.lowercased() {
        case "success":
            return translations.get("logsStatusSuccess", fallback: "Success")
        case "failed":
            return translations.get("logsStatusFailed", fallback: "Failed")
        case "running", "executing", "waiting":
            return translations.get("logsStatusExecuting", fallback: "Executing")
        default:
            return status
        }
    }
}

/// 任务日志内容：任务标识、状态与按行日志。
struct TaskLogContentView: View {
    @EnvironmentObject var translations: TranslationsManager
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
                    EmptyStateView(
                        icon: "doc.text",
                        message: translations.get("commonEmpty", fallback: "No data")
                    )
                } else {
                    List {
                        Section(translations.get("logsTaskOpenDetailAction",
                                                 fallback: "View log")) {
                            InfoLine(
                                label: translations.get("logsTaskDetailIdLabel",
                                                        fallback: "Task ID"),
                                value: log.id
                            )
                            if !log.type.isEmpty {
                                InfoLine(
                                    label: translations.get("logsTaskDetailTypeLabel",
                                                            fallback: "Type"),
                                    value: log.type
                                )
                            }
                            InfoLine(
                                label: translations.get("logsTaskDetailStatusLabel",
                                                        fallback: "Status"),
                                value: taskStatus.isEmpty ? log.status : taskStatus
                            )
                            if !log.createdAt.isEmpty {
                                InfoLine(
                                    label: translations.get("logsTaskDetailCreatedAtLabel",
                                                            fallback: "Created"),
                                    value: TimestampFormat.display(log.createdAt)
                                )
                            }
                        }
                        Section(translations.get("cronjobRecordsTitle",
                                                 fallback: "Records")) {
                            Text(verbatim: lines.joined(separator: "\n"))
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(log.name.isEmpty ? log.id : log.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !taskStatus.isEmpty {
                        StatusBadge(
                            text: taskStatus,
                            color: StatusPalette.cronjobStatus(taskStatus)
                        )
                    }
                    Button {
                        fetch()
                    } label: {
                        Label(translations.get("commonRefresh", fallback: "Refresh"),
                              systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            if lines.isEmpty {
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getTaskLogContent",
            arguments: [
                "taskId": log.id,
                "taskType": log.type,
                "taskOperate": log.operate,
                "resourceId": log.resourceId,
            ]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any] else { return }
                taskStatus = dict["taskStatus"] as? String ?? ""
                let rawLines = dict["lines"] as? [Any] ?? []
                lines = rawLines.compactMap { $0 as? String }
            }
        }
    }
}

/// 系统日志：先选文件，再按文件读取内容。
struct SystemLogsView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var files: [String] = []
    @State private var selectedFile = ""
    @State private var lines: [String] = []
    @State private var isLoadingFiles = false
    @State private var isLoadingContent = false
    @State private var useCoreLogs = false

    var body: some View {
        Group {
            if isLoadingFiles && files.isEmpty {
                LoadingView()
            } else if files.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("logsSystemEmptyTitle", fallback: "No system log files")
                )
            } else {
                content
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    fetchFiles()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(isLoadingFiles)
            }
        }
        .onAppear {
            if files.isEmpty {
                fetchFiles()
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            HStack {
                Text(translations.get("hostLogsCoreToggle", fallback: "Core logs"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { useCoreLogs },
                    set: { value in
                        useCoreLogs = value
                        if !selectedFile.isEmpty {
                            loadContent(selectedFile)
                        }
                    }
                ))
                .labelsHidden()
                .controlSize(.mini)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            if selectedFile.isEmpty {
                Menu {
                    ForEach(files, id: \.self) { file in
                        Button(file) {
                            selectedFile = file
                            loadContent(file)
                        }
                    }
                } label: {
                    Label(translations.get("logsSystemFilesLabel", fallback: "Log files"),
                          systemImage: "doc.text.magnifyingglass")
                }
                .padding(.vertical, 24)
            } else {
                HStack {
                    Text(selectedFile)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Menu {
                        ForEach(files, id: \.self) { file in
                            Button(file) {
                                selectedFile = file
                                loadContent(file)
                            }
                        }
                    } label: {
                        Label(translations.get("logsSystemFilesLabel", fallback: "Log files"),
                              systemImage: "chevron.down")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            if isLoadingContent && lines.isEmpty {
                LoadingView()
            } else if lines.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
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
    }

    private func fetchFiles() {
        isLoadingFiles = true
        ChannelManager.shared.invokeDataMethod("getSystemLogFiles") { result in
            DispatchQueue.main.async {
                isLoadingFiles = false
                guard let items = result as? [Any] else { return }
                files = items.compactMap { $0 as? String }
                if selectedFile.isEmpty {
                    selectedFile = files.first ?? ""
                    if !selectedFile.isEmpty {
                        loadContent(selectedFile)
                    }
                }
            }
        }
    }

    private func loadContent(_ fileName: String) {
        isLoadingContent = true
        ChannelManager.shared.invokeDataMethod(
            "getSystemLogContent",
            arguments: ["fileName": fileName, "useCoreLogs": useCoreLogs]
        ) { result in
            DispatchQueue.main.async {
                isLoadingContent = false
                guard let dict = result as? [String: Any],
                      let rawLines = dict["lines"] as? [Any] else {
                    lines = []
                    return
                }
                lines = rawLines.compactMap { $0 as? String }
            }
        }
    }
}
