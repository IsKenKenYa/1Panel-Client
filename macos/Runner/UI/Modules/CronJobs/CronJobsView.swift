import SwiftUI

struct CronJobsView: View {
    @StateObject private var viewModel = CronJobsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var jobToDelete: CronJobModel?
    @State private var showDeleteConfirm = false

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.cronJobs.isEmpty {
                Text("No cron jobs found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Table(viewModel.cronJobs) {
                    TableColumn(translations.get("cronjob_name", fallback: "Name")) { job in
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.orange)
                            Text(job.name)
                        }
                        .contextMenu {
                            let isActive = job.status.lowercased() == "active" || job.status.lowercased() == "running"
                            Button {
                                Task { await viewModel.toggleCronJobStatus(id: job.originalId, currentStatus: job.status) }
                            } label: {
                                Label(
                                    isActive ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"),
                                    systemImage: isActive ? "stop.fill" : "play.fill"
                                )
                            }
                            Divider()
                            Button(role: .destructive) {
                                jobToDelete = job
                                showDeleteConfirm = true
                            } label: {
                                Label(translations.get("delete", fallback: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("cronjob_schedule", fallback: "Schedule")) { job in
                        Text(job.schedule)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                    TableColumn("Last Result") { job in
                        if !job.lastRecordStatus.isEmpty {
                            let ok = job.lastRecordStatus.lowercased() == "success"
                            Text(job.lastRecordStatus)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(ok ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                                .foregroundColor(ok ? .green : .red)
                                .cornerRadius(4)
                        }
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { job in
                        let isActive = job.status.lowercased() == "active" || job.status.lowercased() == "running"
                        Text(job.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(isActive ? Color.green.opacity(0.12) : Color.gray.opacity(0.12))
                            .foregroundColor(isActive ? .green : .gray)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .disableAlternatingRowBackgrounds()
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
                    .help("Refresh")
                }
            }
        }
        .confirmationDialog(
            "Delete \"\(jobToDelete?.name ?? "")\"?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let j = jobToDelete { Task { await viewModel.deleteCronJob(id: j.originalId) } }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear { viewModel.fetchCronJobs() }
    }
}
