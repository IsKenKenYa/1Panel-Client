import SwiftUI
import AppleSharedUI

struct CronjobModel: Identifiable {
    let id: Int
    let name: String
    let spec: String
    let status: String
    let nextHandle: String
}

class CronjobsViewModel: ObservableObject {
    @Published var cronjobs: [CronjobModel] = []
    @Published var isLoading = false

    func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod("getCronJobs") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let items = result as? [[String: Any]] else { return }
                self?.cronjobs = items.compactMap { item in
                    guard let id = item["id"] as? Int,
                          let name = item["name"] as? String else { return nil }
                    return CronjobModel(
                        id: id,
                        name: name,
                        spec: item["spec"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        nextHandle: item["nextHandle"] as? String ?? ""
                    )
                }
            }
        }
    }

    func toggleStatus(id: Int, currentStatus: String, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "toggleCronJobStatus",
            arguments: ["id": id, "currentStatus": currentStatus]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }

    func delete(id: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "deleteCronJob",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }

    /// 立即执行一次（handleCronJobOnce 通道）。
    func handleOnce(id: Int, completion: @escaping (Bool) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "handleCronJobOnce",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                completion((result as? [String: Any])?["success"] as? Bool ?? false)
            }
        }
    }

    /// 新建 shell 任务（createCronJob 通道）。
    func create(name: String, spec: String, script: String,
                completion: @escaping (Bool, String?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "createCronJob",
            arguments: ["name": name, "spec": spec, "script": script]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(dict?["success"] as? Bool ?? false, dict?["error"] as? String)
            }
        }
    }

    /// 编辑 shell 任务（updateCronJob 通道）。
    func update(id: Int, name: String, spec: String, script: String,
                completion: @escaping (Bool, String?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "updateCronJob",
            arguments: ["id": id, "name": name, "spec": spec, "script": script]
        ) { result in
            DispatchQueue.main.async {
                let dict = result as? [String: Any]
                completion(dict?["success"] as? Bool ?? false, dict?["error"] as? String)
            }
        }
    }

    /// 任务详情（getCronJobInfo 通道），用于编辑时回填脚本与表达式。
    func loadInfo(id: Int, completion: @escaping ([String: Any]?) -> Void) {
        ChannelManager.shared.invokeDataMethod(
            "getCronJobInfo",
            arguments: ["id": id]
        ) { result in
            DispatchQueue.main.async {
                completion(result as? [String: Any])
            }
        }
    }
}

/// 计划任务执行记录（getCronJobRecords 通道）。
struct CronjobRecordRow: Identifiable {
    let id: Int
    let taskId: String
    let startTime: String
    let status: String
    let message: String
    let file: String
}

struct CronjobRecordsView: View {
    @EnvironmentObject var translations: TranslationsManager
    @Environment(\.dismiss) private var dismiss
    let job: CronjobModel

    @State private var records: [CronjobRecordRow] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && records.isEmpty {
                    LoadingView()
                } else if records.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle",
                        message: translations.get("cronjobRecordEmpty", fallback: "No run records yet.")
                    )
                } else {
                    List {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(record.startTime)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    StatusBadge(
                                        text: record.status,
                                        color: StatusPalette.cronjobStatus(record.status)
                                    )
                                }
                                if !record.taskId.isEmpty {
                                    Text("\(translations.get("cronjobRecordTaskIdLabel", fallback: "Task ID")): \(record.taskId)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if !record.message.isEmpty {
                                    Text(record.message)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
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
            .navigationTitle(job.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonClose", fallback: "Close")) { dismiss() }
                }
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
                fetch()
            }
        }
    }

    private func fetch() {
        isLoading = true
        ChannelManager.shared.invokeDataMethod(
            "getCronJobRecords",
            arguments: ["id": job.id, "page": 1, "pageSize": 50]
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                guard let dict = result as? [String: Any],
                      let items = dict["items"] as? [[String: Any]] else { return }
                records = items.compactMap { item in
                    guard let id = item["id"] as? Int else { return nil }
                    return CronjobRecordRow(
                        id: id,
                        taskId: item["taskId"] as? String ?? "",
                        startTime: item["startTime"] as? String ?? "",
                        status: item["status"] as? String ?? "",
                        message: item["message"] as? String ?? "",
                        file: item["file"] as? String ?? ""
                    )
                }
            }
        }
    }
}

