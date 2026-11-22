import AppleSharedUI
import SwiftUI

struct ContainerComposeProject: Identifiable, Equatable {
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

@MainActor
final class ContainerComposeStore: ObservableObject {
    @Published var projects: [ContainerComposeProject] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetch() async {
        isLoading = true
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync("getComposes")
            projects = (raw as? [[String: Any]] ?? []).compactMap { item in
                guard let name = item["name"] as? String, !name.isEmpty else {
                    return nil
                }
                let rawId = item["id"] as? String ?? ""
                return ContainerComposeProject(
                    id: rawId.isEmpty ? name : rawId,
                    name: name,
                    path: item["path"] as? String ?? "",
                    status: item["status"] as? String ?? "",
                    createTime: item["createTime"] as? String ?? "",
                    containerCount: item["containerCount"] as? Int ?? 0,
                    runningCount: item["runningCount"] as? Int ?? 0
                )
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func operate(_ project: ContainerComposeProject, operation: String) async -> String? {
        let error = await perform(
            "composeOperate",
            [
                "name": project.name,
                "path": project.path,
                "operation": operation,
            ]
        )
        if error == nil { await fetch() }
        return error
    }

    func create(
        name: String,
        source: String,
        path: String,
        content: String
    ) async -> String? {
        var arguments: [String: Any] = ["name": name]
        if source == "path" {
            arguments["from"] = "path"
            arguments["path"] = path
        } else {
            arguments["from"] = "edit"
            arguments["file"] = content
        }
        let error = await perform("createCompose", arguments)
        if error == nil { await fetch() }
        return error
    }

    func delete(
        _ project: ContainerComposeProject,
        force: Bool,
        withFile: Bool
    ) async -> String? {
        let error = await perform(
            "composeOperate",
            [
                "name": project.name,
                "path": project.path,
                "operation": "delete",
                "force": force,
                "withFile": withFile,
            ]
        )
        if error == nil { await fetch() }
        return error
    }

    private func perform(_ method: String, _ arguments: [String: Any]) async -> String? {
        do {
            let raw = try await ChannelManager.shared.invokeDataMethodAsync(
                method,
                arguments: arguments
            )
            let payload = raw as? [String: Any] ?? [:]
            if payload["success"] as? Bool == true { return nil }
            return payload["error"] as? String
        } catch {
            return error.localizedDescription
        }
    }
}

/// macOS 容器编排分区：项目列表、启停重启、新建与删除。
struct ContainerComposeSectionView: View {
    @StateObject private var store = ContainerComposeStore()
    @EnvironmentObject private var translations: TranslationsManager

    @State private var showCreateSheet = false
    @State private var pendingDelete: ContainerComposeProject?
    @State private var actionError: String?

    var body: some View {
        Group {
            if store.isLoading && store.projects.isEmpty {
                LoadingView()
            } else if let error = store.errorMessage, store.projects.isEmpty {
                ErrorView(message: error) {
                    Task { await store.fetch() }
                }
            } else if store.projects.isEmpty {
                EmptyStateView(
                    icon: "shippingbox",
                    message: translations.get("commonEmpty", fallback: "No data")
                )
            } else {
                List {
                    ForEach(store.projects) { project in
                        row(project)
                    }
                }
                .listStyle(.inset)
                .refreshable {
                    await store.fetch()
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    Task { await store.fetch() }
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"),
                          systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
                Button {
                    showCreateSheet = true
                } label: {
                    Label(translations.get("orchestrationComposeCreateTitle",
                                           fallback: "Create Compose Project"),
                          systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            ContainerComposeCreateSheet(store: store)
        }
        .sheet(item: $pendingDelete) { project in
            ContainerComposeDeleteSheet(store: store, project: project)
        }
        .alert(
            translations.get("commonError", fallback: "Error"),
            isPresented: Binding(
                get: { actionError != nil },
                set: { if !$0 { actionError = nil } }
            )
        ) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) {
                actionError = nil
            }
        } message: {
            Text(actionError ?? "")
        }
        .task {
            await store.fetch()
        }
    }

    private func row(_ project: ContainerComposeProject) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.title3)
                .foregroundColor(project.isRunning ? .green : .secondary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(project.name)
                        .font(.subheadline.weight(.medium))
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
                if project.containerCount > 0 {
                    Text("\(translations.get("containerTabContainers", fallback: "Containers")) \(project.runningCount)/\(project.containerCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Menu {
                Button {
                    operate(project, operation: "up")
                } label: {
                    Label(translations.get("commonStart", fallback: "Start"),
                          systemImage: "play.fill")
                }
                Button {
                    operate(project, operation: "down")
                } label: {
                    Label(translations.get("commonStop", fallback: "Stop"),
                          systemImage: "stop.fill")
                }
                Button {
                    operate(project, operation: "restart")
                } label: {
                    Label(translations.get("commonRestart", fallback: "Restart"),
                          systemImage: "arrow.clockwise")
                }
                Divider()
                Button(role: .destructive) {
                    pendingDelete = project
                } label: {
                    Label(translations.get("commonDelete", fallback: "Delete"),
                          systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.vertical, 2)
    }

    private func operate(_ project: ContainerComposeProject, operation: String) {
        Task {
            if let error = await store.operate(project, operation: operation) {
                actionError = error.isEmpty
                    ? translations.get("commonOperationFailed", fallback: "Operation failed")
                    : error
            }
        }
    }

    private func statusText(_ project: ContainerComposeProject) -> String {
        if project.isRunning {
            return translations.get("containerStatusRunning", fallback: "Running")
        }
        if project.containerCount > 0 {
            return translations.get("statusStopped", fallback: "Stopped")
        }
        let lower = project.status.lowercased()
        if lower.contains("running") || lower.contains("started") {
            return translations.get("containerStatusRunning", fallback: "Running")
        }
        if lower.contains("stop") || lower.contains("exit") || lower.contains("down") {
            return translations.get("statusStopped", fallback: "Stopped")
        }
        return project.status.isEmpty
            ? translations.get("orchestrationStatusUnknown", fallback: "Unknown")
            : project.status
    }
}

private struct ContainerComposeCreateSheet: View {
    @ObservedObject var store: ContainerComposeStore
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var name = ""
    @State private var source = "path"
    @State private var path = ""
    @State private var content = "services:\n"
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("commonName", fallback: "Name"), text: $name)
                    Picker("", selection: $source) {
                        Text(translations.get("orchestrationComposeSourcePath",
                                              fallback: "Existing File"))
                            .tag("path")
                        Text(translations.get("orchestrationComposeContentLabel",
                                              fallback: "Compose Content"))
                            .tag("content")
                    }
                    .pickerStyle(.segmented)
                    if source == "path" {
                        TextField(translations.get("orchestrationComposePathHint",
                                                   fallback: "Compose file path"),
                                  text: $path)
                    } else {
                        TextEditor(text: $content)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(minHeight: 220)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(translations.get("orchestrationComposeCreateTitle",
                                              fallback: "Create Compose Project"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonSave", fallback: "Save")) {
                        Task { await submit() }
                    }
                    .disabled(isSaving || !canCreate)
                }
            }
        }
        .frame(width: 560, height: 480)
    }

    private var canCreate: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return false }
        if source == "path" {
            return !path.trimmingCharacters(in: .whitespaces).isEmpty
        }
        return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func submit() async {
        isSaving = true
        if let error = await store.create(
            name: name.trimmingCharacters(in: .whitespaces),
            source: source,
            path: path.trimmingCharacters(in: .whitespaces),
            content: content
        ) {
            errorMessage = error.isEmpty
                ? translations.get("commonSaveFailed", fallback: "Save failed")
                : error
        } else {
            dismiss()
        }
        isSaving = false
    }
}

private struct ContainerComposeDeleteSheet: View {
    @ObservedObject var store: ContainerComposeStore
    let project: ContainerComposeProject
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var force = true
    @State private var withFile = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(translations.get("orchestrationComposeForceDelete",
                                            fallback: "Force Delete"),
                           isOn: $force)
                    Toggle(translations.get("orchestrationComposeDeleteFile",
                                            fallback: "Delete Compose File"),
                           isOn: $withFile)
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text(translations.get("orchestrationComposeDeleteConfirm",
                                          fallback: "Stop and remove all containers in {name}?")
                        .replacingOccurrences(of: "{name}", with: project.name))
                        .font(.footnote)
                }
            }
            .navigationTitle(translations.get("orchestrationComposeDelete",
                                              fallback: "Delete Compose"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(translations.get("commonDelete", fallback: "Delete")) {
                        Task { await submit() }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .frame(width: 460, height: 280)
    }

    private func submit() async {
        isDeleting = true
        if let error = await store.delete(project, force: force, withFile: withFile) {
            errorMessage = error.isEmpty
                ? translations.get("commonDeleteFailed", fallback: "Delete failed")
                : error
        } else {
            dismiss()
        }
        isDeleting = false
    }
}