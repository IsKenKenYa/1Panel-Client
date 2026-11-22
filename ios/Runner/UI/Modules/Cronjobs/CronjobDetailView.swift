import AppleSharedUI
import SwiftUI

/// 计划任务详情：任务字段、脚本或命令内容与常用操作。
struct CronjobDetailView: View {
    let job: CronjobModel
    @ObservedObject var viewModel: CronjobsViewModel
    let onEdit: (CronjobModel) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var translations: TranslationsManager

    @State private var info: [String: Any] = [:]
    @State private var isLoading = true
    @State private var showRecords = false
    @State private var showDeleteConfirm = false
    @State private var actionMessage: String?
    @State private var currentStatus: String

    init(job: CronjobModel,
         viewModel: CronjobsViewModel,
         onEdit: @escaping (CronjobModel) -> Void) {
        self.job = job
        self.viewModel = viewModel
        self.onEdit = onEdit
        _currentStatus = State(initialValue: job.status)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(translations.get("cronjobsDetailTitle", fallback: "Cronjob Details")) {
                    HStack {
                        Text(nameValue)
                            .font(.headline)
                        Spacer()
                        StatusBadge(
                            text: statusLabel(currentStatus),
                            color: currentStatus == "Enable" ? .green : .gray
                        )
                    }
                    InfoLine(
                        label: translations.get("cronjobsNameLabel", fallback: "Task Name"),
                        value: nameValue
                    )
                    InfoLine(
                        label: translations.get("cronjobsTypeLabel", fallback: "Type"),
                        value: typeLabel(string("type", fallback: "")),
                    )
                    InfoLine(
                        label: translations.get("cronjobsGroupLabel", fallback: "Group"),
                        value: groupValue
                    )
                    InfoLine(
                        label: translations.get("cronjobsSpecLabel", fallback: "Schedule"),
                        value: specValue
                    )
                    InfoLine(
                        label: translations.get("cronjobsNextRunLabel", fallback: "Next run"),
                        value: job.nextHandle.isEmpty ? "--" : job.nextHandle
                    )
                }

                Section(translations.get("cronjobFormScriptLabel", fallback: "Script")) {
                    if isLoading {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text(translations.get("commonLoading", fallback: "Loading"))
                                .foregroundStyle(.secondary)
                        }
                    } else if let bodyText {
                        Text(verbatim: bodyText)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    } else {
                        Text("--")
                            .foregroundStyle(.secondary)
                    }
                }

                Section(translations.get("websitesDetailActionsTitle", fallback: "Actions")) {
                    Button {
                        runOnce()
                    } label: {
                        Label(translations.get("cronjobsHandleOnceAction",
                                               fallback: "Run once"),
                              systemImage: "play.fill")
                    }
                    Button {
                        toggleStatus()
                    } label: {
                        Label(
                            currentStatus == "Enable"
                                ? translations.get("cronjobsDisableAction", fallback: "Disable")
                                : translations.get("cronjobsEnableAction", fallback: "Enable"),
                            systemImage: currentStatus == "Enable"
                                ? "pause.circle"
                                : "play.circle"
                        )
                    }
                    Button {
                        showRecords = true
                    } label: {
                        Label(translations.get("cronjobsRecordsAction", fallback: "Records"),
                              systemImage: "list.bullet.rectangle")
                    }
                    Button {
                        onEdit(job)
                    } label: {
                        Label(translations.get("commonEdit", fallback: "Edit"),
                              systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(translations.get("commonDelete", fallback: "Delete"),
                              systemImage: "trash")
                    }
                }

                if let actionMessage {
                    Section {
                        Text(actionMessage)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(translations.get("cronjobsDetailTitle", fallback: "Cronjob Details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showRecords) {
                CronjobRecordsView(job: job)
                    .environmentObject(translations)
            }
            .confirmationDialog(
                translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                    delete()
                }
                Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
            } message: {
                Text(translations.get("deleteCannotUndoMessage",
                                      fallback: "This action cannot be undone."))
            }
            .task {
                loadInfo()
            }
        }
    }

    private var nameValue: String {
        string("name", fallback: job.name)
    }

    private var specValue: String {
        let custom = string("specCustom", fallback: "")
        let spec = string("spec", fallback: job.spec)
        return custom.isEmpty ? spec : custom
    }

    private var groupValue: String {
        let group = info["groupID"]
        guard let group else { return "--" }
        let text = "\(group)"
        return text.isEmpty || text == "0" ? "--" : text
    }

    private var bodyText: String? {
        let script = string("script", fallback: "")
        if !script.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return script
        }
        let command = string("command", fallback: "")
        if !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return command
        }
        return nil
    }

    private func string(_ key: String, fallback: String) -> String {
        let value = info[key] as? String ?? ""
        return value.isEmpty ? fallback : value
    }

    private func loadInfo() {
        isLoading = true
        viewModel.loadInfo(id: job.id) { loaded in
            info = loaded ?? [:]
            if let status = loaded?["status"] as? String, !status.isEmpty {
                currentStatus = status
            }
            isLoading = false
        }
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "Enable":
            return translations.get("cronjobsStatusEnable", fallback: "Enabled")
        case "Disable":
            return translations.get("cronjobsStatusDisable", fallback: "Disabled")
        default:
            return status.isEmpty ? "--" : status
        }
    }

    private func typeLabel(_ type: String) -> String {
        switch type.lowercased() {
        case "shell":
            return translations.get("cronjobsTypeShell", fallback: "Shell")
        case "website":
            return translations.get("cronjobsTypeWebsite", fallback: "Website")
        case "database":
            return translations.get("cronjobsTypeDatabase", fallback: "Database")
        case "directory":
            return translations.get("cronjobsTypeDirectory", fallback: "Directory")
        case "log":
            return translations.get("cronjobsTypeLog", fallback: "Log")
        case "snapshot":
            return translations.get("cronjobsTypeSnapshot", fallback: "Snapshot")
        default:
            return type.isEmpty ? "--" : type
        }
    }

    private func runOnce() {
        viewModel.handleOnce(id: job.id) { success in
            actionMessage = success
                ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                : translations.get("commonOperationFailed", fallback: "Operation failed")
            if success { viewModel.fetch() }
        }
    }

    private func toggleStatus() {
        viewModel.toggleStatus(id: job.id, currentStatus: currentStatus) { success in
            if success {
                currentStatus = currentStatus == "Enable" ? "Disable" : "Enable"
                actionMessage = translations.get("commonSaveSuccess", fallback: "Saved")
                viewModel.fetch()
            } else {
                actionMessage = translations.get("commonSaveFailed", fallback: "Save failed")
            }
        }
    }

    private func delete() {
        viewModel.delete(id: job.id) { success in
            if success {
                viewModel.fetch()
                dismiss()
            } else {
                actionMessage = translations.get("commonDeleteFailed", fallback: "Delete failed")
            }
        }
    }
}