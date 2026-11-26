import SwiftUI
import AppleSharedUI

/// 服务器首页：当前服务器的系统信息、资源占用与功能模块入口。
/// 业务模块入口语义与 MDUI3 服务器首页一致。
struct ServerHomeView: View {
    @StateObject private var viewModel = ServerHomeViewModel()
    @EnvironmentObject var translations: TranslationsManager
    let server: ServerModel

    @State private var snapshot: DeviceSnapshotData?

    var body: some View {
        dashboard
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.fetchDashboard()
                    fetchSnapshot()
                } label: {
                    Label(translations.get("commonRefresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
        }
        .onAppear {
            viewModel.fetchDashboard()
            fetchSnapshot()
        }
    }

    private func fetchSnapshot() {
        ChannelManager.shared.invokeDataMethod("getDeviceSnapshot") { result in
            DispatchQueue.main.async {
                guard let dict = result as? [String: Any], !dict.isEmpty else { return }
                snapshot = DeviceSnapshotData(
                    hostname: dict["hostname"] as? String ?? "",
                    product: [dict["productName"] as? String ?? "",
                              dict["productVersion"] as? String ?? ""]
                        .filter { !$0.isEmpty }
                        .joined(separator: " "),
                    system: [dict["systemName"] as? String ?? "",
                             dict["systemVersion"] as? String ?? ""]
                        .filter { !$0.isEmpty }
                        .joined(separator: " "),
                    timeZone: dict["timeZone"] as? String ?? "",
                    localTime: dict["localTime"] as? String ?? "",
                    ntp: dict["ntp"] as? String ?? "",
                    dns: dict["dns"] as? String ?? "",
                    userCount: (dict["users"] as? [Any])?.count ?? 0
                )
            }
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

            if let snapshot {
                Section(translations.get("serverDeviceSnapshotTitle", fallback: "Device Info")) {
                    if !snapshot.product.isEmpty {
                        InfoLine(label: translations.get("hostToolboxProductLabel", fallback: "Product"),
                                 value: snapshot.product)
                    }
                    if !snapshot.system.isEmpty {
                        InfoLine(label: translations.get("dashboardOsLabel", fallback: "OS"),
                                 value: snapshot.system)
                    }
                    if !snapshot.timeZone.isEmpty {
                        InfoLine(label: translations.get("hostToolboxTimeZoneLabel", fallback: "Time Zone"),
                                 value: snapshot.timeZone)
                    }
                    if !snapshot.localTime.isEmpty {
                        InfoLine(label: translations.get("serverLocalTimeLabel", fallback: "Local Time"),
                                 value: snapshot.localTime)
                    }
                    if !snapshot.ntp.isEmpty {
                        InfoLine(label: translations.get("hostToolboxNtpServerLabel", fallback: "NTP Server"),
                                 value: snapshot.ntp)
                    }
                    if !snapshot.dns.isEmpty {
                        InfoLine(label: translations.get("serverDnsLabel", fallback: "DNS"),
                                 value: snapshot.dns)
                    }
                    if snapshot.userCount > 0 {
                        InfoLine(label: translations.get("hostToolboxUsersTitle", fallback: "Users"),
                                 value: "\(snapshot.userCount)")
                    }
                }
            }

        }
        .listStyle(.insetGrouped)
        .refreshable {
            viewModel.fetchDashboard()
            fetchSnapshot()
        }
    }
}

/// 设备快照展示数据。
struct DeviceSnapshotData {
    let hostname: String
    let product: String
    let system: String
    let timeZone: String
    let localTime: String
    let ntp: String
    let dns: String
    let userCount: Int
}

/// 资源占用行：数值 + 阈值色进度条。
struct ResourceGaugeRow: View {
    let title: String
    let value: Double
    let icon: String
    /// 未进入提示与危险区间时的颜色。
    var baseColor: Color = .blue

    private var gaugeColor: Color {
        GaugePalette.color(for: value, base: baseColor)
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
