import SwiftUI

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
}

/// 计划任务列表：调度规则与下次执行时间，支持启停与删除。
struct CronjobsView: View {
    @StateObject private var viewModel = CronjobsViewModel()
    @EnvironmentObject var translations: TranslationsManager

    @State private var pendingDelete: CronjobModel?
    @State private var showDeleteConfirm = false
    @State private var toastText: String?

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
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
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
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                pendingDelete = job
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("commonDelete", fallback: "Delete"), systemImage: "trash")
                            }
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
                    viewModel.fetch()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
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

    private func showToast(_ text: String) {
        toastText = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if toastText == text {
                toastText = nil
            }
        }
    }
}
