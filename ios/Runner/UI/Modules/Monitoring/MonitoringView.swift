import SwiftUI

struct MonitoringView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.metrics.cpu == 0 {
                LoadingView()
            } else {
                List {
                    Section(translations.get("monitorSystemUsageTitle", fallback: "System Usage")) {
                        ResourceGaugeRow(
                            title: translations.get("dashboardCpuUsage", fallback: "CPU"),
                            value: viewModel.metrics.cpu,
                            icon: "cpu"
                        )
                        ResourceGaugeRow(
                            title: translations.get("dashboardMemoryUsage", fallback: "Memory"),
                            value: viewModel.metrics.memory,
                            icon: "memorychip"
                        )
                        ResourceGaugeRow(
                            title: translations.get("dashboardDiskUsage", fallback: "Disk"),
                            value: viewModel.metrics.disk,
                            icon: "internaldrive"
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
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    viewModel.startAutoRefresh()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleMonitoring", fallback: "Monitoring"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ModuleSwitcherMenu(current: .monitoring)
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
        }
    }
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
