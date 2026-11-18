import SwiftUI

/// 服务器首页：当前服务器的系统信息、资源占用与功能模块入口。
/// 业务模块入口语义与 MDUI3 服务器首页一致。
struct ServerHomeView: View {
    @StateObject private var viewModel = ServerHomeViewModel()
    @EnvironmentObject var translations: TranslationsManager
    let server: ServerModel

    var body: some View {
        dashboard
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.fetchDashboard()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.fetchDashboard()
        }
    }

    private var dashboard: some View {
        List {
            Section(translations.get("serverModulesTitle", fallback: "Modules")) {
                ForEach(ModuleRoute.allCases) { module in
                    NavigationLink(value: ServerRoute.module(module)) {
                        Label(module.title(translations), systemImage: module.icon)
                    }
                }
            }

            Section(translations.get("dashboardResourceTitle", fallback: "System Resources")) {
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

            Section(translations.get("dashboardServerInfoTitle", fallback: "Server Info")) {
                InfoLine(label: translations.get("dashboardHostNameLabel", fallback: "Hostname"),
                         value: viewModel.metrics.hostname)
                InfoLine(label: translations.get("dashboardOsLabel", fallback: "OS"),
                         value: viewModel.metrics.osInfo)
                InfoLine(label: translations.get("dashboardCpuCoresLabel", fallback: "CPU Cores"),
                         value: viewModel.metrics.cpuCores > 0 ? "\(viewModel.metrics.cpuCores)" : "--")
                InfoLine(label: translations.get("dashboardUptimeLabel", fallback: "Uptime"),
                         value: viewModel.metrics.uptime.isEmpty ? "--" : viewModel.metrics.uptime)
                InfoLine(label: translations.get("dashboardPanelVersionLabel", fallback: "Panel Version"),
                         value: viewModel.metrics.panelVersion.isEmpty ? "--" : "v\(viewModel.metrics.panelVersion)")
            }

        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.fetchDashboard()
        }
    }
}

/// 资源占用行：数值 + 阈值色进度条（60% 橙色、85% 红色）。
struct ResourceGaugeRow: View {
    let title: String
    let value: Double
    let icon: String

    private var gaugeColor: Color {
        switch value {
        case 85...: return .red
        case 60..<85: return .orange
        default: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f%%", value))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(gaugeColor)
        }
        .padding(.vertical, 2)
    }
}
