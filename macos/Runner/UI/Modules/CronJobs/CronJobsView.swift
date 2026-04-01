import SwiftUI

struct CronJobsView: View {
    @StateObject private var viewModel = CronJobsViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
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
                                .foregroundColor(.blue)
                            Text(job.name)
                        }
                        .contextMenu {
                            let isRunning = job.status.lowercased() == "active" || job.status.lowercased() == "running"
                            Button(action: {
                                Task {
                                    await viewModel.toggleCronJobStatus(id: job.originalId, currentStatus: job.status)
                                }
                            }) {
                                Text(isRunning ? translations.get("stop", fallback: "Stop") : translations.get("start", fallback: "Start"))
                                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                            }
                            Divider()
                            Button(action: {
                                Task {
                                    await viewModel.deleteCronJob(id: job.originalId)
                                }
                            }) {
                                Text(translations.get("delete", fallback: "Delete"))
                                Image(systemName: "trash")
                            }
                        }
                    }
                    TableColumn(translations.get("cronjob_schedule", fallback: "Schedule")) { job in
                        Text(job.schedule)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                    TableColumn(translations.get("app_status", fallback: "Status")) { job in
                        let isRunning = job.status.lowercased() == "active" || job.status.lowercased() == "running"
                        Text(job.status)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isRunning ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundColor(isRunning ? .green : .gray)
                            .cornerRadius(4)
                    }
                }
                .tableStyle(.inset)
                .alternatingRowBackgrounds(.disabled)
            }
        }
        .navigationTitle(translations.get("operationsCronjobsTitle", fallback: "Cron Jobs"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchCronJobs()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchCronJobs()
        }
    }
}