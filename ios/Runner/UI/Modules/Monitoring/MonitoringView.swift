import SwiftUI
import AppleSharedUI

struct MonitoringView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @StateObject private var historyModel = MonitorHistoryViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    @State private var processes: [ListeningProcessRow] = []
    @State private var pendingStop: ListeningProcessRow?
    @State private var toastText: String?
    @State private var historyHours = 1
    @State private var showSettings = false

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.metrics.cpu == 0 {
                LoadingView()
            } else {
                List {
                    MonitorHistorySection(
                        history: historyModel.history,
                        isLoading: historyModel.isLoading
                    )
                    if let error = historyModel.errorMessage {
                        Section {
                            Text(error).font(.caption).foregroundStyle(.red)
                        }
                    }
                    Section(translations.get("monitorSystemUsageTitle", fallback: "System Usage")) {
                        ResourceGaugeRow(
                            title: translations.get("dashboardCpuUsage", fallback: "CPU"),
                            value: viewModel.metrics.cpu,
                            icon: "cpu",
                            baseColor: .blue
                        )
                        ResourceGaugeRow(
                            title: translations.get("dashboardMemoryUsage", fallback: "Memory"),
                            value: viewModel.metrics.memory,
                            icon: "memorychip",
                            baseColor: .purple
                        )
                        ResourceGaugeRow(
                            title: translations.get("dashboardDiskUsage", fallback: "Disk"),
                            value: viewModel.metrics.disk,
                            icon: "internaldrive",
                            baseColor: .teal
                        )
                    }
                    Section(translations.get("monitorLoadAverageTitle", fallback: "Load Average")) {
                        MetricRow(
                            title: "1 Min",
                            value: String(format: "%.2f", viewModel.metrics.load1),
                            icon: "chart.xyaxis.line",
                            color: .green
                        )
                        MetricRow(
                            title: "5 Min",
                            value: String(format: "%.2f", viewModel.metrics.load5),
                            icon: "chart.xyaxis.line",
                            color: .green
                        )
                        MetricRow(
                            title: "15 Min",
                            value: String(format: "%.2f", viewModel.metrics.load15),
                            icon: "chart.xyaxis.line",
                            color: .green
                        )
                    }
                    Section(translations.get("operationsProcessesTitle", fallback: "Processes")) {
                        if processes.isEmpty {
                            Text(translations.get("processesEmptyTitle", fallback: "No processes"))
                                .foregroundColor(.secondary)
                        }
                        ForEach(processes) { process in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(process.name.isEmpty ? "\(process.pid)" : process.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(translations.get("processesSearchPidLabel", fallback: "PID") + " \(process.pid)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if !process.ports.isEmpty {
                                    Label(
                                        translations.get("processesListeningPortsLabel",
                                                        fallback: "Listening ports")
                                            + " " + process.ports.map(String.init).joined(separator: ", "),
                                        systemImage: "network"
                                    )
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    pendingStop = process
                                } label: {
                                    Label(translations.get("commonStop", fallback: "Stop"),
                                          systemImage: "stop.fill")
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.startAutoRefresh()
                    fetchProcesses()
                    await historyModel.fetch(hours: historyHours)
                }
            }
        }
        .navigationTitle(translations.get("serverModuleMonitoring", fallback: "Monitoring"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach([1, 6, 24, 168], id: \.self) { hours in
                        Button(historyLabel(hours)) {
                            historyHours = hours
                            Task { await historyModel.fetch(hours: hours) }
                        }
                    }
                } label: {
                    Label(historyLabel(historyHours), systemImage: "clock.arrow.circlepath")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Label(translations.get("monitorSettingTitle", fallback: "Monitoring Settings"),
                          systemImage: "gearshape")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .monitoring)
            }
        }
        .sheet(isPresented: $showSettings) {
            MonitoringSettingsSheet()
        }
        .confirmationDialog(
            stopConfirmMessage,
            isPresented: Binding(
                get: { pendingStop != nil },
                set: { if !$0 { pendingStop = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(translations.get("commonStop", fallback: "Stop"), role: .destructive) {
                stopProcess()
            }
            Button(translations.get("commonCancel", fallback: "Cancel"), role: .cancel) {
                pendingStop = nil
            }
        }
        .operationNotice(toastText)
        .onAppear {
            viewModel.startAutoRefresh()
            fetchProcesses()
            Task { await historyModel.fetch(hours: historyHours) }
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }

    private var stopConfirmMessage: String {
        let template = translations.get("processesStopConfirm",
                                        fallback: "Stop process {name}?")
        let name = pendingStop?.name ?? ""
        let pid = "\(pendingStop?.pid ?? 0)"
        return template
            .replacingOccurrences(of: "{name}", with: name.isEmpty ? pid : name)
            .replacingOccurrences(of: "{0}", with: name.isEmpty ? pid : name)
    }

    private func historyLabel(_ hours: Int) -> String {
        switch hours {
        case 1: return translations.get("monitorHistoryHour1", fallback: "1 hour")
        case 6: return translations.get("monitorHistoryHour6", fallback: "6 hours")
        case 24: return translations.get("monitorHistoryHour24", fallback: "24 hours")
        case 168: return translations.get("monitorHistoryHour168", fallback: "7 days")
        default: return "\(hours)h"
        }
    }

    private func fetchProcesses() {
        ChannelManager.shared.invokeDataMethod("getListeningProcesses") { result in
            DispatchQueue.main.async {
                guard let items = result as? [[String: Any]] else { return }
                processes = items.enumerated().compactMap { offset, item in
                    guard let pid = item["pid"] as? Int else { return nil }
                    return ListeningProcessRow(
                        uid: "\(pid)-\(offset)",
                        pid: pid,
                        name: item["name"] as? String ?? "",
                        ports: (item["ports"] as? [Any])?.compactMap { ($0 as? NSNumber)?.intValue } ?? []
                    )
                }
            }
        }
    }

    private func stopProcess() {
        guard let process = pendingStop else { return }
        pendingStop = nil
        ChannelManager.shared.invokeDataMethod(
            "stopListeningProcess",
            arguments: ["pid": process.pid]
        ) { result in
            DispatchQueue.main.async {
                let success = (result as? [String: Any])?["success"] as? Bool ?? false
                let text = success
                    ? translations.get("commonOperationSuccess", fallback: "Operation succeeded")
                    : translations.get("commonOperationFailed", fallback: "Operation failed")
                toastText = text
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if toastText == text {
                        toastText = nil
                    }
                }
                fetchProcesses()
            }
        }
    }
}

struct ListeningProcessRow: Identifiable {
    let uid: String
    let pid: Int
    let name: String
    let ports: [Int]

    var id: String { uid }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.vertical, 2)
    }
}
