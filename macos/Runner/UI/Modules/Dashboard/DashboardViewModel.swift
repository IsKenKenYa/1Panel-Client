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
        ChannelManager.shared.invokeDataMethod("getDashboard") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let dict = result as? [String: Any] {
                    self?.metrics.osInfo = dict["osInfo"] as? String ?? "Unknown OS"
                    self?.metrics.uptime = dict["uptime"] as? String ?? "0 days"
                    self?.metrics.cpuUsage = dict["cpuUsage"] as? Int ?? 0
                    self?.metrics.memoryUsage = dict["memoryUsage"] as? Int ?? 0
                    self?.metrics.diskUsage = dict["diskUsage"] as? Int ?? 0
                }
            }
        }
    }
}
