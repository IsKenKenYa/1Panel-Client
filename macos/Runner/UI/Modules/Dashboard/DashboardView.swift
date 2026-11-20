import SwiftUI
import AppleSharedUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // ── System Info ──────────────────────────────────────
                        GroupBox(label: Label(translations.get("dashboardServerInfoTitle", fallback: "System Information"), systemImage: "info.circle")) {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                InfoRow(label: translations.get("dashboardHostNameLabel", fallback: "Hostname"), value: viewModel.metrics.hostname)
                                InfoRow(label: translations.get("dashboardOsLabel", fallback: "OS"), value: viewModel.metrics.osInfo)
                                InfoRow(label: translations.get("dashboardKernelVersionLabel", fallback: "Kernel"), value: viewModel.metrics.kernelVersion)
                                InfoRow(label: translations.get("dashboardCpuCoresLabel", fallback: "CPU Cores"), value: viewModel.metrics.cpuCores > 0 ? "\(viewModel.metrics.cpuCores) cores" : "--")
                                InfoRow(label: translations.get("dashboardUptimeLabel", fallback: "Uptime"), value: viewModel.metrics.uptime)
                                InfoRow(label: translations.get("dashboardPanelVersionLabel", fallback: "1Panel"), value: viewModel.metrics.panelVersion.isEmpty ? "--" : "v\(viewModel.metrics.panelVersion)")
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity)

                        // ── Resource Usage ────────────────────────────────────
                        GroupBox(label: Label(translations.get("dashboardResourceTitle", fallback: "Resource Usage"), systemImage: "gauge")) {
                            VStack(spacing: 16) {
                                ResourceRow(
                                    title: translations.get("dashboardCpuUsage", fallback: "CPU"),
                                    value: viewModel.metrics.cpuUsage / 100,
                                    label: String(format: "%.1f%%", viewModel.metrics.cpuUsage),
                                    icon: "cpu",
                                    color: gaugeColor(viewModel.metrics.cpuUsage)
                                )
                                ResourceRow(
                                    title: translations.get("dashboardMemoryUsage", fallback: "Memory"),
                                    value: viewModel.metrics.memoryUsage / 100,
                                    label: viewModel.metrics.memoryUsageText,
                                    icon: "memorychip",
                                    color: gaugeColor(viewModel.metrics.memoryUsage)
                                )
                                ResourceRow(
                                    title: translations.get("dashboardDiskUsage", fallback: "Disk"),
                                    value: viewModel.metrics.diskUsage / 100,
                                    label: viewModel.metrics.diskUsageText,
                                    icon: "internaldrive",
                                    color: gaugeColor(viewModel.metrics.diskUsage)
                                )
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity)

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleDashboard", fallback: "Dashboard"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { viewModel.fetchDashboardData() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help(translations.get("commonRefresh", fallback: "Refresh"))
                .disabled(viewModel.isLoading)
            }
        }
        .alert(translations.get("commonError", fallback: "Error"), isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(translations.get("commonOk", fallback: "OK"), role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.fetchDashboardData()
        }
    }

    private func gaugeColor(_ percent: Double) -> Color {
        switch percent {
        case ..<60: return .green
        case ..<80: return .orange
        default: return .red
        }
    }
}

// ── Reusable sub-views ────────────────────────────────────────────────────────

struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value.isEmpty ? "--" : value)
                .font(.caption)
                .lineLimit(1)
            Spacer()
        }
    }
}

struct ResourceRow: View {
    let title: String
    let value: Double   // 0…1
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(color)
            Text(title)
                .frame(width: 60, alignment: .leading)
                .font(.subheadline)
            ProgressView(value: max(0, min(1, value)))
                .progressViewStyle(.linear)
                .tint(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
    }
}
