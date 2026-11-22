import AppleSharedUI
import SwiftUI

/// macOS Compose 项目详情：概览、配置文件编辑与日志。
struct ContainerComposeDetailView: View {
    @ObservedObject var store: ContainerComposeStore
    let project: ContainerComposeProject

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var section = "overview"
    @State private var content = ""
    @State private var originalContent = ""
    @State private var containers: [ContainerComposeContainer] = []
    @State private var logs = ""
    @State private var isLoading = true
    @State private var isLoadingLogs = false
    @State private var isSaving = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var composePaths: [String] = []
    @State private var selectedPath = ""
    @State private var selectedLogContainer = ""
    @State private var followLogs = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("", selection: $section) {
                    Text(t("vmTabOverview", "Overview")).tag("overview")
                    Text(t("containerComposeFileTitle", "Compose file")).tag("file")
                    Text(t("containerActionLogs", "Logs")).tag("logs")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Divider()
                if isLoading && containers.isEmpty && content.isEmpty {
                    LoadingView()
                } else {
                    contentView
                }
            }
            .navigationTitle(project.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("commonClose", "Close")) { dismiss() }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        Task { await loadAll() }
                    } label: {
                        Label(t("commonRefresh", "Refresh"),
                              systemImage: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadAll()
            }
            .task(id: followLogs) {
                guard followLogs else { return }
                while !Task.isCancelled {
                    if section == "logs" {
                        await refreshLogs()
                    }
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
            .alert(
                t("commonError", "Error"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(t("commonOk", "OK"), role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch section {
        case "file":
            fileContent
        case "logs":
            logsContent
        default:
            overviewContent
        }
    }

    private var overviewContent: some View {
        List {
            Section(t("containerComposeDetailTitle", "Compose details")) {
                InfoLine(label: t("commonName", "Name"), value: project.name)
                InfoLine(label: t("containerComposeFileTitle", "Compose file"),
                         value: project.path.isEmpty ? "--" : project.path)
                InfoLine(label: t("commonStatus", "Status"), value: statusText)
                InfoLine(label: t("backupRecordsDateLabel", "Created"),
                         value: project.createTime.isEmpty
                             ? "--"
                             : TimestampFormat.display(project.createTime))
                InfoLine(label: t("containerTabContainers", "Containers"),
                         value: "\(project.runningCount)/\(project.containerCount)")
            }
            Section(t("containerTabContainers", "Containers")) {
                if containers.isEmpty {
                    Text(t("commonEmpty", "No data"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(containers) { container in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(container.name)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                StatusBadge(
                                    text: container.state.isEmpty ? "--" : container.state,
                                    color: container.state.lowercased() == "running"
                                        ? .green
                                        : .gray
                                )
                            }
                            Text(container.image.isEmpty ? container.status : container.image)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            Section(t("websitesDetailActionsTitle", "Actions")) {
                actionButton("up", titleKey: "commonStart", icon: "play.fill")
                actionButton("restart", titleKey: "commonRestart",
                             icon: "arrow.clockwise")
                actionButton("down", titleKey: "commonStop", icon: "stop.fill")
            }
        }
        .listStyle(.inset)
    }

    private var fileContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if composePaths.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Picker(
                        t("containerComposeFileTitle", "Compose file"),
                        selection: Binding(
                            get: { selectedPath },
                            set: { newValue in
                                selectedPath = newValue
                                Task { await loadSelectedContent() }
                            }
                        )
                    ) {
                        ForEach(composePaths, id: \.self) { path in
                            Text(fileName(path)).tag(path)
                        }
                    }
                    .pickerStyle(.menu)
                    Text(selectedPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }
            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
            if let statusMessage {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
            HStack(spacing: 12) {
                Button {
                    Task { await saveContent() }
                } label: {
                    Label(t("orchestrationComposeUpdate", "Update Compose"),
                          systemImage: "square.and.arrow.down")
                }
                .disabled(isSaving || content == originalContent)
                Button {
                    Task { await validateContent() }
                } label: {
                    Label(t("orchestrationComposeTest", "Test Compose"),
                          systemImage: "checkmark.seal")
                }
                .disabled(isSaving || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Button {
                    Task { await cleanLogs() }
                } label: {
                    Label(t("orchestrationComposeCleanLog", "Clean Compose Logs"),
                          systemImage: "trash.slash")
                }
                .disabled(isSaving)
                Spacer()
                if isSaving {
                    ProgressView().controlSize(.small)
                }
            }
            .padding(12)
        }
    }

    private var logsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Picker(
                    "",
                    selection: Binding(
                        get: { selectedLogContainer },
                        set: { newValue in
                            selectedLogContainer = newValue
                            Task { await loadLogs() }
                        }
                    )
                ) {
                    Text(t("containerComposeAllContainers", "All containers"))
                        .tag("")
                    ForEach(containers) { container in
                        Text(container.name).tag(container.name)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 260)
                Toggle(t("containerLogsAutoRefresh", "Auto Refresh"),
                       isOn: $followLogs)
                    .toggleStyle(.switch)
                if isLoadingLogs {
                    ProgressView().controlSize(.small)
                }
                Spacer()
                Button {
                    Task { await loadLogs() }
                } label: {
                    Label(t("commonRefresh", "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(isLoadingLogs)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            if logs.isEmpty {
                EmptyStateView(icon: "doc.text",
                               message: t("containerLogsEmpty", "No logs"))
            } else {
                ScrollView {
                    Text(verbatim: logs)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
        }
    }

    private func actionButton(_ operation: String, titleKey: String, icon: String) -> some View {
        Button {
            Task { await operate(operation) }
        } label: {
            Label(t(titleKey, operation), systemImage: icon)
        }
        .disabled(isSaving)
    }

    private var statusText: String {
        if project.isRunning {
            return t("containerStatusRunning", "Running")
        }
        if project.containerCount > 0 {
            return t("statusStopped", "Stopped")
        }
        return project.status.isEmpty ? "--" : project.status
    }

    private func loadAll() async {
        isLoading = true
        composePaths = project.path
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        if selectedPath.isEmpty || !composePaths.contains(selectedPath) {
            selectedPath = composePaths.first ?? ""
        }
        do {
            if !selectedPath.isEmpty {
                content = try await store.loadContent(
                    name: project.name,
                    path: selectedPath
                )
                originalContent = content
            }
            containers = try await store.loadContainers(name: project.name)
            if !selectedLogContainer.isEmpty &&
                !containers.contains(where: { $0.name == selectedLogContainer }) {
                selectedLogContainer = ""
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadSelectedContent() async {
        guard !selectedPath.isEmpty else {
            content = ""
            originalContent = ""
            return
        }
        isLoading = true
        do {
            content = try await store.loadContent(
                name: project.name,
                path: selectedPath
            )
            originalContent = content
            statusMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func operate(_ operation: String) async {
        isSaving = true
        if let error = await store.operate(project, operation: operation) {
            errorMessage = fallback(error)
        } else {
            statusMessage = t("commonOperationSuccess", "Operation succeeded")
        }
        isSaving = false
    }

    private func saveContent() async {
        isSaving = true
        if let error = await store.updateContent(
            name: project.name,
            path: project.path,
            detailPath: selectedPath,
            content: content
        ) {
            errorMessage = fallback(error)
        } else {
            originalContent = content
            statusMessage = t("commonSaveSuccess", "Saved")
        }
        isSaving = false
    }

    private func validateContent() async {
        isSaving = true
        if let error = await store.validateContent(name: project.name, content: content) {
            errorMessage = fallback(error)
        } else {
            statusMessage = t("containerComposeValidateSuccess",
                              "Compose validation passed")
        }
        isSaving = false
    }

    private func cleanLogs() async {
        isSaving = true
        if let error = await store.cleanLogs(name: project.name, path: project.path) {
            errorMessage = fallback(error)
        } else {
            statusMessage = t("orchestrationComposeCleanLog", "Clean Compose Logs")
            logs = ""
        }
        isSaving = false
    }

    private func loadLogs() async {
        isLoadingLogs = true
        do {
            logs = try await store.loadLogs(
                name: project.name,
                container: selectedLogContainer
            )
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoadingLogs = false
    }

    private func refreshLogs() async {
        do {
            logs = try await store.loadLogs(
                name: project.name,
                container: selectedLogContainer
            )
        } catch {
            followLogs = false
            errorMessage = error.localizedDescription
        }
    }

    private func fileName(_ path: String) -> String {
        (path as NSString).lastPathComponent
    }

    private func fallback(_ error: String) -> String {
        error.isEmpty ? t("commonOperationFailed", "Operation failed") : error
    }

    private func t(_ key: String, _ fallback: String) -> String {
        translations.get(key, fallback: fallback)
    }
}