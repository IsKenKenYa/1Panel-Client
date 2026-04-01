import SwiftUI

struct MonitoringView: View {
    @StateObject private var viewModel = MonitoringViewModel()
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(translations.get("serverModuleMonitoring", fallback: "Monitoring"))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            MetricCard(title: translations.get("monitoring_cpu", fallback: "CPU"), value: "\(viewModel.metrics.cpu)%", icon: "cpu")
                            MetricCard(title: translations.get("monitoring_memory", fallback: "Memory"), value: "\(viewModel.metrics.memory)%", icon: "memorychip")
                            MetricCard(title: translations.get("monitoring_disk", fallback: "Disk"), value: "\(viewModel.metrics.disk)%", icon: "internaldrive")
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("System Load")
                                .font(.headline)
                            
                            HStack(spacing: 32) {
                                LoadView(title: "1m", value: viewModel.metrics.load1)
                                LoadView(title: "5m", value: viewModel.metrics.load5)
                                LoadView(title: "15m", value: viewModel.metrics.load15)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // Use native visual effect for cards
                        .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            viewModel.fetchMonitoring()
        }
    }
}

struct MetricCard: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var translations: TranslationsManager
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
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
        .padding()
        .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        .cornerRadius(12)
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
