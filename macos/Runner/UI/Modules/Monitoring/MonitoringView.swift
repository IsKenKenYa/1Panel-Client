import SwiftUI

struct MonitoringView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.metrics.cpu == 0 {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // ── Resource gauges ────────────────────────────────────
                        GroupBox(label: Label("Resource Usage", systemImage: "gauge")) {
                            VStack(spacing: 16) {
                                ResourceRow(
                                    title: "CPU",
                                    value: Double(viewModel.metrics.cpu) / 100,
                                    label: "\(viewModel.metrics.cpu)%",
                                    icon: "cpu",
                                    color: gaugeColor(Double(viewModel.metrics.cpu))
                                )
                                ResourceRow(
                                    title: translations.get("monitoring_memory", fallback: "Memory"),
                                    value: Double(viewModel.metrics.memory) / 100,
                                    label: "\(viewModel.metrics.memory)%",
                                    icon: "memorychip",
                                    color: gaugeColor(Double(viewModel.metrics.memory))
                                )
                                ResourceRow(
                                    title: translations.get("monitoring_disk", fallback: "Disk"),
                                    value: Double(viewModel.metrics.disk) / 100,
                                    label: "\(viewModel.metrics.disk)%",
                                    icon: "internaldrive",
                                    color: gaugeColor(Double(viewModel.metrics.disk))
                                )
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity)

                        // ── System Load ────────────────────────────────────────
                        GroupBox(label: Label("System Load", systemImage: "waveform.path.ecg")) {
                            HStack(spacing: 48) {
                                LoadView(title: "1 min", value: viewModel.metrics.load1)
                                LoadView(title: "5 min", value: viewModel.metrics.load5)
                                LoadView(title: "15 min", value: viewModel.metrics.load15)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(translations.get("serverModuleMonitoring", fallback: "Monitoring"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 4) {
                    if viewModel.isLoading {
                        ProgressView().scaleEffect(0.6)
                    }
                    Button { viewModel.fetchMonitoring() } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh")
                }
            }
        }
        .onAppear {
            viewModel.startAutoRefresh()
        }
        .onDisappear {
            viewModel.stopAutoRefresh()
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

// MetricCard is kept for backward compatibility (used by other views if any)
struct MetricCard: View {
    @EnvironmentObject var theme: ThemeManager
    let title: String
    let value: String
    let icon: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(theme.primaryColor)
                    Text(title)
                        .foregroundColor(.secondary)
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

struct LoadView: View {
    let title: String
    let value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.2f", value))
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}
