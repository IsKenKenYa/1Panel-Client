import SwiftUI
import AppleSharedUI

/// 编排项目列表：启动、停止、重启、删除，并支持从路径或内容新建项目。
struct ContainerComposeRow: Identifiable {
    let id: String
    let name: String
    let path: String
    let status: String
    let createTime: String
    let containerCount: Int
    let runningCount: Int

    var isRunning: Bool {
        if runningCount > 0 { return true }
        let lower = status.lowercased()
        return lower.contains("running") || lower.contains("started")
    }
}

struct ContainerComposeListView: View {
    @EnvironmentObject var translations: TranslationsManager

    @State private var projects: [ContainerComposeRow] = []
    @State private var isLoading = false
    @State private var showCreateSheet = false
    @State private var newName = ""
    @State private var newSource = "path"
    @State private var newPath = ""
    @State private var newContent = "services:\n"
    @State private var pendingDelete: ContainerComposeRow?
    @State private var deleteForce = true
    @State private var deleteFile = false
    @State private var toastText: String?

    var body: some View {
        Group {
            if isLoading && projects.isEmpty {
                LoadingView()
            } else if projects.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(projects) { project in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "shippingbox")
                                .font(.title3)
                                .foregroundColor(project.isRunning ? .green : .secondary)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(project.name)
                                        .font(.subheadline.weight(.medium))
                                        .lineLimit(1)
                                    StatusBadge(
                                        text: statusText(project),
                                        color: project.isRunning ? .green : .gray
                                    )
                                }
                                if !project.path.isEmpty {
                                    Label(project.path, systemImage: "doc.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                if !project.createTime.isEmpty {
                                    Label(TimestampFormat.display(project.createTime),
                                          systemImage: "clock")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if project.containerCount > 0 {
                                    Label("\(translations.get("containerTabContainers", fallback: "Containers")) \(project.runningCount)/\(project.containerCount)",
                                          systemImage: "shippingbox")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Menu {
                                Button {
                                    operate(project, "up")
                                } label: {
                                    Label(translations.get("commonStart", fallback: "Start"),
                                          systemImage: "play.fill")
                                }
                                Button {
                                    operate(project, "down")
                                } label: {
                                    Label(translations.get("commonStop", fallback: "Stop"),
                                          systemImage: "stop.fill")
                                }
                                Button {
                                    operate(project, "restart")
                                } label: {
                                    Label(translations.get("commonRestart", fallback: "Restart"),
                                          systemImage: "arrow.clockwise")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    deleteForce = true
                                    deleteFile = false
                                    pendingDelete = project
                                } label: {
                                    Label(translations.get("commonDelete", fallback: "Delete"),
                                          systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteForce = true
                                deleteFile = false
                                pendingDelete = project
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newName = ""
                    newSource = "path"
                    newPath = ""
                    newContent = "services:\n"
                    showCreateSheet = true
                } label: {
                    Label(translations.get("orchestrationCreateProject", fallback: "Create Project"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            createSheet
        }
        .sheet(item: $pendingDelete) { project in
            deleteSheet(project)
        }
        .operationNotice(toastText)
        .onAppear {
            if projects.isEmpty {
                fetch()
            }
        }
    }

    private var createSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"),
                              text: $newName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Picker("", selection: $newSource) {
                        Text(translations.get("orchestrationComposeSourcePath",
                                              fallback: "Existing file"))
                            .tag("path")
                        Text(translations.get("orchestrationComposeContentLabel",
                                              fallback: "Compose content"))
                            .tag("content")
                    }
                    .pickerStyle(.segmented)
                    if newSource == "path" {
                        TextField(translations.get("orchestrationComposePathHint",
                                                   fallback: "Compose file path"),
                                  text: $newPath)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        TextEditor(text: $newContent)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 180)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } footer: {
                    Text(newSource == "path"
                         ? translations.get("orchestrationComposePathHint",
                                            fallback: "Compose file path")
                         : translations.get("orchestrationComposeContentHint",
                                            fallback: "Paste docker-compose.yml content"))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("orchestrationComposeCreateTitle",
                                              fallback: "Create Compose Project"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showCreateSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        createProject()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    private var canCreate: Bool {
        let name = newName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty { return false }
        if newSource == "path" {
            return !newPath.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func deleteSheet(_ project: ContainerComposeRow) -> some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(translations.get("orchestrationComposeForceDelete",
                                            fallback: "Force delete"),
                           isOn: $deleteForce)
                    Toggle(translations.get("orchestrationComposeDeleteFile",
                                            fallback: "Delete compose file"),
                           isOn: $deleteFile)
                } footer: {
                    Text(translations.get("orchestrationComposeDeleteConfirm",
                                          fallback: "Stop and delete all containers in this project?")
                        .replacingOccurrences(of: "{name}", with: project.name))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("orchestrationComposeDelete", fallback: "Delete Compose"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        pendingDelete = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                        confirmDelete(project)
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getComposes") { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                projects = items.compactMap { item in
                    guard let name = item["name"] as? String, !name.isEmpty else { return nil }
                    let rawId = item["id"] as? String ?? ""
                    return ContainerComposeRow(
                        id: rawId.isEmpty ? name : rawId,
                        name: name,
                        path: item["path"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        createTime: item["createTime"] as? String ?? "",
                        containerCount: item["containerCount"] as? Int ?? 0,
                        runningCount: item["runningCount"] as? Int ?? 0
                    )
                }
            }
        }
    }

    private func operate(_ project: ContainerComposeRow, _ operation: String) {
        ChannelManager.shared.invokeDataMethod(
            "composeOperate",
            arguments: [
                "name": project.name,
                "path": project.path,
                "operation": operation,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                    : translations.get("commonOperationFailed", fallback: "Operation failed"))
                if success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        fetch()
                    }
                }
            }
        }
    }

    private func createProject() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        var arguments: [String: Any] = ["name": name]
        if newSource == "path" {
            arguments["from"] = "path"
            arguments["path"] = newPath.trimmingCharacters(in: .whitespaces)
        } else {
            arguments["from"] = "edit"
            arguments["file"] = newContent
        }
        ChannelManager.shared.invokeDataMethod("createCompose", arguments: arguments) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showCreateSheet = false
                showToast(success
                    ? translations.get("commonCreateSuccess", fallback: "Created")
                    : translations.get("commonSaveFailed", fallback: "Save failed"))
                if success {
                    fetch()
                }
            }
        }
    }

    private func confirmDelete(_ project: ContainerComposeRow) {
        pendingDelete = nil
        ChannelManager.shared.invokeDataMethod(
            "composeOperate",
            arguments: [
                "name": project.name,
                "path": project.path,
                "operation": "delete",
                "force": deleteForce,
                "withFile": deleteFile,
            ]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                showToast(success
                    ? translations.get("commonDeleted", fallback: "Deleted")
                    : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                if success {
                    fetch()
                }
            }
        }
    }

    private func statusText(_ project: ContainerComposeRow) -> String {
        if project.isRunning {
            return translations.get("containerStatusRunning", fallback: "Running")
        }
        if project.containerCount > 0 {
            return translations.get("statusStopped", fallback: "Stopped")
        }
        let status = project.status
        let lower = status.lowercased()
        if lower.contains("running") || lower.contains("started") {
            return translations.get("containerStatusRunning", fallback: "Running")
        }
        if lower.contains("stop") || lower.contains("exit") || lower.contains("down") {
            return translations.get("statusStopped", fallback: "Stopped")
        }
        if status.isEmpty {
            return translations.get("orchestrationStatusUnknown", fallback: "Unknown")
        }
        return status
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
