import SwiftUI

/// 服务器首页：当前服务器的系统信息、资源占用与功能模块入口。
/// 业务模块入口语义与 MDUI3 服务器首页一致。
struct ServerHomeView: View {
    @StateObject private var viewModel = ServerHomeViewModel()
    @EnvironmentObject var translations: TranslationsManager
    let server: ServerModel

    var body: some View {
        List {
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

            Section(translations.get("serverModulesTitle", fallback: "Modules")) {
                NavigationLink(value: ModuleRoute.containers) {
                    ModuleEntryRow(title: translations.get("serverModuleContainers", fallback: "Containers"),
                                   icon: "square.stack.3d.up", color: .blue)
                }
                NavigationLink(value: ModuleRoute.websites) {
                    ModuleEntryRow(title: translations.get("serverModuleWebsites", fallback: "Websites"),
                                   icon: "globe", color: .teal)
                }
                NavigationLink(value: ModuleRoute.apps) {
                    ModuleEntryRow(title: translations.get("serverModuleApps", fallback: "Apps"),
                                   icon: "app.badge", color: .indigo)
                }
                NavigationLink(value: ModuleRoute.monitoring) {
                    ModuleEntryRow(title: translations.get("serverModuleMonitoring", fallback: "Monitoring"),
                                   icon: "chart.xyaxis.line", color: .orange)
                }
                NavigationLink(value: ModuleRoute.databases) {
                    ModuleEntryRow(title: translations.get("serverModuleDatabases", fallback: "Databases"),
                                   icon: "cylinder.split.1x2", color: .purple)
                }
                NavigationLink(value: ModuleRoute.cronjobs) {
                    ModuleEntryRow(title: translations.get("operationsCronjobsTitle", fallback: "Cronjobs"),
                                   icon: "clock.arrow.circlepath", color: .brown)
                }
                NavigationLink(value: ModuleRoute.firewall) {
                    ModuleEntryRow(title: translations.get("serverModuleFirewall", fallback: "Firewall"),
                                   icon: "shield.lefthalf.filled", color: .red)
                }
                NavigationLink(value: ModuleRoute.backups) {
                    ModuleEntryRow(title: translations.get("operationsBackupsTitle", fallback: "Backups"),
                                   icon: "externaldrive", color: .indigo)
                }
                NavigationLink(value: ModuleRoute.ai) {
                    ModuleEntryRow(title: translations.get("serverModuleAi", fallback: "AI"),
                                   icon: "brain", color: .pink)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.fetchDashboard()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.fetchDashboard()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            if !server.isCurrent {
                viewModel.connectServer(id: server.originalId)
            }
            viewModel.fetchDashboard()
        }
    }
}

private struct ModuleEntryRow: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        Label(title, systemImage: icon)
            .foregroundStyle(color)
            .font(.body)
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
