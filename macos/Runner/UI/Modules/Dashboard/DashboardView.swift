import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        GroupBox(label: Text("System Information").font(.headline)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("OS: \(viewModel.metrics.osInfo)")
                                        .font(.subheadline)
                                    Text("Uptime: \(viewModel.metrics.uptime)")
                                        .font(.subheadline)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        HStack(spacing: 16) {
                            MetricCard(title: "CPU Usage", value: "\(viewModel.metrics.cpuUsage)%", icon: "cpu")
                            MetricCard(title: "Memory Usage", value: "\(viewModel.metrics.memoryUsage)%", icon: "memorychip")
                            MetricCard(title: "Disk Usage", value: "\(viewModel.metrics.diskUsage)%", icon: "internaldrive")
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(translations.get("navDashboard", fallback: "Dashboard"))
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    viewModel.fetchDashboardData()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
            }
        }
        .onAppear {
            viewModel.fetchDashboardData()
        }
    }
}