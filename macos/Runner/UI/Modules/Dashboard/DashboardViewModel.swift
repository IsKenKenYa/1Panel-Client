import Foundation

struct DashboardMetrics {
    var osInfo: String = ""
    var uptime: String = ""
    var cpuUsage: Double = 0
    var memoryUsage: Double = 0
    var diskUsage: Double = 0
    var memoryUsageText: String = "--"
    var diskUsageText: String = "--"
    var hostname: String = ""
    var kernelVersion: String = ""
    var cpuCores: Int = 0
    var panelVersion: String = ""
}

class DashboardViewModel: ObservableObject {
    @Published var metrics = DashboardMetrics()
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchDashboardData() {
        isLoading = true
        errorMessage = nil
        ChannelManager.shared.invokeDataMethod("getDashboard") { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let dict = result as? [String: Any] else {
                    self?.errorMessage = "Failed to parse dashboard data"
                    return
                }
                self?.metrics.cpuUsage    = dict["cpu"] as? Double ?? 0
                self?.metrics.memoryUsage = dict["memory"] as? Double ?? 0
                self?.metrics.diskUsage   = dict["disk"] as? Double ?? 0
                self?.metrics.memoryUsageText = dict["memoryUsage"] as? String ?? "--"
                self?.metrics.diskUsageText   = dict["diskUsage"] as? String ?? "--"
                self?.metrics.uptime          = dict["uptime"] as? String ?? "--"
                self?.metrics.osInfo          = dict["os"] as? String ?? ""
                self?.metrics.hostname        = dict["hostname"] as? String ?? ""
                self?.metrics.kernelVersion   = dict["kernelVersion"] as? String ?? ""
                self?.metrics.cpuCores        = dict["cpuCores"] as? Int ?? 0
                self?.metrics.panelVersion    = dict["panelVersion"] as? String ?? ""
            }
        }
    }
}
