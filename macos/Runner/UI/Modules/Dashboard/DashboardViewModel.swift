import Foundation

struct DashboardMetrics {
    var osInfo: String = ""
    var uptime: String = ""
    var cpuUsage: Int = 0
    var memoryUsage: Int = 0
    var diskUsage: Int = 0
}

class DashboardViewModel: ObservableObject {
    @Published var metrics = DashboardMetrics()
    @Published var isLoading = false
    
    func fetchDashboardData() {
        isLoading = true
        // Note: The Dart NativeChannelManager currently does not implement "getDashboard".
        // To avoid throwing an unsupported method-channel error, we mock the data here.
        print("getDashboard is currently not supported: missing Dart handler.")
        DispatchQueue.main.async { [weak self] in
            self?.isLoading = false
            self?.metrics.osInfo = "macOS (Mocked)"
            self?.metrics.uptime = "1 days"
            self?.metrics.cpuUsage = 15
            self?.metrics.memoryUsage = 42
            self?.metrics.diskUsage = 60
        }
    }
}
