import SwiftUI
import AppleSharedUI

struct CronJobsView: View {
    @StateObject private var viewModel = CronJobsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var jobToDelete: CronJobModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.cronJobs.isEmpty {
                EmptyStateView(
                    icon: "timer",
                    message: translations.get("cronjobsEmptyTitle", fallback: "No cron jobs found")
                )
            } else {
                List {
                    ForEach(viewModel.cronJobs) { job in
                        row(job)
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(translations.get("operationsCronjobsTitle", fallback: "Cron Jobs"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                if viewModel.isProcessing {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button { viewModel.fetchCronJobs() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help(translations.get("commonRefresh", fallback: "Refresh"))
                }
            }
        }
        .confirmationDialog(
            translations.get("deleteConfirmTitle", fallback: "Delete \"\(jobToDelete?.name ?? "")\"?"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(translations.get("commonDelete", fallback: "Delete"), role: .destructive) {
                if let j = jobToDelete { Task { await viewModel.deleteCronJob(id: j.originalId) } }
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {}
        } message: {
            Text(translations.get("deleteCannotUndoMessage", fallback: "This action cannot be undone."))
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchCronJobs() }
    }

    private func row(_ job: CronJobModel) -> some View {
        let isActive = ["active", "running"].contains(job.status.lowercased())
        let subtitle = job.lastRecordStatus.isEmpty
            ? job.schedule
            : "\(job.schedule) · \(job.lastRecordStatus)"
        return ModuleRow(
            icon: "timer",
            iconColor: .orange,
            title: job.name,
            subtitle: subtitle,
            badge: job.status.isEmpty ? nil : (job.status, isActive ? .green : .gray)
        ) {
            RowActions {
                RowActionButton(
                    title: isActive
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: isActive ? "stop.fill" : "play.fill"
                ) {
                    Task {
                        await viewModel.toggleCronJobStatus(
                            id: job.originalId,
                            currentStatus: job.status
                        )
                    }
                }
                RowActionButton(
                    title: translations.get("commonDelete", fallback: "Delete"),
                    systemImage: "trash",
                    destructive: true
                ) {
                    jobToDelete = job
                    showDeleteConfirm = true
                }
            }
            .disabled(viewModel.isProcessing)
        }
        .contextMenu {
            Button {
                Task {
                    await viewModel.toggleCronJobStatus(
                        id: job.originalId,
                        currentStatus: job.status
                    )
                }
            } label: {
                Label(
                    isActive
                        ? translations.get("commonStop", fallback: "Stop")
                        : translations.get("commonStart", fallback: "Start"),
                    systemImage: isActive ? "stop.fill" : "play.fill"
                )
            }
            Divider()
            Button(role: .destructive) {
                jobToDelete = job
                showDeleteConfirm = true
            } label: {
                Label(translations.get("commonDelete", fallback: "Delete"),
                      systemImage: "trash")
            }
        }
    }
}