/// 计划任务列表：调度规则与下次执行时间，支持启停、执行一次、执行记录与删除。
struct CronjobsView: View {
    @StateObject private var viewModel = CronjobsViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: CronjobModel?
    @State private var showDeleteConfirm = false
    @State private var showRecordsFor: CronjobModel?
    @State private var detailJob: CronjobModel?
    @State private var pendingEditJob: CronjobModel?
    @State private var toastText: String?
    @State private var showFormSheet = false
    @State private var editingJob: CronjobModel?
    @State private var formName = ""
    @State private var formSpec = ""
    @State private var formScript = ""
    @State private var isSaving = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cronjobs.isEmpty {
                LoadingView()
            } else if viewModel.cronjobs.isEmpty {
                EmptyStateView(
                    icon: "clock.arrow.circlepath",
                    message: translations.get("cronjobsEmptyTitle", fallback: "No cronjobs"),
                    description: translations.get("cronjobsEmptyHint",
                                                  fallback: "Cronjobs created in 1Panel appear here.")
                )
            } else {
                List {
                    ForEach(viewModel.cronjobs) { job in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(job.name)
                                    .font(.headline)
                                Spacer()
                                StatusBadge(
                                    text: statusLabel(job.status),
                                    color: job.status == "Enable" ? .green : .gray
                                )
                            }
                            HStack(spacing: 12) {
                                Label(job.spec, systemImage: "clock")
                                if !job.nextHandle.isEmpty {
                                    Label(job.nextHandle, systemImage: "calendar.badge.clock")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            detailJob = job
                        }
                        .contextMenu {
                            Button {
                                openEditor(job)
                            } label: {
                                Label(translations.get("commonEdit", fallback: "Edit"),
                                      systemImage: "pencil")
                            }
                            Button {
                                showRecordsFor = job
                            } label: {
                                Label(translations.get("cronjobsRecordsAction", fallback: "Records"),
                                      systemImage: "list.bullet.rectangle")
                            }
                            Button(role: .destructive) {
                                pendingDelete = job
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"),
                                      systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            jobLeadingActions(job)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = job
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
                            Button {
                                showRecordsFor = job
                            } label: {
                                Label(translations.get("cronjobsRecordsAction", fallback: "Records"),
                                      systemImage: "list.bullet.rectangle")
                            }
                            .tint(.indigo)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.fetch()
                }
            }
        }
        .navigationTitle(translations.get("operationsCronjobsTitle", fallback: "Cronjobs"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .cronjobs)
                Button {
                    editingJob = nil
                    formName = ""
                    formSpec = ""
                    formScript = ""
                    showFormSheet = true
                } label: {
                    Label(translations.get("hostCronJobsCreateTask", fallback: "Create Task"),
                          systemImage: "plus")
                }
                Button {
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showFormSheet) {
            formSheet
        }
        .sheet(item: $detailJob, onDismiss: {
            if let job = pendingEditJob {
                pendingEditJob = nil
                openEditor(job)
            }
        }) { job in
            CronjobDetailView(job: job, viewModel: viewModel) { editJob in
                pendingEditJob = editJob
                detailJob = nil
            }
            .environmentObject(translations)
        }
        .sheet(item: $showRecordsFor) { job in
            CronjobRecordsView(job: job)
                .environmentObject(translations)
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Confirm Deletion"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                guard let job = pendingDelete else { return }
                pendingDelete = nil
                viewModel.delete(id: job.id) { success in
                    showToast(success
                        ? translations.get("commonDeleted", fallback: "Deleted")
                        : translations.get("commonDeleteFailed", fallback: "Delete failed"))
                    viewModel.fetch()
                }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.fetch()
        }
    }

    @ViewBuilder
    private func jobLeadingActions(_ job: CronjobModel) -> some View {
        Button {
            toggle(job)
        } label: {
            Label(
                translations.get(job.status == "Enable"
                                 ? "cronjobsDisableAction"
                                 : "cronjobsEnableAction",
                                 fallback: job.status == "Enable" ? "Disable" : "Enable"),
                systemImage: job.status == "Enable" ? "pause.circle" : "play.circle"
            )
        }
        .tint(job.status == "Enable" ? .orange : .green)
        Button {
            runOnce(job)
        } label: {
            Label(translations.get("cronjobsHandleOnceAction", fallback: "Run once"),
                  systemImage: "bolt.fill")
        }
        .tint(.blue)
    }

    private func statusLabel(_ status: String) -> String {
        switch status {
        case "Enable":
            return translations.get("cronjobsStatusEnable", fallback: "Enabled")
        case "Disable":
            return translations.get("cronjobsStatusDisable", fallback: "Disabled")
        default:
            return status
        }
    }

    private func toggle(_ job: CronjobModel) {
        viewModel.toggleStatus(id: job.id, currentStatus: job.status) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetch()
        }
    }

    private func runOnce(_ job: CronjobModel) {
        viewModel.handleOnce(id: job.id) { success in
            showToast(success
                ? translations.get("commonSaveSuccess", fallback: "Saved")
                : translations.get("commonSaveFailed", fallback: "Save failed"))
            viewModel.fetch()
        }
    }

    private func openEditor(_ job: CronjobModel) {
        viewModel.loadInfo(id: job.id) { info in
            guard let info else {
                showToast(translations.get("commonLoadFailedTitle", fallback: "Failed to load"))
                return
            }
            editingJob = job
            formName = info["name"] as? String ?? job.name
            formSpec = info["spec"] as? String ?? job.spec
            formScript = info["script"] as? String ?? ""
            showFormSheet = true
        }
    }

    private var formSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(translations.get("cronjobsNameLabel", fallback: "Task Name"),
                              text: $formName)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField(translations.get("cronjobsSpecLabel", fallback: "Schedule"),
                              text: $formSpec)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("0 3 * * *")
                        .font(.footnote)
                }
                Section(translations.get("cronjobFormScriptLabel", fallback: "Script")) {
                    TextEditor(text: $formScript)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 160)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle(editingJob == nil
                ? translations.get("hostCronJobsCreateTask", fallback: "Create Task")
                : translations.get("commonEdit", fallback: "Edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(translations.get("commonCancel", fallback: "Cancel")) {
                        showFormSheet = false
                    }
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button(translations.get("commonSave", fallback: "Save")) {
                            saveForm()
                        }
                        .disabled(formName.trimmingCharacters(in: .whitespaces).isEmpty
                                  || formSpec.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    private func saveForm() {
        let name = formName.trimmingCharacters(in: .whitespaces)
        let spec = formSpec.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !spec.isEmpty else { return }
        isSaving = true
        let completion: (Bool, String?) -> Void = { success, error in
            isSaving = false
            if success {
                showFormSheet = false
                showToast(translations.get("commonSaveSuccess", fallback: "Saved"))
                viewModel.fetch()
            } else {
                let template = translations.get("appOperateFailed", fallback: "Operation failed: {error}")
                showToast(template.replacingOccurrences(of: "{error}", with: error ?? ""))
            }
        }
        if let job = editingJob {
            viewModel.update(id: job.id, name: name, spec: spec, script: formScript,
                             completion: completion)
        } else {
            viewModel.create(name: name, spec: spec, script: formScript,
                             completion: completion)
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
